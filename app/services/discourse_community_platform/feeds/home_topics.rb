# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class HomeTopics
      DEFAULT_LIMIT = PopularTopics::DEFAULT_LIMIT
      MAX_LIMIT = PopularTopics::MAX_LIMIT
      CANDIDATE_MULTIPLIER = 3

      def self.call(guardian:, limit: DEFAULT_LIMIT)
        new(guardian:, limit:).call
      end

      def initialize(guardian:, limit:)
        @guardian = guardian
        @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
      end

      def call
        popular_topics = PopularTopics.call(guardian: @guardian, limit: @limit)
        user = @guardian.user

        return payload(topics: mark_popular(popular_topics), communities: [], personalized: false) if user.blank?

        communities = visible_joined_communities(user)
        return payload(topics: mark_popular(popular_topics), communities: [], personalized: false) if communities.empty?

        joined_topics = ranked_joined_topics(communities)
        joined_items = serialize_joined(joined_topics, communities)
        joined_ids = joined_items.to_h { |topic| [topic[:id], true] }

        fallback_items =
          popular_topics.filter_map do |topic|
            next if joined_ids[topic[:id]]

            topic.merge(feed_source: "popular")
          end

        payload(
          topics: (joined_items + fallback_items).first(@limit),
          communities:,
          personalized: true,
        )
      end

      private

      def visible_joined_communities(user)
        group_ids = ::GroupUser.where(user_id: user.id).pluck(:group_id)
        return [] if group_ids.empty?

        Community
          .where(member_group_id: group_ids)
          .includes(:category)
          .order(:id)
          .select { |community| @guardian.can_see_category?(community.category) }
      end

      def ranked_joined_topics(communities)
        category_ids = communities.map(&:category_id)
        category_topic_ids = communities.filter_map { |community| community.category.topic_id }

        scope =
          Topic
            .where(category_id: category_ids, deleted_at: nil, visible: true)
            .where(archetype: Archetype.default)
            .joins(
              <<~SQL.squish,
                LEFT JOIN discourse_community_platform_topic_scores dcp_home_scores
                  ON dcp_home_scores.topic_id = topics.id
              SQL
            )

        scope = scope.where.not(id: category_topic_ids) if category_topic_ids.any?

        topics =
          scope
            .order(
              Arel.sql(
                "COALESCE(dcp_home_scores.hot_score, " \
                  "(EXTRACT(EPOCH FROM topics.created_at) - #{CommunityTopics::HOT_EPOCH_SECONDS}) / 45000.0) DESC, " \
                  "topics.id DESC",
              ),
            )
            .limit(@limit * CANDIDATE_MULTIPLIER)
            .to_a

        topics.select! { |topic| @guardian.can_see_topic?(topic) }
        topics.first(@limit)
      end

      def serialize_joined(topics, communities)
        scores = TopicScore.where(topic_id: topics.map(&:id)).index_by(&:topic_id)
        communities_by_category = communities.index_by(&:category_id)
        votes = user_votes(topics)

        topics.filter_map do |topic|
          community = communities_by_category[topic.category_id]
          next if community.blank?

          score = scores[topic.id]

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
            feed_source: "joined",
            community: {
              id: community.id,
              name: community.name,
              slug: community.slug,
              path: "/s/#{community.slug}",
            },
          }
        end
      end

      def user_votes(topics)
        user = @guardian.user
        return {} if user.blank? || topics.empty?

        Vote.where(user_id: user.id, topic_id: topics.map(&:id)).pluck(:topic_id, :value).to_h
      end

      def mark_popular(topics)
        topics.map { |topic| topic.merge(feed_source: "popular") }
      end

      def payload(topics:, communities:, personalized:)
        {
          order: "home",
          personalized:,
          joined_communities:
            communities.map do |community|
              {
                id: community.id,
                name: community.name,
                slug: community.slug,
                path: "/s/#{community.slug}",
              }
            end,
          topics:,
        }
      end
    end
  end
end
