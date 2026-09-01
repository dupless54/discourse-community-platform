# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::PopularTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)

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

  it "serializes visible branding in Popular community context" do
    community = create_community(name: "Technology", slug: "technology")
    logo = Fabricate(:upload, user: owner)
    community.update!(icon_upload: logo, icon_emoji: "💻")
    topic = Fabricate(:topic, category: community.category, user: owner)

    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache
    result =
      DiscourseCommunityPlatform::Feeds::PopularTopics.call(guardian: Guardian.new(nil), limit: 10)
    item = result.find { |candidate| candidate[:id] == topic.id }

    expect(item.dig(:community, :slug)).to eq("technology")
    expect(item.dig(:community, :icon_emoji)).to eq("💻")
    expect(item.dig(:community, :icon_url)).to eq(logo.url)
  end

  it "does not serialize a branding upload the current Guardian cannot see" do
    community = create_community(name: "Security", slug: "security")
    logo = Fabricate(:secure_upload, user: owner)
    community.update!(icon_upload: logo, icon_emoji: "🔒")
    topic = Fabricate(:topic, category: community.category, user: owner)

    guardian = Guardian.new(nil)
    expect(guardian.can_see_topic?(topic)).to eq(true)
    expect(guardian.can_see_upload?(logo)).to eq(false)

    DiscourseCommunityPlatform::Feeds::PopularTopics.rebuild_cache
    result = DiscourseCommunityPlatform::Feeds::PopularTopics.call(guardian:, limit: 10)
    item = result.find { |candidate| candidate[:id] == topic.id }

    expect(item.dig(:community, :icon_emoji)).to eq("🔒")
    expect(item.dig(:community, :icon_url)).to be_nil
  end

  it "serializes visible branding for joined communities and their Home topics" do
    community = create_community(name: "Hardware", slug: "hardware")
    logo = Fabricate(:upload, user: owner)
    community.update!(icon_upload: logo, icon_emoji: "🖥️")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community:)
    topic = Fabricate(:topic, category: community.category, user: owner)

    result =
      DiscourseCommunityPlatform::Feeds::HomeTopics.call(guardian: Guardian.new(member), limit: 10)

    joined = result[:joined_communities].find { |candidate| candidate[:id] == community.id }
    item = result[:topics].find { |candidate| candidate[:id] == topic.id }

    expect(joined[:icon_emoji]).to eq("🖥️")
    expect(joined[:icon_url]).to eq(logo.url)
    expect(item.dig(:community, :icon_emoji)).to eq("🖥️")
    expect(item.dig(:community, :icon_url)).to eq(logo.url)
  end
end
