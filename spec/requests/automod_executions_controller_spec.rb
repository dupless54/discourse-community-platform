# frozen_string_literal: true

require "digest"

RSpec.describe DiscourseCommunityPlatform::AutomodExecutionsController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:outsider, :user)
  fab!(:author, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community(name: "Marketplace", slug: "marketplace")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: "public" },
    )
  end

  def create_execution(community:)
    rule =
      DiscourseCommunityPlatform::AutomodRule.create!(
        community:,
        name: "Keyword guard",
        terms: ["blocked phrase"],
        created_by: owner,
        updated_by: owner,
      )
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase")

    DiscourseCommunityPlatform::AutomodExecution.create!(
      community:,
      automod_rule: rule,
      post:,
      rule_name: rule.name,
      trigger: "edit",
      outcome: "queued_for_review",
      content_sha256: Digest::SHA256.hexdigest(post.raw),
    )
  end

  it "returns manager-only AutoModerator audit history" do
    community = create_community
    execution = create_execution(community:)
    sign_in(owner)

    get "/community-platform/communities/#{community.slug}/automod-executions.json"

    expect(response.status).to eq(200)
    item = response.parsed_body.fetch("automod_executions").first
    expect(item).to include(
      "id" => execution.id,
      "post_id" => execution.post_id,
      "username" => author.username,
      "rule_name" => "Keyword guard",
      "trigger" => "edit",
      "outcome" => "queued_for_review",
    )
    expect(item.fetch("post_url")).to be_present
  end

  it "does not expose history to unrelated authenticated users" do
    community = create_community
    create_execution(community:)
    sign_in(outsider)

    get "/community-platform/communities/#{community.slug}/automod-executions.json"

    expect(response.status).to eq(403)
  end

  it "requires authentication" do
    community = create_community

    get "/community-platform/communities/#{community.slug}/automod-executions.json"

    expect(response.status).to eq(403)
  end
end
