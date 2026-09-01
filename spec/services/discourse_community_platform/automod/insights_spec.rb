# frozen_string_literal: true

require "digest"

RSpec.describe DiscourseCommunityPlatform::Automod::Insights do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:author, :user)

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community(name:, slug:)
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name:, slug:, visibility: "public" },
    )
  end

  def create_rule(community:, name:)
    DiscourseCommunityPlatform::AutomodRule.create!(
      community:,
      name:,
      terms: ["blocked phrase"],
      created_by: owner,
      updated_by: owner,
    )
  end

  def create_execution(community:, rule:, post:, trigger:, outcome:, created_at:)
    execution =
      DiscourseCommunityPlatform::AutomodExecution.create!(
        community:,
        automod_rule: rule,
        post:,
        rule_name: rule.name,
        trigger:,
        outcome:,
        content_sha256: Digest::SHA256.hexdigest("#{post.id}-#{created_at.to_f}"),
      )
    execution.update_columns(created_at:, updated_at: created_at)
    execution
  end

  it "returns bounded 7-day and 30-day aggregate moderation insights" do
    now = Time.zone.parse("2026-09-01 12:00:00")
    community = create_community(name: "Safety", slug: "safety")
    other = create_community(name: "Other", slug: "other")
    rule_a = create_rule(community:, name: "Spam guard")
    rule_b = create_rule(community:, name: "Link guard")
    other_rule = create_rule(community: other, name: "Other guard")
    topic = Fabricate(:topic, category: community.category, user: author)
    post_one = Fabricate(:post, topic:, user: author, raw: "blocked phrase one")
    post_two = Fabricate(:post, topic:, user: author, raw: "blocked phrase two")
    other_topic = Fabricate(:topic, category: other.category, user: author)
    other_post = Fabricate(:post, topic: other_topic, user: author, raw: "other blocked phrase")

    create_execution(
      community:,
      rule: rule_a,
      post: post_one,
      trigger: "create",
      outcome: "queued_for_review",
      created_at: now - 2.days,
    )
    create_execution(
      community:,
      rule: rule_a,
      post: post_one,
      trigger: "edit",
      outcome: "already_queued",
      created_at: now - 3.days,
    )
    create_execution(
      community:,
      rule: rule_b,
      post: post_two,
      trigger: "create",
      outcome: "flagged_for_review",
      created_at: now - 20.days,
    )
    create_execution(
      community:,
      rule: rule_b,
      post: post_two,
      trigger: "edit",
      outcome: "queued_for_review",
      created_at: now - 40.days,
    )
    create_execution(
      community: other,
      rule: other_rule,
      post: other_post,
      trigger: "create",
      outcome: "queued_for_review",
      created_at: now - 1.day,
    )

    result = described_class.call(community:, now:)

    expect(result[:last_7_days]).to eq(
      executions: 2,
      unique_posts: 1,
      queued_for_review: 1,
      flagged_for_review: 0,
      already_queued: 1,
    )
    expect(result[:last_30_days]).to eq(
      executions: 3,
      unique_posts: 2,
      queued_for_review: 1,
      flagged_for_review: 1,
      already_queued: 1,
    )
    expect(result[:triggers_30_days]).to eq(create: 2, edit: 1)
    expect(result[:top_rules_30_days]).to eq(
      [
        { rule_name: "Spam guard", executions: 2 },
        { rule_name: "Link guard", executions: 1 },
      ],
    )
  end
end
