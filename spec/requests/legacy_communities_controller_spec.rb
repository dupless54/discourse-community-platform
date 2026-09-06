# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::LegacyCommunitiesController do
  fab!(:owner, :user)
  fab!(:member, :user)
  fab!(:private_group, :group)
  fab!(:category, :category_with_definition) do
    category = Fabricate(:category_with_definition)
    category.set_permissions(everyone: :full)
    category.save!
    category
  end
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

  describe "GET /s/:slug" do
    it "permanently redirects a visible Community to its native Category URL" do
      get "/s/#{community.slug}"

      expect(response.status).to eq(301)
      expect(response.location).to end_with(category.url)
    end

    it "does not reveal a Community when the current Guardian cannot see its Category" do
      category.set_permissions(private_group => :full)
      category.save!

      get "/s/#{community.slug}"

      expect(response.status).to eq(404)
    end

    it "redirects an authorized user for a private Category" do
      category.set_permissions(private_group => :full)
      category.save!
      private_group.add(member)
      sign_in(member)

      get "/s/#{community.slug}"

      expect(response.status).to eq(301)
      expect(response.location).to end_with(category.url)
    end

    it "returns not found for an unknown legacy Community slug" do
      get "/s/does-not-exist"

      expect(response.status).to eq(404)
    end
  end
end
