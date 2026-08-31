# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Community do
  fab!(:owner, :user)
  fab!(:category)

  def build_community(**overrides)
    described_class.new(
      {
        name: "Technology",
        slug: "Technology News",
        category: category,
        owner: owner,
        visibility: "public",
      }.merge(overrides),
    )
  end

  it "normalizes slugs with Discourse's slug implementation" do
    community = build_community

    expect(community).to be_valid
    expect(community.slug).to eq(Slug.for("Technology News"))
  end

  it "rejects unsupported visibility values" do
    community = build_community(visibility: "secret")

    expect(community).not_to be_valid
    expect(community.errors[:visibility]).to be_present
  end

  it "allows each Discourse category to back only one community" do
    build_community(slug: "technology").save!
    duplicate = build_community(slug: "technology-two")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:category_id]).to be_present
  end
end
