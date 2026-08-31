# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::CommunitiesController do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
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
      category: category,
      owner: owner,
      visibility: "public",
    )
  end

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  describe "GET /community-platform/communities/:slug.json" do
    it "returns a visible community using the canonical community contract" do
      get "/community-platform/communities/#{community.slug}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.dig("community", "id")).to eq(community.id)
      expect(response.parsed_body.dig("community", "slug")).to eq("technology")
      expect(response.parsed_body.dig("community", "path")).to eq("/s/technology")
      expect(response.parsed_body.dig("community", "category_id")).to eq(category.id)
      expect(response.parsed_body.dig("community", "is_member")).to eq(false)
      expect(response.parsed_body.dig("community", "can_join")).to eq(false)
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

  describe "POST /community-platform/communities.json" do
    it "creates a community without granting global staff privileges" do
      sign_in(owner)

      post "/community-platform/communities.json",
           params: {
             community: {
               name: "Gaming",
               slug: "gaming",
               description: "Gaming discussions",
               visibility: "restricted",
             },
           }

      expect(response.status).to eq(201)

      created = DiscourseCommunityPlatform::Community.find_by!(slug: "gaming")
      body = response.parsed_body.fetch("community")

      expect(created.owner).to eq(owner)
      expect(created.member_group.reload.user_count).to eq(1)
      expect(created.moderator_group.reload.user_count).to eq(1)
      expect(owner.reload.admin).to eq(false)
      expect(owner.moderator).to eq(false)
      expect(body["path"]).to eq("/s/gaming")
      expect(body["is_member"]).to eq(true)
      expect(body["is_owner"]).to eq(true)
      expect(body["is_moderator"]).to eq(true)
      expect(body["can_join"]).to eq(false)
      expect(body["can_leave"]).to eq(false)
    end

    it "requires an authenticated user" do
      post "/community-platform/communities.json",
           params: { community: { name: "Gaming", slug: "gaming" } }

      expect(response.status).to eq(403)
    end
  end

  describe "community membership" do
    fab!(:member, :user)

    def create_membership_community(visibility: "public", slug: "gaming")
      DiscourseCommunityPlatform::Communities::Create.call(
        user: owner,
        params: {
          name: slug.titleize,
          slug:,
          description: "Community for #{slug}",
          visibility:,
        },
      )
    end

    it "joins a visible community idempotently and keeps counts in sync" do
      membership_community = create_membership_community
      sign_in(member)

      2.times do
        post "/community-platform/communities/#{membership_community.slug}/join.json"
        expect(response.status).to eq(200)
      end

      membership_community.reload
      body = response.parsed_body.fetch("community")

      expect(membership_community.member_group.group_users.exists?(user_id: member.id)).to eq(true)
      expect(membership_community.member_group.reload.user_count).to eq(2)
      expect(membership_community.members_count).to eq(2)
      expect(body["is_member"]).to eq(true)
      expect(body["can_join"]).to eq(false)
      expect(body["can_leave"]).to eq(true)
    end

    it "leaves a community through Discourse GroupManager side effects" do
      membership_community = create_membership_community
      sign_in(member)

      post "/community-platform/communities/#{membership_community.slug}/join.json"
      delete "/community-platform/communities/#{membership_community.slug}/join.json"

      expect(response.status).to eq(200)

      membership_community.reload
      body = response.parsed_body.fetch("community")

      expect(membership_community.member_group.group_users.exists?(user_id: member.id)).to eq(false)
      expect(membership_community.member_group.reload.user_count).to eq(1)
      expect(membership_community.members_count).to eq(1)
      expect(body["is_member"]).to eq(false)
      expect(body["can_join"]).to eq(true)
      expect(body["can_leave"]).to eq(false)
    end

    it "does not allow a community owner or moderator to leave through the member endpoint" do
      membership_community = create_membership_community
      sign_in(owner)

      delete "/community-platform/communities/#{membership_community.slug}/join.json"

      expect(response.status).to eq(403)
      expect(membership_community.member_group.group_users.exists?(user_id: owner.id)).to eq(true)
    end

    it "does not expose a private community through the join endpoint" do
      membership_community = create_membership_community(visibility: "private", slug: "private-gaming")
      sign_in(member)

      post "/community-platform/communities/#{membership_community.slug}/join.json"

      expect(response.status).to eq(404)
      expect(membership_community.member_group.group_users.exists?(user_id: member.id)).to eq(false)
    end

    it "allows a user to join a restricted community while preserving public read access" do
      membership_community = create_membership_community(visibility: "restricted", slug: "restricted-gaming")
      sign_in(member)

      expect(Guardian.new(member).can_see_category?(membership_community.category)).to eq(true)

      post "/community-platform/communities/#{membership_community.slug}/join.json"

      expect(response.status).to eq(200)
      expect(membership_community.member_group.group_users.exists?(user_id: member.id)).to eq(true)
    end
  end
end
