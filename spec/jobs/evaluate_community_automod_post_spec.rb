# frozen_string_literal: true

RSpec.describe Jobs::DiscourseCommunityPlatform::EvaluateAutomodPost do
  fab!(:post)

  it "delegates an existing post to the community AutoModerator evaluator" do
    allow(DiscourseCommunityPlatform::Automod::EvaluatePost).to receive(:call)

    described_class.new.execute(post_id: post.id)

    expect(DiscourseCommunityPlatform::Automod::EvaluatePost).to have_received(:call).with(post:)
  end

  it "ignores a post that no longer exists" do
    allow(DiscourseCommunityPlatform::Automod::EvaluatePost).to receive(:call)

    described_class.new.execute(post_id: -1)

    expect(DiscourseCommunityPlatform::Automod::EvaluatePost).not_to have_received(:call)
  end
end
