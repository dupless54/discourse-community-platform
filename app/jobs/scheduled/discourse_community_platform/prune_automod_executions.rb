# frozen_string_literal: true

module Jobs
  module DiscourseCommunityPlatform
    class PruneAutomodExecutions < ::Jobs::Scheduled
      every 1.day

      def execute(_args = {})
        cutoff = ::DiscourseCommunityPlatform::AutomodExecution::RETENTION_DAYS.days.ago
        ::DiscourseCommunityPlatform::AutomodExecution.where("created_at < ?", cutoff).delete_all
      end
    end
  end
end
