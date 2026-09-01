# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class ExploreCommunities
      CACHE_KEY = "discourse-community-platform:explore-community-signals:v1"
      CACHE_TTL = 30.minutes
      RECENT_WINDOW = 14.days
      DEFAULT_LIMIT = 8
      MAX_LIMIT = 12
      CANDIDATE_LIMIT = 100

      ACTIVITY_SCORE_SQL = <<~SQL.squish
        COUNT(topics.id) * 2.0 +
        COALESCE(SUM(dcp_explore_scores.score), 0) * 3.0 +
        COALESCE(SUM(GREATEST(topics.posts_count - 1, 0)), 0) * 0.75 +
        COALESCE(SUM(topics.views), 0) * 0.01 +
        EXTRACT(EPOCH FROM MAX(COALESCE(topics.last_posted_at, topics.created_at))) / 604800.0
      SQL

      def self.call(guardian:, limit: DEFAULT_LIMIT)
        new(guardian:, limit:).call
      end

      def self.cached_signals
        Discourse.cache.read(CACHE_KEY) || []
      end

      def self.rebuild_cache
        signals =
          ranked_scope
            .limit(CANDIDATE_LIMIT)
            .pluck(
              Arel.sql("dcp_explore_communities.id"),
              Arel.sql("COUNT(topics.id)"),
              Arel.sql(ACTIVITY_SCORE_SQL),
            )
            .map do |community_id, recent_topics_count, activity_score|
              [community_id.to_i, recent_topics_count.to_i, activity_score.to_f]
            end

        Discourse.cache.write(CACHE_KEY, signals, expires_in: CACHE_TTL)
        signals
      end

      def self.ranked_scope
        Topic
          .where(deleted_at: nil, visible: true, archetype: Archetype.default)
          .where("COALESCE(topics.last_posted_at, topics.created_at) >= ?", RECENT_WINDOW.ago)
          .where.not(id: Category.topic_ids)
          .joins(
            <<~SQL.squish,
              INNER JOIN discourse_community_platform_communities dcp_explore_communities
                ON dcp_explore_communities.category_id = topics.category_id
                AND dcp_explore_communities.visibility = 'public'
            SQL
          )
          .joins(
            <<~SQL.squish,
              LEFT JOIN discourse_community_platform_topic_scores dcp_explore_scores
                ON dcp_explore_scores.topic_id = topics.id
                AND dcp_explore_scores.community_id = dcp_explore_communities.id
            SQL
          )
          .group("dcp_explore_communities.id")
          .order(Arel.sql("#{ACTIVITY_SCORE_SQL} DESC, dcp_explore_communities.id DESC"))
      end

      def initialize(guardian:, limit:)
        @guardian = guardian
        @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
      end

      def call
        signals = self.class.cached_signals
        return [] if signals.empty?

        community_ids = signals.map(&:first)
        communities =
          Community
            .where(id: community_ids, visibility: "public")
            .includes(:category, :icon_upload)
            .index_by(&:id)
        joined_category_ids = joined_category_ids_for(@guardian.user)

        signals.filter_map do |community_id, recent_topics_count, _activity_score|
          community = communities[community_id]
          next if community.blank?
          next if joined_category_ids[community.category_id]
          next unless @guardian.can_see_category?(community.category)

          icon_upload = community.icon_upload
          icon_url = icon_upload&.url if icon_upload.blank? || @guardian.can_see_upload?(icon_upload)

          {
            id: community.id,
            name: community.name,
            slug: community.slug,
            path: "/s/#{community.slug}",
            description: community.description,
            members_count: community.members_count,
            icon_emoji: community.icon_emoji,
            icon_url:,
            banner_color: community.banner_color,
            recent_topics_count:,
          }
        end.first(@limit)
      end

      private

      def joined_category_ids_for(user)
        return {} if user.blank?

        group_ids = GroupUser.where(user_id: user.id).pluck(:group_id)
        return {} if group_ids.empty?

        Community
          .where(member_group_id: group_ids)
          .pluck(:category_id)
          .to_h { |category_id| [category_id, true] }
      end
    end
  end
end
