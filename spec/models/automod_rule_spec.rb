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

  it "normalizes terms and supports any/all matching without user regex" do
    community = create_community
    rule =
      described_class.create!(
        community:,
        name: "Scam phrases",
        terms: ["  BUY NOW ", "telegram", "telegram"],
        match_mode: "any",
        created_by: owner,
        updated_by: owner,
      )

    expect(rule.terms).to eq(["buy now", "telegram"])
    expect(rule.matches?("Message me on Telegram")).to eq(true)

    rule.update!(match_mode: "all")
    expect(rule.matches?("Buy now and message me on Telegram")).to eq(true)
    expect(rule.matches?("Buy now")).to eq(false)
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
