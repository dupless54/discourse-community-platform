# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::ExploreTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 6
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_KEY)
  end

  after do
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_KEY)
  end

  def create_community(name:, slug:)
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: "public" },
    )
  end

  def cache_candidates(*topics)
    Discourse.cache.write(
      DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY,
      topics.map(&:id),
      expires_in: DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_TTL,
    )
  end

  it "prioritizes discovery by excluding joined communities and limiting one community's dominance" do
    joined = create_community(name: "Hardware", slug: "hardware")
    technology = create_community(name: "Technology", slug: "technology")
    gaming = create_community(name: "Gaming", slug: "gaming")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community: joined)

    joined_topic = Fabricate(:topic, category: joined.category, user: owner)
    technology_topics = Array.new(3) { Fabricate(:topic, category: technology.category, user: owner) }
    gaming_topic = Fabricate(:topic, category: gaming.category, user: owner)
    cache_candidates(joined_topic, *technology_topics, gaming_topic)

    result = described_class.call(guardian: Guardian.new(member), limit: 10)
    topic_ids = result.map { |topic| topic[:id] }

    expect(topic_ids).not_to include(joined_topic.id)
    expect(topic_ids).to include(technology_topics[0].id, technology_topics[1].id, gaming_topic.id)
    expect(topic_ids).not_to include(technology_topics[2].id)
    expect(result.count { |topic| topic.dig(:community, :slug) == "technology" }).to eq(2)
  end

  it "preserves rich preview, native community identity, and author context for discovery cards" do
    technology = create_community(name: "Technology", slug: "technology")
    topic = Fabricate(:topic, category: technology.category, user: owner, created_at: 2.hours.ago)
    Fabricate(:post, topic:, user: owner, raw: "A bounded Explore preview from the first visible post.")
    cache_candidates(topic)

    result = described_class.call(guardian: Guardian.new(member), limit: 10)
    item = result.first

    expect(item[:id]).to eq(topic.id)
    expect(item[:created_at]).to be_within(0.000001).of(topic.created_at)
    expect(item[:excerpt]).to include("bounded Explore preview")
    expect(item.dig(:community, :slug)).to eq("technology")
    expect(item.dig(:community, :path)).to eq(technology.category.url)
    expect(item.dig(:author, :username)).to eq(owner.username)
    expect(item.dig(:author, :avatar_template)).to eq(owner.avatar_template)
    expect(item.dig(:author, :path)).to eq("/u/#{owner.username}")
  end

  it "uses cached community signals to promote discovery without rebuilding them on request" do
    technology = create_community(name: "Technology", slug: "technology")
    science = create_community(name: "Science", slug: "science")
    technology_topic = Fabricate(:topic, category: technology.category, user: owner)
    science_topic = Fabricate(:topic, category: science.category, user: owner)
    cache_candidates(technology_topic, science_topic)
    Discourse.cache.write(
      DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_KEY,
      [[science.id, 3, 50.0], [technology.id, 2, 20.0]],
      expires_in: DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_TTL,
    )
    allow(DiscourseCommunityPlatform::Feeds::ExploreCommunities).to receive(:rebuild_cache)

    result = described_class.call(guardian: Guardian.new(member))

    expect(result.map { |topic| topic[:id] }).to eq([science_topic.id, technology_topic.id])
    expect(DiscourseCommunityPlatform::Feeds::ExploreCommunities).not_to have_received(:rebuild_cache)
  end

  it "filters cached public candidates through Guardian before serialization" do
    visible = create_community(name: "Technology", slug: "technology")
    hidden = create_community(name: "Security", slug: "security")
    visible_topic = Fabricate(:topic, category: visible.category, user: owner)
    hidden_topic = Fabricate(:topic, category: hidden.category, user: owner)

    hidden.category.set_permissions(hidden.member_group => :full)
    hidden.category.save!
    cache_candidates(hidden_topic, visible_topic)

    result = described_class.call(guardian: Guardian.new(member))

    expect(result.map { |topic| topic[:id] }).to eq([visible_topic.id])
  end
end
