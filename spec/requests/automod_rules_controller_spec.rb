# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::AutomodRulesController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:outsider, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name: "Marketplace", slug: "marketplace", visibility: "public" },
    )
  end

  def expect_management_headers
    expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
  end

  it "lets a community manager create, update, list, and remove rules" do
    community = create_community
    sign_in(owner)

    post "/community-platform/communities/#{community.slug}/automod-rules.json",
         params: {
           automod_rule: {
             name: "Spam phrases",
             match_mode: "any",
             target: "replies",
             action: "flag_only",
             max_account_age_days: 14,
             max_trust_level: 1,
             terms: ["  BUY NOW ", "telegram", "telegram"],
           },
         }

    expect(response.status).to eq(201)
    expect_management_headers
    rule = response.parsed_body.fetch("automod_rule")
    expect(rule["terms"]).to eq(["buy now", "telegram"])
    expect(rule["enabled"]).to eq(true)
    expect(rule["target"]).to eq("replies")
    expect(rule["action"]).to eq("flag_only")
    expect(rule["max_account_age_days"]).to eq(14)
    expect(rule["max_trust_level"]).to eq(1)

    patch "/community-platform/communities/#{community.slug}/automod-rules/#{rule.fetch("id")}.json",
          params: {
            automod_rule: {
              enabled: false,
              match_mode: "all",
              target: "topic_starters",
              action: "queue_for_review",
              max_account_age_days: 7,
              max_trust_level: 0,
            },
          }

    expect(response.status).to eq(200)
    expect_management_headers
    updated = response.parsed_body.fetch("automod_rule")
    expect(updated["enabled"]).to eq(false)
    expect(updated["match_mode"]).to eq("all")
    expect(updated["target"]).to eq("topic_starters")
    expect(updated["action"]).to eq("queue_for_review")
    expect(updated["max_account_age_days"]).to eq(7)
    expect(updated["max_trust_level"]).to eq(0)

    get "/community-platform/communities/#{community.slug}/automod-rules.json"

    expect(response.status).to eq(200)
    expect_management_headers
    expect(response.parsed_body.fetch("automod_rules").length).to eq(1)

    delete "/community-platform/communities/#{community.slug}/automod-rules/#{rule.fetch("id")}.json"

    expect(response.status).to eq(204)
    expect_management_headers
    expect(DiscourseCommunityPlatform::AutomodRule.where(community_id: community.id)).to be_empty
  end

  it "rejects author conditions outside the bounded ranges" do
    community = create_community
    sign_in(owner)

    post "/community-platform/communities/#{community.slug}/automod-rules.json",
         params: {
           automod_rule: {
             name: "Unsafe conditions",
             max_account_age_days: 9999,
             max_trust_level: 99,
             terms: ["blocked phrase"],
           },
         }

    expect(response.status).to eq(422)
    expect_management_headers
    expect(DiscourseCommunityPlatform::AutomodRule.count).to eq(0)
  end

  it "rejects unknown target and action values" do
    community = create_community
    sign_in(owner)

    post "/community-platform/communities/#{community.slug}/automod-rules.json",
         params: {
           automod_rule: {
             name: "Unsafe",
             target: "everything_forever",
             action: "delete",
             terms: ["blocked phrase"],
           },
         }

    expect(response.status).to eq(422)
    expect_management_headers
    expect(DiscourseCommunityPlatform::AutomodRule.count).to eq(0)
  end

  it "rejects rule management by an unrelated authenticated user" do
    community = create_community
    sign_in(outsider)

    get "/community-platform/communities/#{community.slug}/automod-rules.json"
    expect(response.status).to eq(403)
    expect_management_headers

    post "/community-platform/communities/#{community.slug}/automod-rules.json",
         params: { automod_rule: { name: "Hijack", terms: ["anything"] } }

    expect(response.status).to eq(403)
    expect_management_headers
    expect(DiscourseCommunityPlatform::AutomodRule.count).to eq(0)
  end

  it "requires authentication" do
    community = create_community

    get "/community-platform/communities/#{community.slug}/automod-rules.json"

    expect(response.status).to eq(403)
  end

  it "rejects invalid or empty term sets" do
    community = create_community
    sign_in(owner)

    post "/community-platform/communities/#{community.slug}/automod-rules.json",
         params: { automod_rule: { name: "Empty", terms: [] } }

    expect(response.status).to eq(422)
    expect_management_headers
    expect(DiscourseCommunityPlatform::AutomodRule.count).to eq(0)
  end
end
