# frozen_string_literal: true

describe "Community platform root homepage" do
  around do |example|
    original_homepage = SiteSetting.default_homepage
    SiteSetting.default_homepage = "community-home"
    Site.clear_cache
    Rails.application.reload_routes!

    example.run
  ensure
    SiteSetting.default_homepage = original_homepage
    Site.clear_cache
    Rails.application.reload_routes!
  end

  it "renders the selected Community Home at root for anonymous visitors" do
    expect_registered_homepage
    expect(SiteSetting.default_homepage).to eq("community-home")
    expect(SiteSetting.homepage).to eq("community-home")
    expect(SiteSetting.anonymous_homepage).to eq("community-home")

    visit("/")

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css(
      "meta[name=\"discourse_current_homepage\"][content=\"community-home\"]",
      visible: false,
    )
    expect(page).to have_css(".dcp-platform-shell[data-platform-section=\"home\"]")
    expect(page).to have_css("[data-platform-feed=\"home\"][aria-current=\"page\"]")
    expect(page).to have_css("[data-platform-feed=\"home\"][href=\"/\"]", minimum: 1)
    expect(page).to have_no_css("[data-platform-feed=\"home\"][href=\"/home\"]")
  end

  it "keeps a member without a personal homepage override on Community Home" do
    expect_registered_homepage
    expect(SiteSetting.default_homepage).to eq("community-home")
    expect(SiteSetting.homepage).to eq("community-home")

    viewer = Fabricate(:user)
    viewer.user_option.update!(homepage_id: nil)
    expect(viewer.reload.user_option.homepage).to be_nil
    sign_in(viewer)

    visit("/")

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css(
      "meta[name=\"discourse_current_homepage\"][content=\"community-home\"]",
      visible: false,
    )
    expect(page).to have_css(".dcp-platform-shell[data-platform-section=\"home\"]")
    expect(page).to have_css("[data-platform-feed=\"home\"][aria-current=\"page\"]")

    first("[data-platform-feed=\"following\"]").click

    expect(page).to have_current_path("/following", ignore_query: true)
    expect(page).to have_css(".dcp-platform-shell[data-platform-section=\"following\"]")

    first("[data-platform-feed=\"home\"]").click

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css(".dcp-platform-shell[data-platform-section=\"home\"]")
    expect(page).to have_css("[data-platform-feed=\"home\"][aria-current=\"page\"]")
  end

  def expect_registered_homepage
    option =
      DiscoursePluginRegistry.homepage_options.find { |homepage| homepage[:id] == "community-home" }

    expect(option).to include(
      path: "/home",
      route: "discourse_community_platform/home#index",
      anonymous: true,
      server_side: false,
    )
    expect(HomepageSiteSetting.choices).to include("community-home")
  end
end
