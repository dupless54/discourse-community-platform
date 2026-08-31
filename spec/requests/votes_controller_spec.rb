# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::VotesController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:voter, :user)

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

  it "casts and removes a vote through the HTTP contract" do
    community = create_community
    topic = Fabricate(:topic, category: community.category, user: owner)
    sign_in(voter)

    put "/community-platform/topics/#{topic.id}/vote.json", params: { value: 1 }

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("vote", "score")).to eq(1)
    expect(response.parsed_body.dig("vote", "user_vote")).to eq(1)

    put "/community-platform/topics/#{topic.id}/vote.json", params: { value: 0 }

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("vote", "score")).to eq(0)
    expect(response.parsed_body.dig("vote", "user_vote")).to eq(0)
  end

  it "requires authentication" do
    community = create_community
    topic = Fabricate(:topic, category: community.category, user: owner)

    put "/community-platform/topics/#{topic.id}/vote.json", params: { value: 1 }

    expect(response.status).to eq(403)
  end

  it "returns not found instead of leaking a private community topic" do
    community = create_community(visibility: "private", slug: "private-tech")
    topic = Fabricate(:topic, category: community.category, user: owner)
    sign_in(voter)

    put "/community-platform/topics/#{topic.id}/vote.json", params: { value: 1 }

    expect(response.status).to eq(404)
    expect(DiscourseCommunityPlatform::Vote.where(topic_id: topic.id)).to be_empty
  end

  it "rejects invalid vote values" do
    community = create_community
    topic = Fabricate(:topic, category: community.category, user: owner)
    sign_in(voter)

    put "/community-platform/topics/#{topic.id}/vote.json", params: { value: 2 }

    expect(response.status).to eq(400)
  end
end
