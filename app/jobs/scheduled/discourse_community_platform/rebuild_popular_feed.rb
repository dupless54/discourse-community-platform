# frozen_string_literal: true

module Jobs
  module DiscourseCommunityPlatform
    class RebuildPopularFeed < ::Jobs::Scheduled
      every 5.minutes

      def execute(_args = {})
        ::DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache
      end
    end
  end
end
