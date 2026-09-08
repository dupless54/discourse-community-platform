# frozen_string_literal: true

describe "Platform feed browser history" do
  fab!(:viewer, :user)

  def expect_platform_section(section, path)
    expect(page).to have_current_path(path, ignore_query: true)
    expect(page).to have_css(
      ".dcp-platform-shell[data-platform-section=\"#{section}\"]",
    )
    expect(page).to have_css(
      "[data-platform-feed=\"#{section}\"][aria-current=\"page\"]",
    )
  end

  it "restores Home, Explore, Popular, and Following across back and forward" do
    sign_in(viewer)

    visit("/home")
    expect_platform_section("home", "/home")

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
    expect_platform_section("home", "/home")

    page.go_forward
    expect_platform_section("explore", "/explore")

    page.go_forward
    expect_platform_section("popular", "/popular")

    page.go_forward
    expect_platform_section("following", "/following")
  end
end
