# frozen_string_literal: true

describe "Community platform root homepage" do
  fab!(:viewer, :user)

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

  it "renders Community Home at root and keeps primary Home navigation on root" do
    sign_in(viewer)

    visit("/")

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css('.dcp-platform-shell[data-platform-section="home"]')
    expect(page).to have_css('[data-platform-feed="home"][aria-current="page"]')
    expect(page).to have_css('[data-platform-feed="home"][href="/"]', minimum: 1)
    expect(page).to have_no_css('[data-platform-feed="home"][href="/home"]')

    first('[data-platform-feed="following"]').click

    expect(page).to have_current_path("/following", ignore_query: true)
    expect(page).to have_css('.dcp-platform-shell[data-platform-section="following"]')

    first('[data-platform-feed="home"]').click

    expect(page).to have_current_path("/", ignore_query: true)
    expect(page).to have_css('.dcp-platform-shell[data-platform-section="home"]')
    expect(page).to have_css('[data-platform-feed="home"][aria-current="page"]')
  end
end
