# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Communities::Create do
  fab!(:creator) { Fabricate(:user, trust_level: 1) }

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community(**overrides)
    described_class.call(
      user: creator,
      params: {
        name: "Technology",
        slug: "technology",
        description: "Technology discussions",
        visibility: "public",
      }.merge(overrides),
    )
  end

  it "creates a category, member group, moderator group, and community atomically" do
    community = create_community

    expect(community).to be_persisted
    expect(community.category).to be_persisted
    expect(community.member_group).to be_persisted
    expect(community.moderator_group).to be_persisted
    expect(community.owner).to eq(creator)
    expect(community.members_count).to eq(1)

    expect(community.member_group.group_users.exists?(user_id: creator.id, owner: false)).to eq(true)
    expect(community.moderator_group.group_users.exists?(user_id: creator.id, owner: true)).to eq(true)
    expect(community.member_group.reload.user_count).to eq(1)
    expect(community.moderator_group.reload.user_count).to eq(1)
    expect(CategoryModerationGroup.exists?(category: community.category, group: community.moderator_group)).to eq(true)
  end

  it "keeps public communities on normal Discourse public category permissions" do
    community = create_community

    expect(community.category.reload.read_restricted).to eq(false)
    expect(community.category.category_groups).to be_empty
    expect(Guardian.new.can_see_category?(community.category)).to eq(true)
  end

  it "makes restricted communities readable by everyone but writable by members" do
    community = create_community(visibility: "restricted")
    permissions = community.category.category_groups.pluck(:group_id, :permission_type).to_h

    expect(community.category.reload.read_restricted).to eq(false)
    expect(permissions[Group::AUTO_GROUPS[:everyone]]).to eq(CategoryGroup.permission_types[:readonly])
    expect(permissions[community.member_group_id]).to eq(CategoryGroup.permission_types[:full])
    expect(permissions[community.moderator_group_id]).to eq(CategoryGroup.permission_types[:full])
  end

  it "makes private communities visible only through their member and moderator groups" do
    community = create_community(visibility: "private")
    permissions = community.category.category_groups.pluck(:group_id, :permission_type).to_h
    outsider = Fabricate(:user)

    expect(community.category.reload.read_restricted).to eq(true)
    expect(permissions).not_to have_key(Group::AUTO_GROUPS[:everyone])
    expect(permissions[community.member_group_id]).to eq(CategoryGroup.permission_types[:full])
    expect(permissions[community.moderator_group_id]).to eq(CategoryGroup.permission_types[:full])
    expect(Guardian.new(creator).can_see_category?(community.category)).to eq(true)
    expect(Guardian.new(outsider).can_see_category?(community.category)).to eq(false)
  end

  it "rejects unsupported visibility before creating Discourse records" do
    expect { create_community(visibility: "secret") }.to raise_error(Discourse::InvalidParameters)

    expect(DiscourseCommunityPlatform::Community.count).to eq(0)
    expect(Group.where("name LIKE ?", "dcp_%").count).to eq(0)
  end

  it "enforces the configured trust-level policy for non-admin users" do
    SiteSetting.community_platform_min_trust_level_to_create = 2

    expect { create_community }.to raise_error(Discourse::InvalidAccess)
  end
end
