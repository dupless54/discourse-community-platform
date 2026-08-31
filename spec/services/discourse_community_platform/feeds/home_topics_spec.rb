# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::HomeTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)
  fab!(:voter, :user)
  fab!(:second_voter, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 8
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
  end

  after { Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY) }

  def create_community(name:, slug:, visibility: "public")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: },
    )
  end

  it "prioritizes topics from joined communities before the global popular fallback" do
    joined_community = create_community(name: "Hardware", slug: "hardware")
    popular_community = create_community(name: "Gaming", slug: "gaming")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community: joined_community)

    joined_topic = Fabricate(:topic, category: joined_community.category, user: owner, created_at: 2.days.ago)
    popular_topic = Fabricate(:topic, category: popular_community.category, user: owner, created_at: 1.hour.ago)

    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: popular_topic, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: second_voter, topic: popular_topic, value: 1)
    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache

    result = described_class.call(guardian: Guardian.new(member), limit: 10)

    expect(result[:personalized]).to eq(true)
    expect(result[:joined_communities].map { |community| community[:slug] }).to include("hardware")
    expect(result[:topics].first[:id]).to eq(joined_topic.id)
    expect(result[:topics].first[:feed_source]).to eq("joined")
    expect(result[:topics].map { |topic| topic[:id] }).to include(popular_topic.id)
    expect(result[:topics].find { |topic| topic[:id] == popular_topic.id }[:feed_source]).to eq("popular")
  end

  it "uses the Guardian-filtered popular feed for guests" do
    community = create_community(name: "Technology", slug: "technology")
    topic = Fabricate(:topic, category: community.category, user: owner)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic:, value: 1)
    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache

    result = described_class.call(guardian: Guardian.new(nil), limit: 10)

    expect(result[:personalized]).to eq(false)
    expect(result[:joined_communities]).to eq([])
    expect(result[:topics].first[:id]).to eq(topic.id)
    expect(result[:topics].first[:feed_source]).to eq("popular")
  end

  it "does not leak a private community to a user who is not a member" do
    private_community = create_community(name: "Private", slug: "private", visibility: "private")
    public_community = create_community(name: "Public", slug: "public")
    private_topic = Fabricate(:topic, category: private_community.category, user: owner)
    public_topic = Fabricate(:topic, category: public_community.category, user: owner)

    DiscourseCommunityPlatform::Votes::Cast.call(user: owner, topic: private_topic, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: public_topic, value: 1)
    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache

    result = described_class.call(guardian: Guardian.new(member), limit: 10)

    expect(result[:topics].map { |topic| topic[:id] }).to include(public_topic.id)
    expect(result[:topics].map { |topic| topic[:id] }).not_to include(private_topic.id)
    expect(result[:joined_communities].map { |community| community[:slug] }).not_to include("private")
  end

  it "includes private-community topics for an authorized member" do
    private_community = create_community(name: "Private", slug: "private", visibility: "private")
    private_topic = Fabricate(:topic, category: private_community.category, user: owner)
    GroupManager.new(private_community.member_group).add([member.id])

    guardian = Guardian.new(member)
    expect(guardian.can_see_topic?(private_topic)).to eq(true)

    result = described_class.call(guardian:, limit: 10)

    expect(result[:personalized]).to eq(true)
    expect(result[:topics].first[:id]).to eq(private_topic.id)
    expect(result[:topics].first[:feed_source]).to eq("joined")
    expect(result[:topics].first.dig(:community, :slug)).to eq("private")
  end

  it "does not duplicate a joined topic when it is also present in popular candidates" do
    community = create_community(name: "Technology", slug: "technology")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community:)
    topic = Fabricate(:topic, category: community.category, user: owner)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic:, value: 1)
    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache

    result = described_class.call(guardian: Guardian.new(member), limit: 10)

    expect(result[:topics].count { |item| item[:id] == topic.id }).to eq(1)
    expect(result[:topics].first[:feed_source]).to eq("joined")
  end
end
