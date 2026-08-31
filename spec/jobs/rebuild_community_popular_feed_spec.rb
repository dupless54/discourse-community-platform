# frozen_string_literal: true

RSpec.describe Jobs::RebuildCommunityPopularFeed do
  it "rebuilds the cached global popular topic ids" do
    expect(DiscourseCommunityPlatform::Feeds::PopularTopics).to receive(:rebuild_cache)

    described_class.new.execute({})
  end
end
