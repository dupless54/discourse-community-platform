# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::ExploreCommunities do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 6
    Discourse.cache.delete(described_class::CACHE_KEY)
  end

  after { Discourse.cache.delete(described_class::CACHE_KEY) }

  def create_community(name:, slug:, visibility: "public")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: },
    )
  end

  it "builds recommendation signals only from active public communities" do
    public_community = create_community(name: "Technology", slug: "technology")
    private_community = create_community(name: "Private", slug: "private", visibility: "private")
    public_topic = Fabricate(:topic, category: public_community.category, user: owner)
    Fabricate(:topic, category: private_community.category, user: owner)
    DiscourseCommunityPlatform::Votes::Cast.call(user: member, topic: public_topic, value: 1)

    signals = described_class.rebuild_cache
    community_ids = signals.map(&:first)

    expect(community_ids).to include(public_community.id)
    expect(community_ids).not_to include(private_community.id)
    expect(signals.assoc(public_community.id).second).to eq(1)
  end

  it "filters cached recommendations through membership and Guardian without rebuilding on request" do
    joined = create_community(name: "Hardware", slug: "hardware")
    visible = create_community(name: "Science", slug: "science")
    hidden = create_community(name: "Security", slug: "security")
    DiscourseCommunityPlatform::Memberships::Join.call(user: member, community: joined)

    hidden.category.set_permissions(hidden.member_group => :full)
    hidden.category.save!

    Discourse.cache.write(
      described_class::CACHE_KEY,
      [[joined.id, 4, 40.0], [hidden.id, 3, 30.0], [visible.id, 2, 20.0]],
      expires_in: described_class::CACHE_TTL,
    )
    allow(described_class).to receive(:rebuild_cache)

    result = described_class.call(guardian: Guardian.new(member))

    expect(result.map { |community| community[:id] }).to eq([visible.id])
    expect(result.first[:recent_topics_count]).to eq(2)
    expect(result.first[:path]).to eq("/s/science")
    expect(result.first[:can_join]).to eq(true)
    expect(described_class).not_to have_received(:rebuild_cache)
  end

  it "does not offer quick join to guests" do
    visible = create_community(name: "Science", slug: "science")
    Discourse.cache.write(
      described_class::CACHE_KEY,
      [[visible.id, 2, 20.0]],
      expires_in: described_class::CACHE_TTL,
    )

    result = described_class.call(guardian: Guardian.new(nil))

    expect(result.first[:can_join]).to eq(false)
  end

  it "does not offer quick join to suspended users" do
    visible = create_community(name: "Science", slug: "science")
    member.stubs(:suspended?).returns(true)
    Discourse.cache.write(
      described_class::CACHE_KEY,
      [[visible.id, 2, 20.0]],
      expires_in: described_class::CACHE_TTL,
    )

    result = described_class.call(guardian: Guardian.new(member))

    expect(result.first[:can_join]).to eq(false)
  end
end
