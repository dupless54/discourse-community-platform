# frozen_string_literal: true

describe "Responsive platform discovery rails" do
  fab!(:owner, :user)
  fab!(:viewer, :user)
  fab!(:category, :category_with_definition) do
    category = Fabricate(:category_with_definition, name: "Development")
    category.set_permissions(everyone: :full)
    category.save!
    category
  end
  fab!(:community) do
    DiscourseCommunityPlatform::Community.create!(
      name: "Development",
      slug: "development",
      description: "Build and ship software together",
      category:,
      owner:,
      visibility: "public",
      rules: ["Be respectful"],
    )
  end

  before do
    Discourse.cache.write(
      DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_KEY,
      [[community.id, 3, 20.0]],
      expires_in: 30.minutes,
    )
  end

  after do
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_KEY)
  end

  it "keeps Home Community recommendations visible at tablet and mobile widths" do
    sign_in(viewer)

    resize_window(width: 900, height: 900) do
      visit("/home")

      expect(page).to have_css('.dcp-platform-shell[data-platform-section="home"]')
      expect(page).to have_css(".dcp-platform-right-rail")
      expect(page).to have_css(
        ".dcp-explore-discovery-community__link",
        text: community.name,
      )
    end

    resize_window(width: 500, height: 900) do
      visit("/home")

      expect(page).to have_css(".dcp-platform-right-rail")
      expect(page).to have_css(
        ".dcp-explore-discovery-community__link",
        text: community.name,
      )
    end
  end

  it "keeps Following and Popular discovery actions visible on narrow screens" do
    sign_in(viewer)

    [900, 500].each do |width|
      resize_window(width:, height: 900) do
        %w[following popular].each do |section|
          visit("/#{section}")

          expect(page).to have_css(
            ".dcp-platform-shell[data-platform-section=\"#{section}\"]",
          )
          expect(page).to have_css(".dcp-platform-right-rail")
          expect(page).to have_css(".dcp-platform-rail-card--discover")
        end
      end
    end
  end
end
