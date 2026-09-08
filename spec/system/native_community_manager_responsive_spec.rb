# frozen_string_literal: true

describe "Native Community manager responsive surfaces" do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }

  let(:community) do
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "Mobile Community Management",
        slug: "mobile-community-management",
        description:
          "A deliberately detailed Community description for responsive owner-management coverage.",
        visibility: "public",
      },
    )
  end
  let(:topic) { Fabricate(:topic, category: community.category, user: owner) }
  let(:post) { Fabricate(:post, topic:, user: owner, raw: "Native manager responsive topic") }

  let(:topic_list) { PageObjects::Components::TopicList.new }

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 8

    community.update!(rules: ["Keep management changes scoped to this Community"])
    topic
    post
  end

  def expect_surface_within_viewport(selector)
    expect(
      page.evaluate_script(<<~JS),
        (() => {
          const element = document.querySelector(#{selector.to_json});
          if (!element) {
            return false;
          }

          const rect = element.getBoundingClientRect();
          return (
            rect.left >= -1 &&
            rect.right <= window.innerWidth + 1 &&
            element.scrollWidth <= element.clientWidth + 1
          );
        })()
      JS
    ).to eq(true)
  end

  it "keeps scoped owner management usable without horizontal overflow on mobile" do
    expect(owner.admin?).to eq(false)
    expect(owner.moderator?).to eq(false)

    sign_in(owner)

    resize_window(width: 500, height: 900) do
      visit(community.category.url)

      expect(page).to have_css(".dcp-native-community")
      expect(page).to have_css("[data-test-native-community-management]")
      expect(page).to have_css("[data-test-native-community-manager-tools]")
      expect(page).to have_css("[data-test-native-community-description]")
      expect(page).to have_css("[data-test-native-community-save]")
      expect(topic_list).to have_topic(topic)

      expect_surface_within_viewport(".dcp-native-community")
      expect_surface_within_viewport("[data-test-native-community-management]")
      expect_surface_within_viewport(".dcp-management-branding-grid")
      expect_surface_within_viewport("[data-test-native-community-manager-tools]")

      expect(
        page.evaluate_script(<<~JS),
          (() => {
            const grid = document.querySelector(".dcp-management-branding-grid");
            return getComputedStyle(grid).gridTemplateColumns.split(" ").length;
          })()
        JS
      ).to eq(1)
    end
  end
end
