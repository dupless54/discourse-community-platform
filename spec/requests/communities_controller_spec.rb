# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::CommunitiesController do
  fab!(:owner, :user)
  fab!(:category)
  fab!(:community) do
    DiscourseCommunityPlatform::Community.create!(
      name: "Technology",
      slug: "technology",
      description: "Technology discussions",
      category: category,
      owner: owner,
      visibility: "public",
    )
  end

  describe "GET /community-platform/communities/:slug.json" do
    it "returns a visible community using the canonical community contract" do
      get "/community-platform/communities/#{community.slug}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("community", "id")).to eq(community.id)
      expect(response.parsed_body.dig("community", "slug")).to eq("technology")
      expect(response.parsed_body.dig("community", "path")).to eq("/r/technology")
      expect(response.parsed_body.dig("community", "category_id")).to eq(category.id)
    end

    it "returns not found for an unknown community" do
      get "/community-platform/communities/does-not-exist.json"

      expect(response.status).to eq(404)
    end
  end
end
