# frozen_string_literal: true

module ::Jobs
  class RebuildCommunityPopularFeed < ::Jobs::Scheduled
    every 5.minutes

    def execute(_args)
      ::DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache
    end
  end
end
