# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::CommunitiesController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:viewer, :user)
  fab!(:second_voter, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community(visibility: "public", slug: "technology")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name: slug.titleize, slug:, visibility: },
    )
  end

  it "returns ranked topic summaries without duplicating topic content" do
    community = create_community
    low = Fabricate(:topic, category: community.category, user: owner, created_at: 1.hour.ago)
    high = Fabricate(:topic, category: community.category, user: owner, created_at: 2.hours.ago)

    DiscourseCommunityPlatform::Votes::Cast.call(user: viewer, topic: high, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: second_voter, topic: high, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: viewer, topic: low, value: 1)

    sign_in(viewer)
    get "/community-platform/communities/#{community.slug}/topics.json", params: { order: "top" }

    expect(response.status).to eq(200)
    body = response.parsed_body

    expect(body["order"]).to eq("top")
    expect(body["topics"].map { |topic| topic["id"] }).to eq([high.id, low.id])
    expect(body["topics"].first["score"]).to eq(2)
    expect(body["topics"].first["user_vote"]).to eq(1)
    expect(body["topics"].first).not_to have_key("posts")
  end

  it "falls back to hot for an unknown order" do
    community = create_community
    Fabricate(:topic, category: community.category, user: owner)

    get "/community-platform/communities/#{community.slug}/topics.json", params: { order: "unknown" }

    expect(response.status).to eq(200)
    expect(response.parsed_body["order"]).to eq("hot")
  end

  it "does not expose a private community feed to an unauthorized user" do
    community = create_community(visibility: "private", slug: "private-tech")
    topic = Fabricate(:topic, category: community.category, user: owner)
    sign_in(viewer)

    get "/community-platform/communities/#{community.slug}/topics.json"

    expect(response.status).to eq(404)
    expect(response.body).not_to include(topic.title)
  end
end
