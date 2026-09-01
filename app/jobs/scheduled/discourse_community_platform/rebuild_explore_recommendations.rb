# frozen_string_literal: true

module Jobs
  module DiscourseCommunityPlatform
    class RebuildExploreRecommendations < ::Jobs::Scheduled
      every 10.minutes

      def execute(_args = {})
        ::DiscourseCommunityPlatform::Feeds::ExploreCommunities.rebuild_cache
      end
    end
  end
end
