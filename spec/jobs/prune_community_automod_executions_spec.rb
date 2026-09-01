# frozen_string_literal: true

require "digest"

RSpec.describe Jobs::DiscourseCommunityPlatform::PruneAutomodExecutions do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:author, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  it "deletes audit executions older than the retention window" do
    community =
      DiscourseCommunityPlatform::Communities::Create.call(
        user: owner,
        params: { name: "Audit", slug: "audit", visibility: "public" },
      )
    rule =
      DiscourseCommunityPlatform::AutomodRule.create!(
        community:,
        name: "Keyword guard",
        terms: ["blocked phrase"],
        created_by: owner,
        updated_by: owner,
      )
    topic = Fabricate(:topic, category: community.category, user: author)
    old_post = Fabricate(:post, topic:, user: author, raw: "blocked phrase old")
    recent_post = Fabricate(:post, topic:, user: author, raw: "blocked phrase recent")

    old_execution =
      DiscourseCommunityPlatform::AutomodExecution.create!(
        community:,
        automod_rule: rule,
        post: old_post,
        rule_name: rule.name,
        trigger: "create",
        outcome: "queued_for_review",
        content_sha256: Digest::SHA256.hexdigest(old_post.raw),
      )
    recent_execution =
      DiscourseCommunityPlatform::AutomodExecution.create!(
        community:,
        automod_rule: rule,
        post: recent_post,
        rule_name: rule.name,
        trigger: "create",
        outcome: "queued_for_review",
        content_sha256: Digest::SHA256.hexdigest(recent_post.raw),
      )
    old_execution.update_columns(created_at: 91.days.ago, updated_at: 91.days.ago)

    described_class.new.execute

    expect(DiscourseCommunityPlatform::AutomodExecution.exists?(old_execution.id)).to eq(false)
    expect(DiscourseCommunityPlatform::AutomodExecution.exists?(recent_execution.id)).to eq(true)
  end
end
