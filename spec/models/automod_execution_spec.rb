# frozen_string_literal: true

require "digest"

RSpec.describe DiscourseCommunityPlatform::AutomodExecution do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:author, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  let(:community) do
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name: "Audit", slug: "audit", visibility: "public" },
    )
  end
  let(:rule) do
    DiscourseCommunityPlatform::AutomodRule.create!(
      community:,
      name: "Keyword guard",
      terms: ["blocked phrase"],
      created_by: owner,
      updated_by: owner,
    )
  end
  let(:topic) { Fabricate(:topic, category: community.category, user: author) }
  let(:post) { Fabricate(:post, topic:, user: author, raw: "blocked phrase") }

  def build_execution(trigger: "create", outcome: "queued_for_review")
    described_class.new(
      community:,
      automod_rule: rule,
      post:,
      rule_name: rule.name,
      trigger:,
      outcome:,
      content_sha256: Digest::SHA256.hexdigest(post.raw),
    )
  end

  it "accepts bounded create/edit triggers and review outcomes" do
    expect(build_execution).to be_valid
    expect(build_execution(outcome: "flagged_for_review")).to be_valid
    expect(build_execution(trigger: "edit", outcome: "already_queued")).to be_valid
  end

  it "rejects unknown triggers" do
    execution = build_execution(trigger: "delete")

    expect(execution).not_to be_valid
    expect(execution.errors[:trigger]).to be_present
  end

  it "rejects unknown outcomes" do
    execution = build_execution(outcome: "deleted")

    expect(execution).not_to be_valid
    expect(execution.errors[:outcome]).to be_present
  end
end
