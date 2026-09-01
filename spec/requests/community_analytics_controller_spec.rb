# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::CommunityAnalyticsController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:outsider, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
    Discourse.cache.delete(DiscourseCommunityPlatform::Analytics::CommunityActivity::CACHE_KEY)
  end

  after do
    Discourse.cache.delete(DiscourseCommunityPlatform::Analytics::CommunityActivity::CACHE_KEY)
  end

  def create_community
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name: "Technology", slug: "technology", visibility: "public" },
    )
  end

  def cache_snapshot(community)
    Discourse.cache.write(
      DiscourseCommunityPlatform::Analytics::CommunityActivity::CACHE_KEY,
      {
        community.id => {
          status: "ready",
          generated_at: Time.zone.parse("2026-09-01 12:00:00"),
          last_7_days: {
            new_topics: 4,
            posts: 18,
            replies: 14,
            active_topics: 6,
            contributors: 9,
          },
          last_30_days: {
            new_topics: 17,
            posts: 73,
            replies: 56,
            active_topics: 22,
            contributors: 31,
          },
        },
      },
      expires_in: 30.minutes,
    )
  end

  it "returns cached aggregate activity only to a community manager" do
    community = create_community
    cache_snapshot(community)
    sign_in(owner)
    expect(DiscourseCommunityPlatform::Analytics::CommunityActivity).not_to receive(:rebuild_cache)

    get "/community-platform/communities/#{community.slug}/activity-analytics.json"

    expect(response.status).to eq(200)
    analytics = response.parsed_body.fetch("community_activity_analytics")
    expect(analytics.fetch("status")).to eq("ready")
    expect(analytics.fetch("last_7_days")).to include(
      "new_topics" => 4,
      "posts" => 18,
      "contributors" => 9,
    )
    expect(analytics.fetch("last_30_days")).to include(
      "new_topics" => 17,
      "posts" => 73,
      "contributors" => 31,
    )
    expect(response.body).not_to include("username", "post_id", "post_url", "raw")
  end

  it "does not expose analytics to unrelated authenticated users" do
    community = create_community
    cache_snapshot(community)
    sign_in(outsider)

    get "/community-platform/communities/#{community.slug}/activity-analytics.json"

    expect(response.status).to eq(403)
  end

  it "requires authentication" do
    community = create_community

    get "/community-platform/communities/#{community.slug}/activity-analytics.json"

    expect(response.status).to eq(403)
  end
end
