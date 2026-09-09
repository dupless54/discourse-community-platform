# frozen_string_literal: true

RSpec.describe "Community Platform enablement" do
  fab!(:owner, :admin)
  fab!(:viewer, :user)
  fab!(:community) do
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "Enablement Community",
        slug: "enablement-community",
        description: "Community data must survive a plugin enablement toggle",
        visibility: "public",
      },
    )
  end
  fab!(:topic) { Fabricate(:topic, category: community.category, user: owner) }

  around do |example|
    original_enabled = SiteSetting.community_platform_enabled
    original_homepage = SiteSetting.default_homepage

    begin
      SiteSetting.community_platform_enabled = true
      SiteSetting.default_homepage = "community-home"
      Site.clear_cache
      example.run
    ensure
      SiteSetting.community_platform_enabled = original_enabled
      SiteSetting.default_homepage = original_homepage
      Site.clear_cache
    end
  end

  before do
    DiscourseCommunityPlatform::Memberships::Join.call(user: viewer, community:)
    DiscourseCommunityPlatform::Votes::Cast.call(user: viewer, topic:, value: 1)
    sign_in(viewer)
  end

  it "removes plugin surfaces while disabled and restores them without deleting Community data" do
    expect(
      DiscoursePluginRegistry.homepage_options.any? { |option| option[:id] == "community-home" },
    ).to eq(true)
    expect(HomepageSiteSetting.choices).to include("community-home")
    expect(SiteSetting.homepage).to eq("community-home")

    get "/home"
    expect(response.status).to eq(200)

    get "/community-platform/feeds/home.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body["topics"].map { |item| item["id"] }).to include(topic.id)

    community_id = community.id
    category_id = community.category_id
    member_group_id = community.member_group_id

    SiteSetting.community_platform_enabled = false
    Site.clear_cache

    expect(
      DiscoursePluginRegistry.homepage_options.any? { |option| option[:id] == "community-home" },
    ).to eq(false)
    expect(HomepageSiteSetting.choices).not_to include("community-home")
    expect(SiteSetting.homepage).not_to eq("community-home")

    get "/home"
    expect(response.status).to eq(404)

    get "/community-platform/feeds/home.json"
    expect(response.status).to eq(404)

    get "/"
    expect(response.status).to eq(200)
    expect(response.body).not_to include(
      '<meta name="discourse_current_homepage" content="community-home">',
    )

    SiteSetting.community_platform_enabled = true
    Site.clear_cache

    expect(
      DiscoursePluginRegistry.homepage_options.any? { |option| option[:id] == "community-home" },
    ).to eq(true)
    expect(HomepageSiteSetting.choices).to include("community-home")
    expect(SiteSetting.homepage).to eq("community-home")

    get "/home"
    expect(response.status).to eq(200)

    get "/community-platform/feeds/home.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body["topics"].map { |item| item["id"] }).to include(topic.id)

    persisted_community = DiscourseCommunityPlatform::Community.find(community_id)
    expect(persisted_community.category_id).to eq(category_id)
    expect(persisted_community.member_group_id).to eq(member_group_id)
    expect(persisted_community.member_group.users.exists?(viewer.id)).to eq(true)
    expect(DiscourseCommunityPlatform::Vote.find_by(user: viewer, topic:)&.value).to eq(1)
    expect(DiscourseCommunityPlatform::TopicScore.find_by(topic:)&.score).to eq(1)
  end
end
