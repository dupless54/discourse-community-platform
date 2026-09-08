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

  def focus_element(selector)
    page.execute_script("document.querySelector(#{selector.to_json}).focus()")
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

  it "keeps branding upload controls keyboard operable with visible context on mobile" do
    sign_in(owner)
    image_file = file_from_fixtures("logo.png", "images")

    resize_window(width: 500, height: 900) do
      visit(community.category.url)

      logo_selector = "#dcp-native-community-logo-uploader"
      banner_selector = "#dcp-native-community-banner-uploader"

      expect(page).to have_css(
        ".dcp-branding-field strong",
        text: I18n.t("js.community_platform.management.logo"),
      )
      expect(page).to have_css(
        ".dcp-branding-field small",
        text: I18n.t("js.community_platform.management.logo_hint"),
      )
      expect(page).to have_css(
        ".dcp-branding-field strong",
        text: I18n.t("js.community_platform.management.banner_image"),
      )
      expect(page).to have_css(
        ".dcp-branding-field small",
        text: I18n.t("js.community_platform.management.banner_image_hint"),
      )

      expect(page).to have_css(
        "#{logo_selector} label.btn[tabindex='0']",
        text: I18n.t("js.upload_selector.select_file"),
      )
      expect(page).to have_css(
        "#{banner_selector} label.btn[tabindex='0']",
        text: I18n.t("js.upload_selector.select_file"),
      )

      logo_uploader =
        PageObjects::Components::UppyImageUploader.new(find(logo_selector))
      banner_uploader =
        PageObjects::Components::UppyImageUploader.new(find(banner_selector))

      logo_uploader.select_image_with_keyboard(image_file.path)
      expect(logo_uploader).to have_uploaded_image
      expect(page).to have_css(
        "#{logo_selector} label.btn[tabindex='0']",
        text: I18n.t("js.upload_selector.change"),
      )
      expect(page).to have_css(
        "#{logo_selector} .btn-danger",
        text: I18n.t("js.upload_selector.delete"),
      )

      banner_uploader.select_image_with_keyboard(image_file.path)
      expect(banner_uploader).to have_uploaded_image
      expect(page).to have_css(
        "#{banner_selector} label.btn[tabindex='0']",
        text: I18n.t("js.upload_selector.change"),
      )
      expect(page).to have_css(
        "#{banner_selector} .btn-danger",
        text: I18n.t("js.upload_selector.delete"),
      )

      logo_uploader.remove_image_with_keyboard
      expect(page).to have_no_css("#{logo_selector} .btn-danger")
      expect(page).to have_css(
        "#{logo_selector} label.btn[tabindex='0']",
        text: I18n.t("js.upload_selector.select_file"),
      )

      expect_surface_within_viewport(logo_selector)
      expect_surface_within_viewport(banner_selector)
    end
  end

  it "keeps the native management form keyboard operable on mobile" do
    sign_in(owner)

    resize_window(width: 500, height: 900) do
      visit(community.category.url)

      focus_element("[data-test-native-community-description]")
      page.active_element.send_keys([:control, "a"], "Keyboard managed description")

      focus_element("[data-test-native-community-visibility]")
      page.active_element.send_keys(:down)
      expect(find("[data-test-native-community-visibility]").value).to eq("restricted")

      focus_element("[data-test-native-community-rules]")
      page.active_element.send_keys([:control, "a"], "Keyboard rule one\nKeyboard rule two")
      page.active_element.send_keys(:tab)

      expect(page.active_element).to eq(find("[data-test-native-community-save]"))
      page.active_element.send_keys(:enter)

      expect(page).to have_css(
        "[data-test-native-community-management] [role='status']",
        text: I18n.t("js.community_platform.management.saved"),
      )

      community.reload
      expect(community.description).to eq("Keyboard managed description")
      expect(community.visibility).to eq("restricted")
      expect(community.rules).to eq(["Keyboard rule one", "Keyboard rule two"])
    end
  end
end
