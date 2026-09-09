# frozen_string_literal: true

require "digest"
require File.expand_path(
  "../../db/migrate/20260906190000_backfill_community_legacy_permalinks.rb",
  __dir__,
)

RSpec.describe "RC3 upgrade data continuity" do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:voter, :user)
  fab!(:author, :user)

  before do
    @original_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  after { ActiveRecord::Migration.verbose = @original_verbose }

  it "preserves existing Community, vote, score, AutoModerator rule, and audit data" do
    community =
      DiscourseCommunityPlatform::Communities::Create.call(
        user: owner,
        params: {
          name: "Upgrade Safety",
          slug: "upgrade-safety",
          description: "Existing RC2 Community data",
          visibility: "public",
        },
      )
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase")

    DiscourseCommunityPlatform::Votes::Cast.call(user: voter, topic:, value: 1)
    vote = DiscourseCommunityPlatform::Vote.find_by!(user_id: voter.id, topic_id: topic.id)
    score = DiscourseCommunityPlatform::TopicScore.find_by!(topic_id: topic.id)
    rule =
      DiscourseCommunityPlatform::AutomodRule.create!(
        community:,
        name: "Upgrade keyword guard",
        terms: ["blocked phrase"],
        match_mode: "all",
        target: "replies",
        action: "flag_only",
        created_by: owner,
        updated_by: owner,
      )
    execution =
      DiscourseCommunityPlatform::AutomodExecution.create!(
        community:,
        automod_rule: rule,
        post:,
        rule_name: rule.name,
        trigger: "create",
        outcome: "flagged_for_review",
        content_sha256: Digest::SHA256.hexdigest(post.raw),
      )

    snapshots = {
      community: community.attributes,
      vote: vote.attributes,
      score: score.attributes,
      rule: rule.attributes,
      execution: execution.attributes,
    }
    member_group_id = community.member_group_id
    owner_membership_id =
      community.member_group.group_users.find_by!(user_id: owner.id).id

    Permalink.find_by_url("s/#{community.slug}").destroy!
    expect(Permalink.find_by_url("s/#{community.slug}")).to be_nil

    BackfillCommunityLegacyPermalinks.new.up

    expect(community.reload.attributes).to eq(snapshots[:community])
    expect(vote.reload.attributes).to eq(snapshots[:vote])
    expect(score.reload.attributes).to eq(snapshots[:score])
    expect(rule.reload.attributes).to eq(snapshots[:rule])
    expect(execution.reload.attributes).to eq(snapshots[:execution])
    expect(community.member_group_id).to eq(member_group_id)
    expect(GroupUser.exists?(id: owner_membership_id, group_id: member_group_id, user_id: owner.id)).to eq(
      true,
    )
    expect(Permalink.find_by_url("s/#{community.slug}")&.category_id).to eq(community.category_id)
  end
end
