# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::CommunityTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:voter, :user)
  fab!(:second_voter, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name: "Technology", slug: "technology", visibility: "public" },
    )
  end

  it "orders top topics by the plugin vote score and exposes the current user's vote" do
    community = create_community
    older = Fabricate(:topic, category: community.category, user: owner, created_at: 2.days.ago)
    newer = Fabricate(:topic, category: community.category, user: owner, created_at: 1.hour.ago)

    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: older, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: second_voter, topic: older, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: newer, value: 1)

    result = described_class.call(community:, guardian: Guardian.new(voter), order: "top")

    expect(result.map { |topic| topic[:id] }).to eq([older.id, newer.id])
    expect(result.first[:score]).to eq(2)
    expect(result.first[:user_vote]).to eq(1)
  end

  it "exposes Discourse author and creation context for visible community topics" do
    community = create_community
    topic = Fabricate(:topic, category: community.category, user: owner, created_at: 3.hours.ago)

    result = described_class.call(community:, guardian: Guardian.new(voter), order: "new")
    item = result.find { |candidate| candidate[:id] == topic.id }

    expect(item[:created_at]).to eq(topic.created_at)
    expect(item.dig(:author, :id)).to eq(owner.id)
    expect(item.dig(:author, :username)).to eq(owner.username)
    expect(item.dig(:author, :avatar_template)).to eq(owner.avatar_template)
    expect(item.dig(:author, :path)).to eq("/u/#{owner.username}")
  end

  it "orders new topics by Discourse topic creation time" do
    community = create_community
    older = Fabricate(:topic, category: community.category, user: owner, created_at: 2.days.ago)
    newer = Fabricate(:topic, category: community.category, user: owner, created_at: 1.hour.ago)

    result = described_class.call(community:, guardian: Guardian.new(voter), order: "new")

    expect(result.map { |topic| topic[:id] }).to eq([newer.id, older.id])
  end

  it "keeps unvoted topics eligible for hot ranking" do
    community = create_community
    older = Fabricate(:topic, category: community.category, user: owner, created_at: 2.days.ago)
    newer = Fabricate(:topic, category: community.category, user: owner, created_at: 1.hour.ago)

    result = described_class.call(community:, guardian: Guardian.new(voter), order: "hot")

    expect(result.map { |topic| topic[:id] }).to eq([newer.id, older.id])
    expect(result.first[:score]).to eq(0)
  end

  it "ranks recent vote velocity above stale lifetime score" do
    community = create_community
    recent_mover = Fabricate(:topic, category: community.category, user: owner, created_at: 2.days.ago)
    stale_leader = Fabricate(:topic, category: community.category, user: owner, created_at: 1.day.ago)

    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: recent_mover, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: stale_leader, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: second_voter, topic: stale_leader, value: 1)
    DiscourseCommunityPlatform::Vote.where(topic_id: stale_leader.id).update_all(updated_at: 2.days.ago)

    result = described_class.call(community:, guardian: Guardian.new(voter), order: "rising")

    expect(result.map { |topic| topic[:id] }).to eq([recent_mover.id, stale_leader.id])
    expect(result.first[:score]).to eq(1)
    expect(result.second[:score]).to eq(2)
  end

  it "filters topics through the current Guardian" do
    community = create_community
    visible_topic = Fabricate(:topic, category: community.category, user: owner)
    hidden_topic = Fabricate(:topic, category: community.category, user: owner, visible: false)

    result = described_class.call(community:, guardian: Guardian.new(voter), order: "new")

    expect(result.map { |topic| topic[:id] }).to include(visible_topic.id)
    expect(result.map { |topic| topic[:id] }).not_to include(hidden_topic.id)
  end
end
