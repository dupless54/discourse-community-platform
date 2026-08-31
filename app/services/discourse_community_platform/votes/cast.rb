# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Votes
    class Cast
      VALID_VALUES = [-1, 0, 1].freeze
      HOT_EPOCH = Time.utc(2020, 1, 1).freeze

      def self.call(user:, topic:, value:)
        new(user:, topic:, value:).call
      end

      def initialize(user:, topic:, value:)
        @user = user
        @topic = topic
        @value = Integer(value, exception: false)
      end

      def call
        ensure_vote_allowed!
        community = Community.find_by!(category_id: @topic.category_id)
        guardian = Guardian.new(@user)
        raise Discourse::NotFound unless guardian.can_see_topic?(@topic)

        score = nil
        user_vote = nil

        Vote.transaction do
          score = TopicScore.create_or_find_by!(topic_id: @topic.id) { |row| row.community_id = community.id }
          score.lock!
          score.update!(community_id: community.id) if score.community_id != community.id

          vote = Vote.find_by(user_id: @user.id, topic_id: @topic.id)

          if @value.zero?
            vote&.destroy!
          elsif vote
            vote.update!(community_id: community.id, value: @value)
          else
            Vote.create!(community:, topic: @topic, user: @user, value: @value)
          end

          counts = Vote.where(topic_id: @topic.id).group(:value).count
          upvotes = counts.fetch(1, 0)
          downvotes = counts.fetch(-1, 0)
          raw_score = upvotes - downvotes

          score.update!(
            upvotes:,
            downvotes:,
            score: raw_score,
            hot_score: hot_score(raw_score),
          )

          user_vote = @value
        end

        {
          topic_id: @topic.id,
          community_id: community.id,
          upvotes: score.upvotes,
          downvotes: score.downvotes,
          score: score.score,
          hot_score: score.hot_score.to_f,
          user_vote:,
        }
      end

      private

      def ensure_vote_allowed!
        raise Discourse::InvalidAccess if @user.blank?
        raise Discourse::InvalidAccess if @user.staged? || @user.suspended? || @user.silenced?
        raise Discourse::InvalidParameters.new(:value) if VALID_VALUES.exclude?(@value)
        raise Discourse::NotFound if @topic.blank? || @topic.trashed? || @topic.private_message?
        raise Discourse::InvalidAccess if @topic.is_category_topic?
      end

      def hot_score(raw_score)
        order = Math.log10([raw_score.abs, 1].max)
        sign = raw_score <=> 0
        age_component = (@topic.created_at.to_f - HOT_EPOCH.to_f) / 45_000.0

        (sign * order + age_component).round(8)
      end
    end
  end
end
