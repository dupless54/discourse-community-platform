# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::FeedsController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)
  fab!(:voter, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 5
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
  end

  after { Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY) }

  def create_community(name:, slug:)
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: "public" },
    )
  end

  it "returns a personalized home payload for a signed-in community member" do
    joined_community = create_community(name: "Hardware", slug: "hardware")
    popular_community = create_community(name: "Gaming", slug: "gaming")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community: joined_community)

    joined_topic = Fabricate(:topic, category: joined_community.category, user: owner)
    popular_topic = Fabricate(:topic, category: popular_community.category, user: owner)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: popular_topic, value: 1)
    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache
    sign_in(member)

    get "/community-platform/feeds/home.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body
    expect(payload["order"]).to eq("home")
    expect(payload["personalized"]).to eq(true)
    expect(payload["joined_communities"].first["slug"]).to eq("hardware")
    expect(payload["topics"].first["id"]).to eq(joined_topic.id)
    expect(payload["topics"].first["feed_source"]).to eq("joined")
    expect(payload["topics"].map { |topic| topic["id"] }).to include(popular_topic.id)
    expect(payload["topics"].first).not_to have_key("raw")
    expect(payload["topics"].first).not_to have_key("posts")
  end

  it "returns a non-personalized popular fallback to guests" do
    community = create_community(name: "Technology", slug: "technology")
    topic = Fabricate(:topic, category: community.category, user: owner)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic:, value: 1)
    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache

    get "/community-platform/feeds/home.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body
    expect(payload["personalized"]).to eq(false)
    expect(payload["joined_communities"]).to eq([])
    expect(payload["topics"].first["id"]).to eq(topic.id)
    expect(payload["topics"].first["feed_source"]).to eq("popular")
  end
end
