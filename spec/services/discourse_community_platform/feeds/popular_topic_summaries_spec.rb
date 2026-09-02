# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::PopularTopicSummaries do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:viewer, :user)

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

  it "hydrates bounded Guardian-visible summaries from the existing Popular cache" do
    community = create_community(name: "Technology", slug: "technology")
    topic = Fabricate(:topic, category: community.category, user: owner)
    DiscourseCommunityPlatform::Votes::Cast.call(user: viewer, topic:, value: 1)

    Discourse.cache.write(
      DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY,
      [topic.id],
      expires_in: DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_TTL,
    )
    allow(DiscourseCommunityPlatform::Feeds::PopularTopics).to receive(:rebuild_cache)

    result = described_class.call(guardian: Guardian.new(viewer), limit: 1)
    summary = result.first

    expect(DiscourseCommunityPlatform::Feeds::PopularTopics).not_to have_received(:rebuild_cache)
    expect(summary[:id]).to eq(topic.id)
    expect(summary[:title]).to eq(topic.title)
    expect(summary[:path]).to eq(topic.relative_url)
    expect(summary[:score]).to eq(1)
    expect(summary.dig(:community, :slug)).to eq("technology")
    expect(summary.dig(:community, :path)).to eq("/s/technology")
    expect(summary).not_to have_key(:excerpt)
    expect(summary).not_to have_key(:image_url)
    expect(summary).not_to have_key(:author)
    expect(summary).not_to have_key(:user_vote)
  end

  it "filters cached topic ids through Guardian before exposing summaries" do
    visible_community = create_community(name: "Visible", slug: "visible")
    hidden_community = create_community(name: "Hidden", slug: "hidden")
    visible_topic = Fabricate(:topic, category: visible_community.category, user: owner)
    hidden_topic = Fabricate(:topic, category: hidden_community.category, user: owner)

    hidden_community.category.set_permissions(hidden_community.member_group => :full)
    hidden_community.category.save!

    Discourse.cache.write(
      DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY,
      [hidden_topic.id, visible_topic.id],
      expires_in: DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_TTL,
    )

    result = described_class.call(guardian: Guardian.new(viewer))

    expect(result.map { |item| item[:id] }).to eq([visible_topic.id])
  end
end
