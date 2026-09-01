# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Automod
    class EvaluatePost
      def self.call(post:)
        new(post:).call
      end

      def initialize(post:)
        @post = post
      end

      def call
        return if @post.blank? || @post.deleted_at.present? || @post.topic.blank?
        return if @post.topic.archetype == Archetype.private_message
        return if @post.user_id == Discourse.system_user.id

        community = Community.find_by(category_id: @post.topic.category_id)
        return if community.blank?

        matched_rule =
          AutomodRule.where(community_id: community.id, enabled: true).order(:id).find do |rule|
            rule.matches?(@post.raw)
          end
        return if matched_rule.blank?
        return if already_flagged?

        PostActionCreator.new(
          Discourse.system_user,
          @post,
          PostActionType.types[:inappropriate],
          message:
            I18n.t(
              "discourse_community_platform.automod.flag_reason",
              community: community.name,
              rule: matched_rule.name,
            ),
          queue_for_review: true,
        ).perform
      end

      private

      def already_flagged?
        PostAction.exists?(
          post_id: @post.id,
          user_id: Discourse.system_user.id,
          post_action_type_id: PostActionType.types[:inappropriate],
          deleted_at: nil,
        )
      end
    end
  end
end
