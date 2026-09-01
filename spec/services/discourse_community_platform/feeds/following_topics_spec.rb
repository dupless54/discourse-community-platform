# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::FollowingTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)
  fab!(:followed_user, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 8
  end

  after do
    if @created_user_follower_constant && Object.const_defined?(:UserFollower, false)
      Object.send(:remove_const, :UserFollower)
    end
  end

  def create_community(name:, slug:, visibility: "public")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: },
    )
  end

  def enable_follow_integration_with(*topics)
    unless Object.const_defined?(:UserFollower, false)
      Object.const_set(:UserFollower, Class.new)
      @created_user_follower_constant = true
    end

    UserFollower.stubs(:topics_for).returns(topics)
    SiteSetting.stubs(:discourse_follow_enabled).returns(true)
  end

  it "returns a login-required empty payload for guests without loading Popular" do
    allow(DiscourseCommunityPlatform::Feeds::PopularTopics).to receive(:call)

    result = described_class.call(guardian: Guardian.new(nil), limit: 10)

    expect(result[:order]).to eq("following")
    expect(result[:login_required]).to eq(true)
    expect(result[:personalized]).to eq(false)
    expect(result[:joined_communities]).to eq([])
    expect(result[:topics]).to eq([])
    expect(DiscourseCommunityPlatform::Feeds::PopularTopics).not_to have_received(:call)
  end

  it "combines joined-community and followed-user topics by recency without Popular fallback" do
    joined_community = create_community(name: "Hardware", slug: "hardware")
    followed_community = create_community(name: "Development", slug: "development")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community: joined_community)

    joined_topic =
      Fabricate(:topic, category: joined_community.category, user: owner, created_at: 2.hours.ago)
    followed_topic =
      Fabricate(:topic, category: followed_community.category, user: followed_user, created_at: 1.hour.ago)
    enable_follow_integration_with(followed_topic)
    allow(DiscourseCommunityPlatform::Feeds::PopularTopics).to receive(:call)

    result = described_class.call(guardian: Guardian.new(member), limit: 10)

    expect(result[:order]).to eq("following")
    expect(result[:login_required]).to eq(false)
    expect(result[:personalized]).to eq(true)
    expect(result[:joined_communities].map { |community| community[:slug] }).to eq(["hardware"])
    expect(result[:topics].map { |topic| topic[:id] }).to eq([followed_topic.id, joined_topic.id])
    expect(result[:topics].map { |topic| topic[:feed_source] }).to eq(%w[followed joined])
    expect(result[:topics].first.dig(:author, :username)).to eq(followed_user.username)
    expect(DiscourseCommunityPlatform::Feeds::PopularTopics).not_to have_received(:call)
  end

  it "deduplicates followed topics already sourced from a joined community" do
    community = create_community(name: "Technology", slug: "technology")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community:)
    topic = Fabricate(:topic, category: community.category, user: followed_user)
    enable_follow_integration_with(topic)

    result = described_class.call(guardian: Guardian.new(member), limit: 10)
    matching_items = result[:topics].select { |item| item[:id] == topic.id }

    expect(matching_items.length).to eq(1)
    expect(matching_items.first[:feed_source]).to eq("joined")
  end

  it "rechecks Guardian visibility for followed topics" do
    private_community = create_community(name: "Private Follow", slug: "private-follow", visibility: "private")
    private_topic = Fabricate(:topic, category: private_community.category, user: followed_user)
    enable_follow_integration_with(private_topic)

    guardian = Guardian.new(member)
    expect(guardian.can_see_topic?(private_topic)).to eq(false)

    result = described_class.call(guardian:, limit: 10)

    expect(result[:topics]).to eq([])
    expect(result[:login_required]).to eq(false)
    expect(result[:personalized]).to eq(true)
  end
end
