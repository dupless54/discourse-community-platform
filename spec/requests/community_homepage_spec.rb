# frozen_string_literal: true

RSpec.describe "Community platform homepage" do
  before do
    @original_homepage = SiteSetting.default_homepage
    @original_login_hint = SiteSetting.has_login_hint

    SiteSetting.has_login_hint = false
    SiteSetting.default_homepage = "community-home"
    Site.clear_cache
    Rails.application.reload_routes!
  end

  after do
    SiteSetting.default_homepage = @original_homepage
    SiteSetting.has_login_hint = @original_login_hint
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
    expect(HomepageSiteSetting.choices).to include("community-home")
    expect(SiteSetting.default_homepage).to eq("community-home")
    expect(SiteSetting.homepage).to eq("community-home")
    expect(SiteSetting.anonymous_homepage).to eq("community-home")
  end

  it "serves the selected Community homepage shell at the root for anonymous visitors" do
    get "/"

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("text/html")
    expect(response.body).to include(
      '<meta name="discourse_current_homepage" content="community-home">',
    )
  end

  it "serves direct community feed routes through the Discourse Ember shell" do
    %w[/home /following /explore /popular].each do |path|
      get path

      expect(response.status).to eq(200), "expected #{path} to serve the Ember shell"
      expect(response.media_type).to eq("text/html")
    end
  end

  it "does not replace explicit Discourse discovery routes" do
    get "/latest"

    expect(response.status).to eq(200)
    expect(response.media_type).to eq("text/html")
  end
end
