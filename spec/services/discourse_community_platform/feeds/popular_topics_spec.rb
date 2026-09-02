# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::PopularTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:voter, :user)
  fab!(:second_voter, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 5
    Discourse.cache.delete(described_class::CACHE_KEY)
  end

  after { Discourse.cache.delete(described_class::CACHE_KEY) }

  def create_community(name:, slug:, visibility: "public")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: },
    )
  end

  it "ranks recent topics across public communities and returns social topic context" do
    technology = create_community(name: "Technology", slug: "technology")
    gaming = create_community(name: "Gaming", slug: "gaming")
    technology_topic = Fabricate(:topic, category: technology.category, user: owner, created_at: 2.days.ago)
    gaming_topic = Fabricate(:topic, category: gaming.category, user: owner, created_at: 1.day.ago)

    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: technology_topic, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: second_voter, topic: technology_topic, value: 1)
    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic: gaming_topic, value: 1)

    described_class.rebuild_cache
    result = described_class.call(guardian: Guardian.new(voter))

    expect(result.map { |topic| topic[:id] }).to include(technology_topic.id, gaming_topic.id)
    expect(result.first[:id]).to eq(technology_topic.id)
    expect(result.first.dig(:community, :slug)).to eq("technology")
    expect(result.first.dig(:community, :path)).to eq("/s/technology")
    expect(result.first.dig(:author, :username)).to eq(owner.username)
    expect(result.first.dig(:author, :avatar_template)).to eq(owner.avatar_template)
    expect(result.first.dig(:author, :path)).to eq("/u/#{owner.username}")
    expect(result.first[:created_at]).to be_within(0.000001).of(technology_topic.created_at)
  end

  it "keeps restricted and private communities out of the shared popular cache" do
    public_community = create_community(name: "Public", slug: "public")
    restricted_community = create_community(name: "Restricted", slug: "restricted", visibility: "restricted")
    private_community = create_community(name: "Private", slug: "private", visibility: "private")

    public_topic = Fabricate(:topic, category: public_community.category, user: owner)
    restricted_topic = Fabricate(:topic, category: restricted_community.category, user: owner)
    private_topic = Fabricate(:topic, category: private_community.category, user: owner)

    [restricted_topic, private_topic].each do |topic|
      DiscourseCommunityPlatform::Votes::Cast.call(user: owner, topic:, value: 1)
    end

    topic_ids = described_class.rebuild_cache

    expect(topic_ids).to include(public_topic.id)
    expect(topic_ids).not_to include(restricted_topic.id, private_topic.id)
  end

  it "filters cached candidates through Guardian before serializing them" do
    visible_community = create_community(name: "Technology", slug: "technology")
    hidden_community = create_community(name: "Security", slug: "security")
    visible_topic = Fabricate(:topic, category: visible_community.category, user: owner)
    hidden_topic = Fabricate(:topic, category: hidden_community.category, user: owner)

    hidden_community.category.set_permissions(hidden_community.member_group => :full)
    hidden_community.category.save!

    guardian = Guardian.new(voter)
    expect(guardian.can_see_topic?(hidden_topic)).to eq(false)

    Discourse.cache.write(
      described_class::CACHE_KEY,
      [hidden_topic.id, visible_topic.id],
      expires_in: described_class::CACHE_TTL,
    )

    result = described_class.call(guardian:)

    expect(result.map { |topic| topic[:id] }).to eq([visible_topic.id])
  end
end
