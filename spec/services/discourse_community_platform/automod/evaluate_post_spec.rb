# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Automod::EvaluatePost do
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

  def create_rule(
    community:,
    terms:,
    match_mode: "any",
    enabled: true,
    target: "all_posts",
    action: "queue_for_review",
    max_account_age_days: nil,
    max_trust_level: nil
  )
    DiscourseCommunityPlatform::AutomodRule.create!(
      community:,
      name: "Keyword guard",
      enabled:,
      match_mode:,
      target:,
      action:,
      max_account_age_days:,
      max_trust_level:,
      terms:,
      created_by: owner,
      updated_by: owner,
    )
  end

  def successful_creator
    result = instance_double(PostActionCreator::CreateResult, success?: true)
    instance_double(PostActionCreator, perform: result)
  end

  it "queues a matching community post for review and records an audit execution" do
    community = create_community(name: "Marketplace", slug: "marketplace")
    rule = create_rule(community:, terms: ["buy now", "crypto"])
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "Best crypto deal — buy now")
    creator = successful_creator
    allow(PostActionCreator).to receive(:new).and_return(creator)

    described_class.call(post:)

    expect(PostActionCreator).to have_received(:new).with(
      Discourse.system_user,
      post,
      PostActionType.types[:inappropriate],
      message:
        I18n.t(
          "community_platform.automod.flag_reason",
          community: community.name,
          rule: "Keyword guard",
        ),
      queue_for_review: true,
    )

    execution = DiscourseCommunityPlatform::AutomodExecution.last
    expect(execution).to have_attributes(
      community_id: community.id,
      automod_rule_id: rule.id,
      post_id: post.id,
      rule_name: "Keyword guard",
      trigger: "create",
      outcome: "queued_for_review",
    )
    expect(execution.content_sha256).to eq(Digest::SHA256.hexdigest(post.raw))
  end

  it "uses a standard Discourse flag when the bounded action is flag_only" do
    community = create_community(name: "Flag only", slug: "flag-only")
    create_rule(community:, terms: ["blocked phrase"], action: "flag_only")
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase")
    creator = successful_creator
    allow(PostActionCreator).to receive(:new).and_return(creator)

    described_class.call(post:)

    expect(PostActionCreator).to have_received(:new).with(
      Discourse.system_user,
      post,
      PostActionType.types[:inappropriate],
      message:
        I18n.t(
          "community_platform.automod.flag_reason",
          community: community.name,
          rule: "Keyword guard",
        ),
      queue_for_review: false,
    )
    expect(DiscourseCommunityPlatform::AutomodExecution.last.outcome).to eq("flagged_for_review")
  end

  it "applies a matching rule when the author satisfies both bounded conditions" do
    community = create_community(name: "New users", slug: "newusers")
    young_author = Fabricate(:user, trust_level: TrustLevel[0])
    young_author.update_column(:created_at, 3.days.ago)
    create_rule(
      community:,
      terms: ["blocked phrase"],
      max_account_age_days: 7,
      max_trust_level: TrustLevel[0],
    )
    topic = Fabricate(:topic, category: community.category, user: young_author)
    post = Fabricate(:post, topic:, user: young_author, raw: "blocked phrase")
    creator = successful_creator
    allow(PostActionCreator).to receive(:new).and_return(creator)

    described_class.call(post:)

    expect(PostActionCreator).to have_received(:new).once
    expect(DiscourseCommunityPlatform::AutomodExecution.where(post_id: post.id).count).to eq(1)
  end

  it "does not apply an author-conditioned rule to an older or higher-trust author" do
    community = create_community(name: "Author bounds", slug: "author-bounds")
    create_rule(
      community:,
      terms: ["blocked phrase"],
      max_account_age_days: 7,
      max_trust_level: TrustLevel[1],
    )
    old_author = Fabricate(:user, trust_level: TrustLevel[1])
    old_author.update_column(:created_at, 30.days.ago)
    high_trust_author = Fabricate(:user, trust_level: TrustLevel[2])
    high_trust_author.update_column(:created_at, 2.days.ago)
    old_topic = Fabricate(:topic, category: community.category, user: old_author)
    high_trust_topic = Fabricate(:topic, category: community.category, user: high_trust_author)
    old_post = Fabricate(:post, topic: old_topic, user: old_author, raw: "blocked phrase")
    high_trust_post =
      Fabricate(:post, topic: high_trust_topic, user: high_trust_author, raw: "blocked phrase")
    allow(PostActionCreator).to receive(:new)

    described_class.call(post: old_post)
    described_class.call(post: high_trust_post)

    expect(PostActionCreator).not_to have_received(:new)
    expect(
      DiscourseCommunityPlatform::AutomodExecution.where(post_id: [old_post.id, high_trust_post.id]),
    ).to be_empty
  end

  it "does not apply a reply-only rule to the topic starter" do
    community = create_community(name: "Replies", slug: "replies")
    create_rule(community:, terms: ["blocked phrase"], target: "replies")
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase", post_number: 1)
    allow(PostActionCreator).to receive(:new)

    described_class.call(post:)

    expect(PostActionCreator).not_to have_received(:new)
    expect(DiscourseCommunityPlatform::AutomodExecution.where(post_id: post.id)).to be_empty
  end

  it "records an edited matching post that was already queued without creating another flag" do
    community = create_community(name: "Edited", slug: "edited")
    rule = create_rule(community:, terms: ["blocked phrase"])
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase after edit")
    allow(PostAction).to receive(:exists?).and_return(true)
    allow(PostActionCreator).to receive(:new)

    described_class.call(post:, trigger: "edit")

    expect(PostActionCreator).not_to have_received(:new)
    expect(DiscourseCommunityPlatform::AutomodExecution.last).to have_attributes(
      community_id: community.id,
      automod_rule_id: rule.id,
      post_id: post.id,
      trigger: "edit",
      outcome: "already_queued",
    )
  end

  it "recognizes a retained system review score when the post action is no longer active" do
    community = create_community(name: "Retained review", slug: "retained-review")
    rule = create_rule(community:, terms: ["blocked phrase"])
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase after edit")
    inappropriate_type_id = PostActionType.types[:inappropriate]
    system_user = Discourse.system_user
    reviewable =
      ReviewableFlaggedPost.needs_review!(
        created_by: system_user,
        target: post,
        topic:,
        reviewable_by_moderator: true,
      )
    reviewable.add_score(
      system_user,
      inappropriate_type_id,
      reason: "queued_by_staff",
    )
    allow(PostActionCreator).to receive(:new)

    described_class.call(post:, trigger: "edit")

    expect(PostActionCreator).not_to have_received(:new)
    expect(
      reviewable.reviewable_scores.where(
        user_id: system_user.id,
        reviewable_score_type: inappropriate_type_id,
      ).count,
    ).to eq(1)
    expect(DiscourseCommunityPlatform::AutomodExecution.last).to have_attributes(
      community_id: community.id,
      automod_rule_id: rule.id,
      post_id: post.id,
      trigger: "edit",
      outcome: "already_queued",
    )
  end

  it "does not process the same rule, post, and content twice" do
    community = create_community(name: "Dedup", slug: "dedup")
    create_rule(community:, terms: ["blocked phrase"])
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase")
    creator = successful_creator
    allow(PostActionCreator).to receive(:new).and_return(creator)

    described_class.call(post:)
    described_class.call(post:, trigger: "edit")

    expect(PostActionCreator).to have_received(:new).once
    expect(DiscourseCommunityPlatform::AutomodExecution.where(post_id: post.id).count).to eq(1)
  end

  it "does not audit a failed review action" do
    community = create_community(name: "Failure", slug: "failure")
    create_rule(community:, terms: ["blocked phrase"])
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase")
    result = instance_double(PostActionCreator::CreateResult, success?: false)
    creator = instance_double(PostActionCreator, perform: result)
    allow(PostActionCreator).to receive(:new).and_return(creator)

    described_class.call(post:)

    expect(DiscourseCommunityPlatform::AutomodExecution.where(post_id: post.id)).to be_empty
  end

  it "supports all-term rules without flagging partial matches" do
    community = create_community(name: "Support", slug: "support")
    create_rule(community:, terms: ["refund", "telegram"], match_mode: "all")
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "Please refund this order")
    allow(PostActionCreator).to receive(:new)

    described_class.call(post:)

    expect(PostActionCreator).not_to have_received(:new)
  end

  it "does not apply a rule to posts from another community" do
    guarded = create_community(name: "Guarded", slug: "guarded")
    other = create_community(name: "Other", slug: "other")
    create_rule(community: guarded, terms: ["blocked phrase"])
    topic = Fabricate(:topic, category: other.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase")
    allow(PostActionCreator).to receive(:new)

    described_class.call(post:)

    expect(PostActionCreator).not_to have_received(:new)
  end

  it "ignores disabled rules" do
    community = create_community(name: "Disabled", slug: "disabled")
    create_rule(community:, terms: ["blocked phrase"], enabled: false)
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "blocked phrase")
    allow(PostActionCreator).to receive(:new)

    described_class.call(post:)

    expect(PostActionCreator).not_to have_received(:new)
  end
end
