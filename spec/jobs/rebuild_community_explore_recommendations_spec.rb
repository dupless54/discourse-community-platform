# frozen_string_literal: true

RSpec.describe Jobs::DiscourseCommunityPlatform::RebuildExploreRecommendations do
  it "rebuilds cached Explore community signals" do
    allow(DiscourseCommunityPlatform::Feeds::ExploreCommunities).to receive(:rebuild_cache)

    described_class.new.execute({})

    expect(DiscourseCommunityPlatform::Feeds::ExploreCommunities).to have_received(:rebuild_cache).once
  end
end
