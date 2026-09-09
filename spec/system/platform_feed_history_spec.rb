# frozen_string_literal: true

describe "Platform feed browser history" do
  fab!(:viewer, :user)

  before do
    @original_homepage = SiteSetting.default_homepage
    SiteSetting.default_homepage = "community-home"
    Site.clear_cache
    Rails.application.reload_routes!
  end

  after do
    SiteSetting.default_homepage = @original_homepage
    Site.clear_cache
    Rails.application.reload_routes!
  end

  def expect_platform_section(section, path)
    expect(page).to have_current_path(path, ignore_query: true)
    expect(page).to have_css(
      ".dcp-platform-shell[data-platform-section=\"#{section}\"]",
    )
    expect(page).to have_css(
      "[data-platform-feed=\"#{section}\"][aria-current=\"page\"]",
    )
  end

  it "restores root Home, Explore, Popular, and Following across back and forward" do
    viewer.user_option.update!(homepage_id: nil)
    sign_in(viewer)

    visit("/")
    expect_platform_section("home", "/")

    find('[data-platform-feed="explore"]').click
    expect_platform_section("explore", "/explore")

    find('[data-platform-feed="popular"]').click
    expect_platform_section("popular", "/popular")

    find('[data-platform-feed="following"]').click
    expect_platform_section("following", "/following")

    page.go_back
    expect_platform_section("popular", "/popular")

    page.go_back
    expect_platform_section("explore", "/explore")

    page.go_back
    expect_platform_section("home", "/")

    page.go_forward
    expect_platform_section("explore", "/explore")

    page.go_forward
    expect_platform_section("popular", "/popular")

    page.go_forward
    expect_platform_section("following", "/following")
  end
end
