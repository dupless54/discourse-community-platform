# frozen_string_literal: true

RSpec.describe "Legacy Community permalinks" do
  fab!(:owner, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 0
    SiteSetting.community_platform_max_communities_per_user = 10
  end

  def create_community(visibility: "public", slug: "technology")
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name: slug.titleize, slug:, visibility: },
    )
  end

  describe "GET /s/:slug" do
    it "creates a native category permalink and permanently redirects a visible Community" do
      community = create_community

      permalink = Permalink.find_by_url("/s/#{community.slug}")
      expect(permalink&.category_id).to eq(community.category_id)

      get "/s/#{community.slug}"

      expect(response.status).to eq(301)
      expect(response.location).to end_with(community.category.url)
    end

    it "does not reveal a private Community when the current Guardian cannot see its Category" do
      community = create_community(visibility: "private", slug: "private-tech")

      get "/s/#{community.slug}"

      expect(response.status).to eq(404)
    end

    it "redirects an authorized user for a private Community" do
      community = create_community(visibility: "private", slug: "owner-tech")
      sign_in(owner)

      get "/s/#{community.slug}"

      expect(response.status).to eq(301)
      expect(response.location).to end_with(community.category.url)
    end

    it "does not redirect an unknown legacy Community slug" do
      expect(Permalink.find_by_url("/s/does-not-exist")).to be_nil

      get "/s/does-not-exist"

      expect(response.status).to eq(200)
      expect(response.headers["Location"]).to be_blank
    end
  end
end
