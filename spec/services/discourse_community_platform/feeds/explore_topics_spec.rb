# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::ExploreTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 6
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
  end

  after { Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY) }

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
