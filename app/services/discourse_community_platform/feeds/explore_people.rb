# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class ExplorePeople
      DEFAULT_LIMIT = 6
      MAX_LIMIT = 12
      CANDIDATE_TOPIC_LIMIT = 120

      def self.call(guardian:, limit: DEFAULT_LIMIT)
        new(guardian:, limit:).call
      end

      def initialize(guardian:, limit:)
        @guardian = guardian
        @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
      end

      def call
        return [] unless follow_integration_available?

        topic_ids = Discourse.cache.read(PopularTopics::CACHE_KEY) || []
        return [] if topic_ids.empty?

        topics =
          Topic
            .where(id: topic_ids.first(CANDIDATE_TOPIC_LIMIT))
            .includes(:user, :category)
            .index_by(&:id)

        contribution_counts = Hash.new(0)
        ordered_user_ids = []

        topic_ids.first(CANDIDATE_TOPIC_LIMIT).each do |topic_id|
          topic = topics[topic_id]
          next if topic.blank? || topic.user.blank?
          next unless @guardian.can_see_topic?(topic)

          user_id = topic.user_id
          ordered_user_ids << user_id unless contribution_counts.key?(user_id)
          contribution_counts[user_id] += 1
        end

        current_user = @guardian.user
        excluded_ids = [current_user&.id].compact
        excluded_ids.concat(followed_user_ids(current_user)) if current_user

        candidate_ids = ordered_user_ids.reject { |user_id| excluded_ids.include?(user_id) }
        return [] if candidate_ids.empty?

        users =
          ::UserFollower
            .filter_opted_out_users(User.where(id: candidate_ids, active: true, staged: false))
            .index_by(&:id)

        candidate_ids.filter_map do |user_id|
          user = users[user_id]
          next if user.blank?

          {
            id: user.id,
            username: user.username,
            name: user.name,
            path: "/u/#{user.username}",
            avatar_template: user.avatar_template,
            recent_public_topics_count: contribution_counts[user.id],
          }
        end.first(@limit)
      end

      private

      def follow_integration_available?
        return false unless defined?(::UserFollower)

        SiteSetting.discourse_follow_enabled
      rescue NoMethodError
        false
      end

      def followed_user_ids(user)
        ::UserFollower.where(follower_id: user.id).pluck(:user_id)
      end
    end
  end
end
