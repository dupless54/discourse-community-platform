# frozen_string_literal: true

RSpec.describe Jobs::DiscourseCommunityPlatform::RebuildCommunityActivityAnalytics do
  it "rebuilds cached community activity analytics" do
    allow(DiscourseCommunityPlatform::Analytics::CommunityActivity).to receive(:rebuild_cache)

    described_class.new.execute({})

    expect(DiscourseCommunityPlatform::Analytics::CommunityActivity).to have_received(:rebuild_cache)
  end
end
