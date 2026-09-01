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
      body = response.parsed_body.fetch("community")

      expect(body["id"]).to eq(community.id)
      expect(body["slug"]).to eq("technology")
      expect(body["path"]).to eq("/s/technology")
      expect(body["category_id"]).to eq(category.id)
      expect(body["category_url"]).to eq(category.url)
      expect(body["rules"]).to eq([])
      expect(body["is_member"]).to eq(false)
      expect(body["can_join"]).to eq(false)
      expect(body["can_manage"]).to eq(false)
      expect(body).not_to have_key("icon_upload_id")
      expect(body).not_to have_key("banner_upload_id")
    end

    it "exposes management capability and branding upload ids only to an authorized manager" do
      logo =
        Fabricate(
          :upload,
          user: owner,
          original_filename: "community-logo.png",
          extension: "png",
        )
      banner =
        Fabricate(
          :upload,
          user: owner,
          original_filename: "community-banner.jpg",
          extension: "jpg",
        )
      community.update!(icon_upload: logo, banner_upload: banner)
      sign_in(owner)

      get "/community-platform/communities/#{community.slug}.json"

      expect(response.status).to eq(200)
      body = response.parsed_body.fetch("community")
      expect(body["can_manage"]).to eq(true)
      expect(body["owner_username"]).to eq(owner.username)
      expect(body["icon_upload_id"]).to eq(logo.id)
      expect(body["banner_upload_id"]).to eq(banner.id)
      expect(body["icon_url"]).to eq(logo.url)
      expect(body["banner_url"]).to eq(banner.url)
    end

    it "keeps secure branding urls behind the current Guardian upload boundary" do
      logo =
        Fabricate(
          :upload,
          user: owner,
          original_filename: "secure-community-logo.png",
          extension: "png",
        )
      banner =
        Fabricate(
          :upload,
          user: owner,
          original_filename: "secure-community-banner.jpg",
          extension: "jpg",
        )
      logo.update!(secure: true)
      banner.update!(secure: true)
      community.update!(icon_upload: logo, banner_upload: banner)
      sign_in(owner)

      guardian = Guardian.new(owner)
      expect(guardian.can_see_upload?(logo)).to eq(false)
      expect(guardian.can_see_upload?(banner)).to eq(false)

      get "/community-platform/communities/#{community.slug}.json"

      expect(response.status).to eq(200)
      body = response.parsed_body.fetch("community")
      expect(body["icon_upload_id"]).to eq(logo.id)
      expect(body["banner_upload_id"]).to eq(banner.id)
      expect(body["icon_url"]).to be_nil
      expect(body["banner_url"]).to be_nil
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
      expect(body["can_manage"]).to eq(true)
    end

    it "requires an authenticated user" do
      post "/community-platform/communities.json",
           params: { community: { name: "Gaming", slug: "gaming" } }

      expect(response.status).to eq(403)
    end
  end

  describe "PATCH /community-platform/communities/:slug.json" do
    fab!(:outsider, :user)

    def create_managed_community
      DiscourseCommunityPlatform::Communities::Create.call(
        user: owner,
        params: {
          name: "Managed",
          slug: "managed",
          description: "Managed community",
          visibility: "public",
        },
      )
    end

    it "updates metadata, branding, and category visibility for the owner" do
      managed = create_managed_community
      logo =
        Fabricate(
          :upload,
          user: owner,
          original_filename: "managed-logo.png",
          extension: "png",
        )
      banner =
        Fabricate(
          :upload,
          user: owner,
          original_filename: "managed-banner.jpg",
          extension: "jpg",
        )
      sign_in(owner)

      patch "/community-platform/communities/#{managed.slug}.json",
            params: {
              community: {
                description: "Updated community",
                visibility: "private",
                icon_emoji: "🧭",
                banner_color: "#112233",
                icon_upload_id: logo.id,
                banner_upload_id: banner.id,
                rules: ["Be respectful", "No spam"],
              },
            }

      expect(response.status).to eq(200)

      managed.reload
      body = response.parsed_body.fetch("community")

      expect(managed.description).to eq("Updated community")
      expect(managed.visibility).to eq("private")
      expect(managed.rules).to eq(["Be respectful", "No spam"])
      expect(managed.icon_emoji).to eq("🧭")
      expect(managed.banner_color).to eq("112233")
      expect(managed.icon_upload_id).to eq(logo.id)
      expect(managed.banner_upload_id).to eq(banner.id)
      expect(managed.category.reload.description).to eq("Updated community")
      expect(managed.category.read_restricted).to eq(true)
      expect(body["can_manage"]).to eq(true)
      expect(body["banner_color"]).to eq("112233")
      expect(body["icon_upload_id"]).to eq(logo.id)
      expect(body["banner_upload_id"]).to eq(banner.id)
      expect(body["icon_url"]).to eq(logo.url)
      expect(body["banner_url"]).to eq(banner.url)
    end

    it "rejects an unrelated authenticated user" do
      managed = create_managed_community
      sign_in(outsider)

      patch "/community-platform/communities/#{managed.slug}.json",
            params: { community: { description: "Hijacked" } }

      expect(response.status).to eq(403)
      expect(managed.reload.description).to eq("Managed community")
    end

    it "requires authentication" do
      managed = create_managed_community

      patch "/community-platform/communities/#{managed.slug}.json",
            params: { community: { description: "Anonymous change" } }

      expect(response.status).to eq(403)
      expect(managed.reload.description).to eq("Managed community")
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
