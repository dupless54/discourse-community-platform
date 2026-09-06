# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::CommunitiesController do
  fab!(:owner, :user)
  fab!(:category, :category_with_definition) do
    category = Fabricate(:category_with_definition)
    category.set_permissions(everyone: :full)
    category.save!
    category
  end
  fab!(:private_group, :group)
  fab!(:community) do
    DiscourseCommunityPlatform::Community.create!(
      name: "Technology",
      slug: "technology",
      description: "Technology discussions",
      category:,
      owner:,
      visibility: "public",
      rules: ["Be respectful"],
    )
  end

  describe "GET /community-platform/categories/:category_id/community.json" do
    it "resolves the Community through the native Category id" do
      get "/community-platform/categories/#{category.id}/community.json"

      expect(response.status).to eq(200)
      body = response.parsed_body.fetch("community")

      expect(body["id"]).to eq(community.id)
      expect(body["category_id"]).to eq(category.id)
      expect(body["category_url"]).to eq(category.url)
      expect(body["path"]).to eq(category.url)
      expect(body["rules"]).to eq(["Be respectful"])
    end

    it "keeps the native lookup behind Guardian category visibility" do
      category.set_permissions(private_group => :full)
      category.save!

      get "/community-platform/categories/#{category.id}/community.json"

      expect(response.status).to eq(404)
    end

    it "returns not found for a Category that is not mapped to a Community" do
      ordinary_category = Fabricate(:category)

      get "/community-platform/categories/#{ordinary_category.id}/community.json"

      expect(response.status).to eq(404)
    end
  end
end
