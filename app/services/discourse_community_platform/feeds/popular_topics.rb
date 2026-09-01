# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class PopularTopics
      CACHE_KEY = "discourse-community-platform:popular-topic-ids:v1"
      CACHE_TTL = 15.minutes
      RECENT_WINDOW = 14.days
      DEFAULT_LIMIT = 30
      MAX_LIMIT = 50
      CANDIDATE_LIMIT = 300

      def self.call(guardian:, limit: DEFAULT_LIMIT)
        new(guardian:, limit:).call
      end

      def self.cached_topic_ids
        Discourse.cache.read(CACHE_KEY).presence || rebuild_cache
      end

      def self.rebuild_cache
        topic_ids = ranked_scope.limit(CANDIDATE_LIMIT).pluck("topics.id")
        Discourse.cache.write(CACHE_KEY, topic_ids, expires_in: CACHE_TTL)
        topic_ids
      end

      def self.ranked_scope
        Topic
          .where(deleted_at: nil, visible: true, archetype: Archetype.default)
          .where("COALESCE(topics.last_posted_at, topics.created_at) >= ?", RECENT_WINDOW.ago)
          .where.not(id: Category.topic_ids)
          .joins(
            <<~SQL.squish,
              INNER JOIN discourse_community_platform_communities dcp_communities
                ON dcp_communities.category_id = topics.category_id
                AND dcp_communities.visibility = 'public'
            SQL
          )
          .joins(
            <<~SQL.squish,
              LEFT JOIN discourse_community_platform_topic_scores dcp_scores
                ON dcp_scores.topic_id = topics.id
                AND dcp_scores.community_id = dcp_communities.id
            SQL
          )
          .order(
            Arel.sql(
              "(COALESCE(dcp_scores.score, 0) * 4.0 + " \
                "COALESCE(dcp_scores.upvotes, 0) * 0.35 + " \
                "COALESCE(dcp_scores.downvotes, 0) * 0.10 + " \
                "LN(GREATEST(topics.posts_count, 1)) * 1.5 + " \
                "LN(GREATEST(topics.views, 0) + 1) * 0.35 + " \
                "EXTRACT(EPOCH FROM COALESCE(topics.last_posted_at, topics.created_at)) / 345600.0) DESC, " \
                "topics.id DESC",
            ),
          )
      end

      def initialize(guardian:, limit:)
        @guardian = guardian
        @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
      end

      def call
        topic_ids = self.class.cached_topic_ids
        topics_by_id = Topic.where(id: topic_ids).includes(:category).index_by(&:id)

        topics =
          topic_ids.filter_map do |topic_id|
            topic = topics_by_id[topic_id]
            topic if topic && @guardian.can_see_topic?(topic)
          end.first(@limit)

        scores = TopicScore.where(topic_id: topics.map(&:id)).index_by(&:topic_id)
        communities =
          Community
            .where(category_id: topics.map(&:category_id))
            .includes(:icon_upload)
            .index_by(&:category_id)
        votes = user_votes(topics)
        previews = TopicPreviews.call(topics:, guardian: @guardian)

        topics.filter_map do |topic|
          community = communities[topic.category_id]
          next if community.blank? || !community.public?

          score = scores[topic.id]
          preview = previews.fetch(topic.id, {})

          {
            id: topic.id,
            title: topic.title,
            slug: topic.slug,
            path: topic.relative_url,
            posts_count: topic.posts_count,
            views: topic.views,
            like_count: topic.like_count,
            created_at: topic.created_at,
            last_posted_at: topic.last_posted_at,
            score: score&.score || 0,
            upvotes: score&.upvotes || 0,
            downvotes: score&.downvotes || 0,
            user_vote: votes.fetch(topic.id, 0),
            excerpt: preview[:excerpt],
            image_url: preview[:image_url],
            community: community_identity(community),
          }
        end
      end

      private

      def community_identity(community)
        icon_upload = community.icon_upload
        icon_url = icon_upload&.url if icon_upload.blank? || @guardian.can_see_upload?(icon_upload)

        {
          id: community.id,
          name: community.name,
          slug: community.slug,
          path: "/s/#{community.slug}",
          icon_emoji: community.icon_emoji,
          icon_url:,
        }
      end

      def user_votes(topics)
        user = @guardian.user
        return {} if user.blank? || topics.empty?

        Vote.where(user_id: user.id, topic_id: topics.map(&:id)).pluck(:topic_id, :value).to_h
      end
    end
  end
end
