# frozen_string_literal: true

describe "Explore Community keyboard quick join" do
  fab!(:owner) { Fabricate(:user, trust_level: 1) }
  fab!(:viewer) { Fabricate(:user, trust_level: 1) }

  let(:community) do
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "Keyboard Discovery Community",
        slug: "keyboard-discovery-community",
        description: "A public Community used for real-browser Explore keyboard coverage.",
        visibility: "public",
      },
    )
  end

  before do
    SiteSetting.community_platform_allow_user_community_creation = true
    SiteSetting.community_platform_min_trust_level_to_create = 1
    SiteSetting.community_platform_max_communities_per_user = 8

    community
    Discourse.cache.write(
      DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_KEY,
      [[community.id, 3, 20.0]],
      expires_in: 30.minutes,
    )
  end

  after do
    Discourse.cache.delete(DiscourseCommunityPlatform::Feeds::ExploreCommunities::CACHE_KEY)
  end

  it "tabs from native Community navigation to quick join and joins with Enter" do
    sign_in(viewer)

    resize_window(width: 500, height: 900) do
      visit("/explore")

      link_selector = ".dcp-explore-discovery-community__link"
      join_selector = ".dcp-explore-community-card__join"

      expect(page).to have_css(link_selector, text: community.name)
      expect(page).to have_css(join_selector, text: I18n.t("js.community_platform.join"))
      expect(page).to have_css("#{link_selector}[href='#{community.category.url}']")

      page.execute_script("document.querySelector(#{link_selector.to_json}).focus()")
      expect(
        page.evaluate_script(
          "document.activeElement?.matches(#{link_selector.to_json})",
        ),
      ).to eq(true)

      page.send_keys(:tab)
      expect(
        page.evaluate_script(
          "document.activeElement?.matches(#{join_selector.to_json})",
        ),
      ).to eq(true)

      page.send_keys(:enter)

      expect(page).to have_no_css(join_selector)
      expect(page).to have_css(
        ".dcp-explore-community-card__joined[role='status']",
        text: I18n.t("js.community_platform.joined"),
      )
      expect(page).to have_no_css(".dcp-explore-membership-error")
      expect(
        community.member_group.reload.group_users.exists?(user_id: viewer.id, owner: false),
      ).to eq(true)
    end
  end
end
