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

  def create_rule(community:, terms:, match_mode: "any", enabled: true)
    DiscourseCommunityPlatform::AutomodRule.create!(
      community:,
      name: "Keyword guard",
      enabled:,
      match_mode:,
      terms:,
      created_by: owner,
      updated_by: owner,
    )
  end

  it "queues a matching community post for review through Discourse moderation primitives" do
    community = create_community(name: "Marketplace", slug: "marketplace")
    create_rule(community:, terms: ["buy now", "crypto"])
    topic = Fabricate(:topic, category: community.category, user: author)
    post = Fabricate(:post, topic:, user: author, raw: "Best crypto deal — buy now")
    creator = double("post_action_creator", perform: true)
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
