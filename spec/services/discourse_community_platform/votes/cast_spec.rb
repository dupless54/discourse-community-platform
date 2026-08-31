# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Votes::Cast do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:voter, :user)
  fab!(:other_voter, :user)

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

  it "creates, switches, and removes a vote while keeping the score aggregate exact" do
    community = create_community
    topic = Fabricate(:topic, category: community.category, user: owner)

    upvote = described_class.call(user: voter, topic:, value: 1)

    expect(upvote[:upvotes]).to eq(1)
    expect(upvote[:downvotes]).to eq(0)
    expect(upvote[:score]).to eq(1)
    expect(upvote[:user_vote]).to eq(1)

    downvote = described_class.call(user: voter, topic:, value: -1)

    expect(downvote[:upvotes]).to eq(0)
    expect(downvote[:downvotes]).to eq(1)
    expect(downvote[:score]).to eq(-1)
    expect(DiscourseCommunityPlatform::Vote.where(user_id: voter.id, topic_id: topic.id).count).to eq(1)

    removed = described_class.call(user: voter, topic:, value: 0)

    expect(removed[:upvotes]).to eq(0)
    expect(removed[:downvotes]).to eq(0)
    expect(removed[:score]).to eq(0)
    expect(removed[:user_vote]).to eq(0)
    expect(DiscourseCommunityPlatform::Vote.where(user_id: voter.id, topic_id: topic.id)).to be_empty
  end

  it "aggregates votes from different users without losing counts" do
    community = create_community
    topic = Fabricate(:topic, category: community.category, user: owner)

    described_class.call(user: voter, topic:, value: 1)
    result = described_class.call(user: other_voter, topic:, value: -1)

    expect(result[:upvotes]).to eq(1)
    expect(result[:downvotes]).to eq(1)
    expect(result[:score]).to eq(0)
    expect(DiscourseCommunityPlatform::TopicScore.find_by!(topic_id: topic.id).score).to eq(0)
  end

  it "does not leak or vote on a private community topic for an unauthorized user" do
    community = create_community(visibility: "private", slug: "private-tech")
    topic = Fabricate(:topic, category: community.category, user: owner)

    expect { described_class.call(user: voter, topic:, value: 1) }.to raise_error(Discourse::NotFound)
    expect(DiscourseCommunityPlatform::Vote.where(topic_id: topic.id)).to be_empty
  end

  it "rejects topics that are not backed by a community" do
    topic = Fabricate(:topic)

    expect { described_class.call(user: voter, topic:, value: 1) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
