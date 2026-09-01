# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Analytics::CommunityActivity do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:author_a, :user)
  fab!(:author_b, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 4
    Discourse.cache.delete(described_class::CACHE_KEY)
  end

  after { Discourse.cache.delete(described_class::CACHE_KEY) }

  def create_community(name:, slug:)
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: "public" },
    )
  end

  def create_topic_with_posts(community:, topic_time:, starter:, replies: [])
    topic = Fabricate(:topic, category: community.category, user: starter)
    topic.update_columns(created_at: topic_time, updated_at: topic_time)

    first_post = Fabricate(:post, topic:, user: starter)
    first_post.update_columns(created_at: topic_time, updated_at: topic_time, post_number: 1)

    replies.each_with_index do |(user, created_at), index|
      post = Fabricate(:post, topic:, user:)
      post.update_columns(
        created_at:,
        updated_at: created_at,
        post_number: index + 2,
      )
    end

    topic
  end

  it "returns a zeroed warming snapshot without rebuilding synchronously" do
    community = create_community(name: "Technology", slug: "technology")
    allow(described_class).to receive(:rebuild_cache)

    result = described_class.call(community:)

    expect(described_class).not_to have_received(:rebuild_cache)
    expect(result).to eq(
      status: "warming",
      generated_at: nil,
      last_7_days: {
        new_topics: 0,
        posts: 0,
        replies: 0,
        active_topics: 0,
        contributors: 0,
      },
      last_30_days: {
        new_topics: 0,
        posts: 0,
        replies: 0,
        active_topics: 0,
        contributors: 0,
      },
    )
  end

  it "rebuilds isolated 7-day and 30-day activity aggregates" do
    now = Time.zone.parse("2026-09-01 12:00:00")
    community = create_community(name: "Technology", slug: "technology")
    other = create_community(name: "Science", slug: "science")

    create_topic_with_posts(
      community:,
      topic_time: now - 2.days,
      starter: author_a,
      replies: [[author_b, now - 1.day]],
    )
    create_topic_with_posts(
      community:,
      topic_time: now - 20.days,
      starter: author_a,
      replies: [[author_a, now - 10.days]],
    )
    create_topic_with_posts(
      community:,
      topic_time: now - 40.days,
      starter: author_b,
      replies: [[author_b, now - 39.days]],
    )
    create_topic_with_posts(
      community: other,
      topic_time: now - 1.day,
      starter: author_b,
      replies: [[author_b, now - 1.hour]],
    )

    described_class.rebuild_cache(now:)
    result = described_class.call(community:)

    expect(result[:status]).to eq("ready")
    expect(result[:generated_at]).to eq(now)
    expect(result[:last_7_days]).to eq(
      new_topics: 1,
      posts: 2,
      replies: 1,
      active_topics: 1,
      contributors: 2,
    )
    expect(result[:last_30_days]).to eq(
      new_topics: 2,
      posts: 4,
      replies: 2,
      active_topics: 2,
      contributors: 2,
    )

    other_result = described_class.call(community: other)
    expect(other_result[:last_7_days]).to include(
      new_topics: 1,
      posts: 2,
      replies: 1,
      active_topics: 1,
      contributors: 1,
    )
  end
end
