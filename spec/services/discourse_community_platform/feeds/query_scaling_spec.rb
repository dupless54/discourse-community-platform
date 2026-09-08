# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::HomeTopics do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:member, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 8
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
  end

  after do
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::PopularTopics::CACHE_KEY)
  end

  def create_community(index)
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "Performance #{index}",
        slug: "performance-#{index}",
        visibility: "public",
      },
    )
  end

  it "loads first-post preview data with a bounded number of topic and post queries" do
    topics =
      5.times.map do |index|
        topic = Fabricate(:topic, user: owner)
        Fabricate(:post, topic:, user: owner, raw: "Preview body #{index}")
        topic
      end

    queries =
      track_sql_queries do
        previews =
          DiscourseCommunityPlatform::Feeds::TopicPreviews.call(
            topics:,
            guardian: Guardian.new(member),
          )

        expect(previews.keys).to contain_exactly(*topics.map(&:id))
      end

    expect(queries.grep(/FROM "topics"/).length).to be <= 2
    expect(queries.grep(/FROM "posts"/).length).to eq(1)
  end

  it "does not query Categories once per Community identity in Home" do
    communities =
      5.times.map do |index|
        community = create_community(index)
        DiscourseCommunityPlatform::Memberships::Join.call(user: member, community:)
        Fabricate(:topic, category: community.category, user: owner)
        community
      end

    queries =
      track_sql_queries do
        payload =
          described_class.call(
            guardian: Guardian.new(member),
            limit: communities.length,
          )

        expect(payload[:joined_communities].length).to eq(communities.length)
        expect(payload[:topics].length).to eq(communities.length)
      end

    expect(queries.grep(/FROM "categories"/).length).to be <= 1
  end
end
