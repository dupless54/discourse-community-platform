# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::ExplorePeople do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:contributor, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
  end

  after do
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)

    if @created_user_follower_stub && Object.const_defined?(:UserFollower, false)
      Object.send(:remove_const, :UserFollower)
    end
  end

  def create_community(name:, slug:, visibility: "public")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: },
    )
  end

  def enable_follow_integration
    unless Object.const_defined?(:UserFollower, false)
      Object.const_set(
        :UserFollower,
        Class.new do
          def self.filter_opted_out_users(relation)
            relation
          end
        end,
      )
      @created_user_follower_stub = true
    end

    SiteSetting.stubs(:discourse_follow_enabled).returns(true)
  end

  it "returns no recommendations when Discourse Follow is unavailable" do
    result = described_class.call(guardian: Guardian.new(nil), limit: 6)

    expect(result).to eq([])
  end

  it "discovers visible contributors from the cached Popular candidate pool" do
    enable_follow_integration
    community = create_community(name: "Science", slug: "science")
    topic = Fabricate(:topic, category: community.category, user: contributor)
    Discourse.cache.write(
      DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY,
      [topic.id],
      expires_in: DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_TTL,
    )

    result = described_class.call(guardian: Guardian.new(nil), limit: 6)

    expect(result.map { |person| person[:id] }).to eq([contributor.id])
    expect(result.first[:username]).to eq(contributor.username)
    expect(result.first[:path]).to eq("/u/#{contributor.username}")
    expect(result.first[:recent_public_topics_count]).to eq(1)
  end

  it "does not rebuild Popular when the candidate cache is cold" do
    enable_follow_integration
    allow(DiscourseCommunityPlatform::Feeds::PopularTopics).to receive(:rebuild_cache)

    result = described_class.call(guardian: Guardian.new(nil), limit: 6)

    expect(result).to eq([])
    expect(DiscourseCommunityPlatform::Feeds::PopularTopics).not_to have_received(:rebuild_cache)
  end
end
