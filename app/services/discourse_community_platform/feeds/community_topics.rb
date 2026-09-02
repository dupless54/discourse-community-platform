# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class CommunityTopics
      ORDERS = %w[hot new top rising].freeze
      DEFAULT_LIMIT = 30
      MAX_LIMIT = 50
      HOT_EPOCH_SECONDS = Time.utc(2020, 1, 1).to_i
      RISING_WINDOW = 24.hours

      def self.call(community:, guardian:, order: "hot", limit: DEFAULT_LIMIT)
        new(community:, guardian:, order:, limit:).call
      end

      def initialize(community:, guardian:, order:, limit:)
        @community = community
        @guardian = guardian
        @order = ORDERS.include?(order.to_s) ? order.to_s : "hot"
        @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
      end

      def call
        topics = ranked_scope.limit(@limit * 3).to_a
        topics.select! { |topic| @guardian.can_see_topic?(topic) }
        topics = topics.first(@limit)

        scores = TopicScore.where(topic_id: topics.map(&:id)).index_by(&:topic_id)
        votes = user_votes(topics)
        previews = TopicPreviews.call(topics:, guardian: @guardian)

        topics.map do |topic|
          score = scores[topic.id]
          preview = previews.fetch(topic.id, {})
          item = {
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
          }

          item[:author] = topic_author(topic) if topic.user
          item
        end
      end

      private

      def ranked_scope
        scope =
          Topic
            .where(category_id: @community.category_id, deleted_at: nil, visible: true)
            .where(archetype: Archetype.default)
            .where.not(id: @community.category.topic_id)
            .includes(:user)
            .joins(
              <<~SQL.squish,
                LEFT JOIN discourse_community_platform_topic_scores dcp_scores
                  ON dcp_scores.topic_id = topics.id
                  AND dcp_scores.community_id = #{@community.id.to_i}
              SQL
            )

        scope = scope.joins(rising_join_sql) if @order == "rising"

        case @order
        when "new"
          scope.order(created_at: :desc, id: :desc)
        when "top"
          scope.order(Arel.sql("COALESCE(dcp_scores.score, 0) DESC, topics.created_at DESC"))
        when "rising"
          scope.order(
            Arel.sql(
              "(COALESCE(dcp_rising.recent_score, 0) * 4.0 + " \
                "COALESCE(dcp_rising.recent_votes, 0) * 1.5 + " \
                "LEAST(GREATEST(topics.posts_count - 1, 0), 20) * 0.15) DESC, " \
                "COALESCE(topics.last_posted_at, topics.created_at) DESC, topics.id DESC",
            ),
          )
        else
          scope.order(
            Arel.sql(
              "COALESCE(dcp_scores.hot_score, " \
                "(EXTRACT(EPOCH FROM topics.created_at) - #{HOT_EPOCH_SECONDS}) / 45000.0) DESC, " \
                "topics.id DESC",
            ),
          )
        end
      end

      def rising_join_sql
        cutoff = ActiveRecord::Base.connection.quote(RISING_WINDOW.ago)

        <<~SQL.squish
          LEFT JOIN (
            SELECT topic_id, SUM(value) AS recent_score, COUNT(*) AS recent_votes
            FROM discourse_community_platform_votes
            WHERE community_id = #{@community.id.to_i}
              AND updated_at >= #{cutoff}
            GROUP BY topic_id
          ) dcp_rising ON dcp_rising.topic_id = topics.id
        SQL
      end

      def topic_author(topic)
        {
          id: topic.user.id,
          username: topic.user.username,
          name: topic.user.name,
          avatar_template: topic.user.avatar_template,
          path: "/u/#{topic.user.username}",
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
