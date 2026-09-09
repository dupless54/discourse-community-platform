# frozen_string_literal: true

module Jobs
  module DiscourseCommunityPlatform
    class RebuildCommunityActivityAnalytics < ::Jobs::Scheduled
      every 15.minutes

      def execute(_args = {})
        return unless SiteSetting.community_platform_enabled

        ::DiscourseCommunityPlatform::Analytics::CommunityActivity.rebuild_cache
      end
    end
  end
end
