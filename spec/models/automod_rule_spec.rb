# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::AutomodRule do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 3
  end

  def create_community
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: { name: "Safety", slug: "safety", visibility: "public" },
    )
  end

  def create_rule(community:, **attrs)
    described_class.create!(
      {
        community:,
        name: "Scam phrases",
        terms: ["telegram"],
        created_by: owner,
        updated_by: owner,
      }.merge(attrs),
    )
  end

  it "normalizes terms and supports any/all matching without user regex" do
    community = create_community
    rule =
      create_rule(
        community:,
        terms: ["  BUY NOW ", "telegram", "telegram"],
        match_mode: "any",
      )

    expect(rule.terms).to eq(["buy now", "telegram"])
    expect(rule.matches?("Message me on Telegram")).to eq(true)

    rule.update!(match_mode: "all")
    expect(rule.matches?("Buy now and message me on Telegram")).to eq(true)
    expect(rule.matches?("Buy now")).to eq(false)
  end

  it "defaults existing-style rules to all posts and priority review" do
    rule = create_rule(community: create_community)

    expect(rule.target).to eq("all_posts")
    expect(rule.action).to eq("queue_for_review")
    expect(rule.queue_for_review?).to eq(true)
  end

  it "supports bounded topic-starter and reply targets" do
    community = create_community
    topic = Fabricate(:topic, category: community.category, user: owner)
    first_post = Fabricate(:post, topic:, user: owner, post_number: 1)
    reply = Fabricate(:post, topic:, user: owner, post_number: 2)

    starter_rule = create_rule(community:, target: "topic_starters")
    reply_rule = create_rule(community:, name: "Reply rule", target: "replies")

    expect(starter_rule.applies_to_post?(first_post)).to eq(true)
    expect(starter_rule.applies_to_post?(reply)).to eq(false)
    expect(reply_rule.applies_to_post?(first_post)).to eq(false)
    expect(reply_rule.applies_to_post?(reply)).to eq(true)
  end

  it "rejects unknown targets and actions" do
    rule = create_rule(community: create_community)

    rule.target = "regex_everywhere"
    rule.action = "delete"

    expect(rule).not_to be_valid
    expect(rule.errors[:target]).to be_present
    expect(rule.errors[:action]).to be_present
  end

  it "bounds the number of rules that one community can evaluate" do
    community = create_community

    described_class::MAX_RULES_PER_COMMUNITY.times do |index|
      described_class.create!(
        community:,
        name: "Rule #{index}",
        terms: ["term #{index}"],
        created_by: owner,
        updated_by: owner,
      )
    end

    extra_rule =
      described_class.new(
        community:,
        name: "One too many",
        terms: ["overflow"],
        created_by: owner,
        updated_by: owner,
      )

    expect(extra_rule).not_to be_valid
    expect(extra_rule.errors.full_messages.join).to include(
      described_class::MAX_RULES_PER_COMMUNITY.to_s,
    )
  end
end
