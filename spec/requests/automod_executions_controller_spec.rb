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

  def expect_management_headers
    expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
  end

  it "returns manager-only AutoModerator audit history" do
    community = create_community
    execution = create_execution(community:)
    sign_in(owner)

    get "/community-platform/communities/#{community.slug}/automod-executions.json"

    expect(response.status).to eq(200)
    expect_management_headers
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

  it "returns aggregate moderation insights without post or user metadata" do
    community = create_community
    create_execution(community:)
    sign_in(owner)

    get "/community-platform/communities/#{community.slug}/moderation-insights.json"

    expect(response.status).to eq(200)
    expect_management_headers
    insights = response.parsed_body.fetch("moderation_insights")
    expect(insights.dig("last_7_days", "executions")).to eq(1)
    expect(insights.dig("last_30_days", "unique_posts")).to eq(1)
    expect(insights.dig("triggers_30_days", "edit")).to eq(1)
    expect(insights.fetch("top_rules_30_days").first).to include(
      "rule_name" => "Keyword guard",
      "executions" => 1,
    )
    expect(response.body).not_to include(author.username)
    expect(response.body).not_to include("post_url")
    expect(response.body).not_to include("post_id")
  end

  it "hides post metadata when the audited post is no longer visible to the manager" do
    community = create_community
    execution = create_execution(community:)
    private_category = Fabricate(:private_category, group: Fabricate(:group))
    execution.post.topic.update!(category: private_category)
    sign_in(owner)

    get "/community-platform/communities/#{community.slug}/automod-executions.json"

    expect(response.status).to eq(200)
    item = response.parsed_body.fetch("automod_executions").first
    expect(item.fetch("post_url")).to be_nil
    expect(item.fetch("username")).to be_nil
  end

  it "keeps a rule-name snapshot after the original rule is removed" do
    community = create_community
    execution = create_execution(community:)
    execution.automod_rule.destroy!
    sign_in(owner)

    get "/community-platform/communities/#{community.slug}/automod-executions.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("automod_executions", 0, "rule_name")).to eq("Keyword guard")
  end

  it "does not expose history or insights to unrelated authenticated users" do
    community = create_community
    create_execution(community:)
    sign_in(outsider)

    get "/community-platform/communities/#{community.slug}/automod-executions.json"
    expect(response.status).to eq(403)
    expect_management_headers

    get "/community-platform/communities/#{community.slug}/moderation-insights.json"
    expect(response.status).to eq(403)
    expect_management_headers
  end

  it "requires authentication for history and insights" do
    community = create_community

    get "/community-platform/communities/#{community.slug}/automod-executions.json"
    expect(response.status).to eq(403)

    get "/community-platform/communities/#{community.slug}/moderation-insights.json"
    expect(response.status).to eq(403)
  end
end
