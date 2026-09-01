# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::FeedsController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:voter, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
  end

  after { Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY) }

  it "returns cached popular topic summaries without duplicating Discourse topic content" do
    community =
      DiscourseCommunityPlatform::Communities::Create.call(
        user: owner,
        params: { name: "Technology", slug: "technology", visibility: "public" },
      )
    topic = Fabricate(:topic, category: community.category, user: owner)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic:, value: 1)
    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache

    get "/community-platform/feeds/popular.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body
    expect(payload["order"]).to eq("popular")
    expect(payload["topics"].first["id"]).to eq(topic.id)
    expect(payload["topics"].first.dig("community", "slug")).to eq("technology")
    expect(payload["topics"].first).not_to have_key("raw")
    expect(payload["topics"].first).not_to have_key("posts")
  end

  it "returns no personalized Following data to guests" do
    get "/community-platform/feeds/following.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body
    expect(payload["order"]).to eq("following")
    expect(payload["login_required"]).to eq(true)
    expect(payload["personalized"]).to eq(false)
    expect(payload["joined_communities"]).to eq([])
    expect(payload["topics"]).to eq([])
  end
end
