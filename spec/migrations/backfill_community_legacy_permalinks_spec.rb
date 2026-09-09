# frozen_string_literal: true

require File.expand_path(
  "../../db/migrate/20260906190000_backfill_community_legacy_permalinks.rb",
  __dir__,
)

RSpec.describe BackfillCommunityLegacyPermalinks do
  fab!(:owner, :user)

  before do
    @original_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
  end

  after { ActiveRecord::Migration.verbose = @original_verbose }

  def create_community(slug)
    category = Fabricate(:category)

    community =
      DiscourseCommunityPlatform::Community.create!(
        name: slug.titleize,
        slug:,
        description: "Migration regression fixture",
        category:,
        owner:,
        visibility: "public",
        rules: [],
      )

    [community, category]
  end

  it "backfills only missing legacy permalinks and remains idempotent" do
    existing_community, existing_category = create_community("existing-legacy")
    missing_community, missing_category = create_community("missing-legacy")
    existing_permalink =
      Permalink.create!(url: "s/#{existing_community.slug}", category: existing_category)

    2.times { described_class.new.up }

    expect(Permalink.where(url: "s/#{existing_community.slug}")).to contain_exactly(existing_permalink)
    expect(Permalink.where(url: "s/#{missing_community.slug}").pluck(:category_id)).to eq(
      [missing_category.id],
    )
  end

  it "refuses a rollback that could delete a pre-existing Discourse permalink" do
    community, category = create_community("preexisting-legacy")
    existing_permalink = Permalink.create!(url: "s/#{community.slug}", category:)

    expect { described_class.new.down }.to raise_error(ActiveRecord::IrreversibleMigration)
    expect(Permalink.exists?(existing_permalink.id)).to eq(true)
  end
end
