# frozen_string_literal: true

require "digest"

module ::DiscourseCommunityPlatform
  module Automod
    class EvaluatePost
      MUTEX_VALIDITY = 2.minutes

      def self.call(post:, trigger: "create")
        new(post:, trigger:).call
      end

      def initialize(post:, trigger:)
        @post = post
        @trigger = trigger.to_s
      end

      def call
        return if @post.blank? || @post.deleted_at.present? || @post.topic.blank?
        return if AutomodExecution::TRIGGERS.exclude?(@trigger)
        return if @post.topic.archetype == Archetype.private_message
        return if @post.user_id == Discourse.system_user.id

        DistributedMutex.synchronize(
          "discourse-community-platform-automod-post-#{@post.id}",
          validity: MUTEX_VALIDITY,
        ) { evaluate_current_content }
      end

      private

      def evaluate_current_content
        @post.reload
        return if @post.deleted_at.present? || @post.topic.blank?

        community = Community.find_by(category_id: @post.topic.category_id)
        return if community.blank?

        matched_rule =
          AutomodRule
            .where(community_id: community.id, enabled: true)
            .order(:id)
            .limit(AutomodRule::MAX_RULES_PER_COMMUNITY)
            .detect { |rule| rule.applies_to?(@post) && rule.matches?(@post.raw) }
        return if matched_rule.blank?

        content_sha256 = Digest::SHA256.hexdigest(@post.raw.to_s)
        return if already_audited?(matched_rule, content_sha256)

        if already_flagged?
          record_execution(
            community:,
            rule: matched_rule,
            content_sha256:,
            outcome: "already_queued",
          )
          return
        end

        result =
          PostActionCreator.new(
            Discourse.system_user,
            @post,
            PostActionType.types[:inappropriate],
            message:
              I18n.t(
                "community_platform.automod.flag_reason",
                community: community.name,
                rule: matched_rule.name,
              ),
            queue_for_review: matched_rule.queue_for_review?,
          ).perform
        return unless result.success?

        record_execution(
          community:,
          rule: matched_rule,
          content_sha256:,
          outcome: matched_rule.queue_for_review? ? "queued_for_review" : "flagged_for_review",
        )
      end

      def already_audited?(rule, content_sha256)
        AutomodExecution.exists?(
          automod_rule_id: rule.id,
          post_id: @post.id,
          content_sha256:,
        )
      end

      def record_execution(community:, rule:, content_sha256:, outcome:)
        AutomodExecution.create!(
          community_id: community.id,
          automod_rule_id: rule.id,
          post_id: @post.id,
          rule_name: rule.name,
          trigger: @trigger,
          outcome:,
          content_sha256:,
        )
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      def already_flagged?
        inappropriate_type_id = PostActionType.types[:inappropriate]
        system_user_id = Discourse.system_user.id

        return true if
          PostAction.exists?(
            post_id: @post.id,
            user_id: system_user_id,
            post_action_type_id: inappropriate_type_id,
            deleted_at: nil,
          )

        reviewable = ReviewableFlaggedPost.find_by(target: @post)
        return false if reviewable.blank?

        reviewable.reviewable_scores.exists?(
          user_id: system_user_id,
          reviewable_score_type: inappropriate_type_id,
        )
      end
    end
  end
end
