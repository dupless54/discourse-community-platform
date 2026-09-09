# frozen_string_literal: true

RSpec.describe Jobs::DiscourseCommunityPlatform do
  around do |example|
    original_enabled = SiteSetting.community_platform_enabled

    begin
      SiteSetting.community_platform_enabled = false
      example.run
    ensure
      SiteSetting.community_platform_enabled = original_enabled
    end
  end

  it "does not rebuild Explore recommendations while the plugin is disabled" do
    allow(DiscourseCommunityPlatform::Feeds::ExploreCommunities).to receive(:rebuild_cache)

    Jobs::DiscourseCommunityPlatform::RebuildExploreRecommendations.new.execute({})

    expect(DiscourseCommunityPlatform::Feeds::ExploreCommunities).not_to have_received(:rebuild_cache)
  end

  it "does not rebuild activity analytics while the plugin is disabled" do
    allow(DiscourseCommunityPlatform::Analytics::CommunityActivity).to receive(:rebuild_cache)

    Jobs::DiscourseCommunityPlatform::RebuildCommunityActivityAnalytics.new.execute({})

    expect(DiscourseCommunityPlatform::Analytics::CommunityActivity).not_to have_received(:rebuild_cache)
  end

  it "does not rebuild the Popular feed while the plugin is disabled" do
    allow(DiscourseCommunityPlatform::Feeds::PopularTopics).to receive(:rebuild_cache)

    Jobs::DiscourseCommunityPlatform::RebuildPopularFeed.new.execute({})

    expect(DiscourseCommunityPlatform::Feeds::PopularTopics).not_to have_received(:rebuild_cache)
  end

  it "does not prune AutoModerator audit history while the plugin is disabled" do
    allow(DiscourseCommunityPlatform::AutomodExecution).to receive(:where)

    Jobs::DiscourseCommunityPlatform::PruneAutomodExecutions.new.execute({})

    expect(DiscourseCommunityPlatform::AutomodExecution).not_to have_received(:where)
  end
end
