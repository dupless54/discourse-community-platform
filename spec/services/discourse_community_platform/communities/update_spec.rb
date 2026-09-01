# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Communities::Update do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:moderator, :user)
  fab!(:outsider, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "Technology",
        slug: "technology",
        description: "Technology discussions",
        visibility: "public",
      },
    )
  end

  it "lets the owner update rules and appearance while synchronizing the category description" do
    community = create_community

    updated =
      described_class.call(
        user: owner,
        community:,
        params: {
          description: "A better description",
          rules: ["Be kind", "Stay on topic"],
          icon_emoji: "💻",
          banner_color: "#1a2b3c",
        },
      )

    expect(updated.description).to eq("A better description")
    expect(updated.rules).to eq(["Be kind", "Stay on topic"])
    expect(updated.icon_emoji).to eq("💻")
    expect(updated.banner_color).to eq("1A2B3C")
    expect(updated.category.reload.description).to eq("A better description")
  end

  it "assigns manager-owned image uploads and keeps explicit upload references" do
    community = create_community
    logo =
      Fabricate(
        :upload,
        user_id: owner.id,
        original_filename: "community-logo.png",
        extension: "png",
      )
    banner =
      Fabricate(
        :upload,
        user_id: owner.id,
        original_filename: "community-banner.jpg",
        extension: "jpg",
      )

    updated =
      described_class.call(
        user: owner,
        community:,
        params: { icon_upload_id: logo.id, banner_upload_id: banner.id },
      )

    expect(updated.icon_upload_id).to eq(logo.id)
    expect(updated.banner_upload_id).to eq(banner.id)
    expect(UploadReference.exists?(target: updated, upload: logo)).to eq(true)
    expect(UploadReference.exists?(target: updated, upload: banner)).to eq(true)
  end

  it "clears removed branding references" do
    community = create_community
    logo =
      Fabricate(
        :upload,
        user_id: owner.id,
        original_filename: "community-logo.png",
        extension: "png",
      )

    described_class.call(user: owner, community:, params: { icon_upload_id: logo.id })
    described_class.call(user: owner, community:, params: { icon_upload_id: nil })

    expect(community.reload.icon_upload_id).to be_nil
    expect(UploadReference.exists?(target: community, upload: logo)).to eq(false)
  end

  it "rejects another user's upload and non-image uploads" do
    community = create_community
    foreign_image =
      Fabricate(
        :upload,
        user_id: outsider.id,
        original_filename: "foreign.png",
        extension: "png",
      )
    document =
      Fabricate(
        :upload,
        user_id: owner.id,
        original_filename: "notes.txt",
        extension: "txt",
      )

    expect {
      described_class.call(user: owner, community:, params: { icon_upload_id: foreign_image.id })
    }.to raise_error(Discourse::InvalidParameters)

    expect {
      described_class.call(user: owner, community:, params: { banner_upload_id: document.id })
    }.to raise_error(Discourse::InvalidParameters)

    expect(community.reload.icon_upload_id).to be_nil
    expect(community.banner_upload_id).to be_nil
  end

  it "lets a community moderator manage the community without global staff privileges" do
    community = create_community
    GroupManager.new(community.moderator_group).add([moderator.id])

    updated = described_class.call(user: moderator, community:, params: { rules: ["No spam"] })

    expect(updated.rules).to eq(["No spam"])
    expect(moderator.reload.admin).to eq(false)
    expect(moderator.moderator).to eq(false)
  end

  it "rejects management by an unrelated user" do
    community = create_community

    expect {
      described_class.call(user: outsider, community:, params: { description: "Hijacked" })
    }.to raise_error(Discourse::InvalidAccess)

    expect(community.reload.description).to eq("Technology discussions")
  end

  it "keeps plugin visibility and Discourse category permissions in sync" do
    community = create_community

    described_class.call(user: owner, community:, params: { visibility: "private" })

    community.reload
    permissions = community.category.category_groups.pluck(:group_id, :permission_type).to_h

    expect(community.visibility).to eq("private")
    expect(community.category.reload.read_restricted).to eq(true)
    expect(permissions).not_to have_key(Group::AUTO_GROUPS[:everyone])
    expect(permissions[community.member_group_id]).to eq(CategoryGroup.permission_types[:full])
    expect(permissions[community.moderator_group_id]).to eq(CategoryGroup.permission_types[:full])
    expect(Guardian.new(outsider).can_see_category?(community.category)).to eq(false)

    described_class.call(user: owner, community:, params: { visibility: "public" })

    expect(community.reload.visibility).to eq("public")
    expect(community.category.reload.read_restricted).to eq(false)
    expect(Guardian.new(outsider).can_see_category?(community.category)).to eq(true)
  end

  it "rejects invalid rules without partially changing category permissions" do
    community = create_community
    invalid_rules = Array.new(DiscourseCommunityPlatform::Community::MAX_RULES + 1, "Rule")

    expect {
      described_class.call(
        user: owner,
        community:,
        params: { visibility: "private", rules: invalid_rules },
      )
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(community.reload.visibility).to eq("public")
    expect(community.category.reload.read_restricted).to eq(false)
  end
end
