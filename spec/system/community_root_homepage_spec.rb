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
    visit("/")

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css(".dcp-platform-shell[data-platform-section=\"home\"]")
    expect(page).to have_css("[data-platform-feed=\"home\"][aria-current=\"page\"]")
    expect(page).to have_css("[data-platform-feed=\"home\"][href=\"/\"]", minimum: 1)
    expect(page).to have_no_css("[data-platform-feed=\"home\"][href=\"/home\"]")
  end

  it "keeps a member without a personal homepage override on Community Home" do
    viewer = Fabricate(:user)
    viewer.user_option.update!(homepage_id: nil)
    sign_in(viewer)

    visit("/")

    expect(page).to have_current_path("/", ignore_query: true)
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
end
