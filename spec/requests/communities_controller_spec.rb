# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::CommunitiesController do
  fab!(:owner, :user)
  fab!(:category, :category_with_definition)
  fab!(:private_group, :group)
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
      expect(response.parsed_body.dig("community", "path")).to eq("/s/technology")
      expect(response.parsed_body.dig("community", "category_id")).to eq(category.id)
    end

    it "does not leak community metadata when Discourse category permissions deny access" do
      category.set_permissions(private_group => :full)
      category.save!

      get "/community-platform/communities/#{community.slug}.json"

      expect(response.status).to eq(404)
    end

    it "returns not found for an unknown community" do
      get "/community-platform/communities/does-not-exist.json"

      expect(response.status).to eq(404)
    end
  end
end
