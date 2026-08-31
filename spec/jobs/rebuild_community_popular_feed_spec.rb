# frozen_string_literal: true

RSpec.describe Jobs::DiscourseCommunityPlatform::RebuildPopularFeed do
  it "rebuilds the cached global popular topic ids" do
    allow(DiscourseCommunityPlatform::Feeds::PopularTopics).to receive(:rebuild_cache)

    described_class.new.execute({})

    expect(DiscourseCommunityPlatform::Feeds::PopularTopics).to have_received(:rebuild_cache).once
  end
end
