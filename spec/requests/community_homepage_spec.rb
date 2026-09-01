# frozen_string_literal: true

RSpec.describe "Community platform homepage" do
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

  it "registers the personalized home through the official Discourse homepage API" do
    option =
      DiscoursePluginRegistry.homepage_options.find { |homepage| homepage[:id] == "community-home" }

    expect(option).to include(
      name: "community_platform.homepage.title",
      path: "/home",
      route: "discourse_community_platform/home#index",
      anonymous: true,
      server_side: false,
    )
  end

  it "serves the Discourse Ember shell at the root for anonymous visitors" do
    get "/"

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("text/html")
  end

  it "does not replace explicit Discourse discovery routes" do
    get "/latest"

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("text/html")
  end
end
