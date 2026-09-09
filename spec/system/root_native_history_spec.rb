# frozen_string_literal: true

describe "Root and native Community browser history" do
  fab!(:owner, :admin)
  fab!(:viewer, :user)
  fab!(:community) do
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "History Community",
        slug: "history-community",
        description: "A public Community used to verify root/native browser history",
        visibility: "public",
      },
    )
  end
  fab!(:topic) { Fabricate(:topic, category: community.category, user: owner) }
  fab!(:post) do
    Fabricate(
      :post,
      topic:,
      user: owner,
      raw: "Root to native Category and Topic history",
    )
  end

  let(:topic_list) { PageObjects::Components::TopicList.new }

  before do
    @original_homepage = SiteSetting.default_homepage
    SiteSetting.default_homepage = "community-home"
    Site.clear_cache
    Rails.application.reload_routes!

    DiscourseCommunityPlatform::Memberships::Join.call(user: viewer, community:)
    viewer.user_option.update!(homepage_id: nil)
    sign_in(viewer)
  end

  after do
    SiteSetting.default_homepage = @original_homepage
    Site.clear_cache
    Rails.application.reload_routes!
  end

  it "restores root Home, native Category, and native Topic across back and forward" do
    visit("/")

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css('.dcp-platform-shell[data-platform-section="home"]')
    expect(page).to have_css(".dcp-home-card__title", text: topic.title)

    find(".dcp-topic-context__community", match: :first).click

    expect(page).to have_current_path(community.category.url, ignore_query: true)
    expect(page).to have_css(".dcp-native-community")
    expect(topic_list).to have_topic(topic)

    topic_list.visit_topic(topic)

    expect(page).to have_current_path(topic.url, ignore_query: true)
    expect(page).to have_css("[data-test-topic-community-context]")
    expect(page).to have_css("#topic .cooked", text: post.raw)

    page.go_back

    expect(page).to have_current_path(community.category.url, ignore_query: true)
    expect(page).to have_css(".dcp-native-community")
    expect(page).to have_no_css("[data-test-topic-community-context]")

    page.go_back

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css('.dcp-platform-shell[data-platform-section="home"]')
    expect(page).to have_css(".dcp-home-card__title", text: topic.title)

    page.go_forward

    expect(page).to have_current_path(community.category.url, ignore_query: true)
    expect(page).to have_css(".dcp-native-community")

    page.go_forward

    expect(page).to have_current_path(topic.url, ignore_query: true)
    expect(page).to have_css("[data-test-topic-community-context]")
    expect(page).to have_css("#topic .cooked", text: post.raw)
  end
end
