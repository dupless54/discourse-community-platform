# frozen_string_literal: true

module Jobs
  module DiscourseCommunityPlatform
    class PruneAutomodExecutions < ::Jobs::Scheduled
      every 1.day

      def execute(_args = {})
        return unless SiteSetting.community_platform_enabled

        cutoff = ::DiscourseCommunityPlatform::AutomodExecution::RETENTION_DAYS.days.ago
        ::DiscourseCommunityPlatform::AutomodExecution.where("created_at < ?", cutoff).delete_all
      end
    end
  end
end
