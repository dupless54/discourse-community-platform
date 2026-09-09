# frozen_string_literal: true

RSpec.describe Jobs::DiscourseCommunityPlatform::EvaluateAutomodPost do
  fab!(:post)

  it "delegates an existing post to the community AutoModerator evaluator" do
    allow(DiscourseCommunityPlatform::Automod::EvaluatePost).to receive(:call)

    described_class.new.execute(post_id: post.id)

    expect(DiscourseCommunityPlatform::Automod::EvaluatePost).to have_received(:call).with(
      post:,
      trigger: "create",
    )
  end

  it "forwards edit triggers to the community AutoModerator evaluator" do
    allow(DiscourseCommunityPlatform::Automod::EvaluatePost).to receive(:call)

    described_class.new.execute(post_id: post.id, trigger: "edit")

    expect(DiscourseCommunityPlatform::Automod::EvaluatePost).to have_received(:call).with(
      post:,
      trigger: "edit",
    )
  end

  it "ignores a post that no longer exists" do
    allow(DiscourseCommunityPlatform::Automod::EvaluatePost).to receive(:call)

    described_class.new.execute(post_id: -1)

    expect(DiscourseCommunityPlatform::Automod::EvaluatePost).not_to have_received(:call)
  end

  it "does not evaluate an already queued post after the plugin is disabled" do
    original_enabled = SiteSetting.community_platform_enabled
    allow(DiscourseCommunityPlatform::Automod::EvaluatePost).to receive(:call)

    begin
      SiteSetting.community_platform_enabled = false
      described_class.new.execute(post_id: post.id)

      expect(DiscourseCommunityPlatform::Automod::EvaluatePost).not_to have_received(:call)
    ensure
      SiteSetting.community_platform_enabled = original_enabled
    end
  end
end
