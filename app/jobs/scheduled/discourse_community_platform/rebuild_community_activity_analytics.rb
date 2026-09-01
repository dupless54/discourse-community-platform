# frozen_string_literal: true

module Jobs
  module DiscourseCommunityPlatform
    class RebuildCommunityActivityAnalytics < ::Jobs::Scheduled
      every 15.minutes

      def execute(_args = {})
        ::DiscourseCommunityPlatform::Analytics::CommunityActivity.rebuild_cache
      end
    end
  end
end
