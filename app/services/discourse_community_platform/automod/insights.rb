# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Automod
    class Insights
      TOP_RULES_LIMIT = 5

      def self.call(community:, now: Time.current)
        new(community:, now:).call
      end

      def initialize(community:, now:)
        @community = community
        @now = now
      end

      def call
        {
          last_7_days: summarize_since(@now - 7.days),
          last_30_days: summarize_since(@now - 30.days),
          triggers_30_days: trigger_counts,
          top_rules_30_days: top_rules,
        }
      end

      private

      def base_scope
        AutomodExecution.where(community_id: @community.id)
      end

      def scope_since(cutoff)
        base_scope.where(created_at: cutoff..@now)
      end

      def summarize_since(cutoff)
        scope = scope_since(cutoff)
        outcome_counts = scope.group(:outcome).count

        {
          executions: outcome_counts.values.sum,
          unique_posts: scope.distinct.count(:post_id),
          queued_for_review: outcome_counts.fetch("queued_for_review", 0),
          flagged_for_review: outcome_counts.fetch("flagged_for_review", 0),
          already_queued: outcome_counts.fetch("already_queued", 0),
        }
      end

      def trigger_counts
        counts = scope_since(@now - 30.days).group(:trigger).count

        {
          create: counts.fetch("create", 0),
          edit: counts.fetch("edit", 0),
        }
      end

      def top_rules
        scope_since(@now - 30.days)
          .group(:rule_name)
          .order(Arel.sql("COUNT(*) DESC"), :rule_name)
          .limit(TOP_RULES_LIMIT)
          .count
          .map { |rule_name, count| { rule_name:, executions: count } }
      end
    end
  end
end
