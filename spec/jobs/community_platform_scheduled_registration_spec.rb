# frozen_string_literal: true

RSpec.describe Jobs::DiscourseCommunityPlatform do
  scheduled_jobs = {
    Jobs::DiscourseCommunityPlatform::RebuildPopularFeed => 5.minutes,
    Jobs::DiscourseCommunityPlatform::RebuildExploreRecommendations => 10.minutes,
    Jobs::DiscourseCommunityPlatform::RebuildCommunityActivityAnalytics => 15.minutes,
    Jobs::DiscourseCommunityPlatform::PruneAutomodExecutions => 1.day,
  }.freeze

  scheduled_jobs.each do |job_class, cadence|
    it "registers #{job_class.name} with MiniScheduler every #{cadence.inspect}" do
      expect(job_class).to be < Jobs::Scheduled
      expect(job_class).to be_scheduled
      expect(job_class.every).to eq(cadence)
      expect(job_class.queue).to eq("default")
    end
  end
end
