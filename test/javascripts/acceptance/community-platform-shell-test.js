import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("Community Platform | platform shell", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/home.json", () => {
      return helper.response({
        order: "home",
        personalized: true,
        joined_communities: [
          {
            id: 4,
            name: "Hardware",
            slug: "hardware",
            path: "/c/hardware/4",
          },
        ],
        trending_topics: [
          {
            id: 91,
            title: "A cached trending discussion",
            path: "/t/cached-trending-discussion/91",
            posts_count: 14,
            score: 23,
            community: {
              id: 7,
              name: "Gaming",
              slug: "gaming",
              path: "/c/gaming/7",
            },
          },
        ],
        topics: [],
      });
    });
  });

  test("renders the route-scoped desktop and mobile shell", async function (assert) {
    await visit("/home");

    assert.true(document.body.classList.contains("dcp-platform-shell-active"));
    assert.dom('.dcp-platform-shell[data-platform-section="home"]').exists();
    assert.dom(".dcp-platform-header").exists();
    assert.dom(".dcp-platform-sidebar").exists();
    assert.dom(".dcp-platform-right-rail").includesText("Hardware");
    assert.dom('.dcp-platform-right-rail a[href="/c/hardware/4"]').exists();
    assert
      .dom(
        '.dcp-platform-trending-item__title[href="/t/cached-trending-discussion/91"]'
      )
      .hasText("A cached trending discussion");
    assert
      .dom('.dcp-platform-trending-community[href="/c/gaming/7"]')
      .includesText("Gaming");
    assert.dom(".dcp-platform-trending-item__meta").includesText("23 score");
    assert.dom('[data-platform-feed="home"]').exists({ count: 2 });
    assert.dom('[data-platform-feed="home"]').hasClass("active");
    assert
      .dom('.dcp-platform-search input[name="q"]')
      .hasAttribute("type", "search")
      .hasAttribute("aria-label", i18n("search.title"))
      .hasAttribute("placeholder", i18n("search.title"));

    assert.dom(".dcp-platform-account__profile").hasTagName("div");
    assert.dom(".dcp-platform-account__profile > a").exists({ count: 2 });
    assert.dom(".dcp-platform-account__profile a a").doesNotExist();
    assert.dom(".dcp-platform-account__avatar").hasAttribute("aria-label");
    assert.dom(".dcp-platform-account__profile-name").hasAttribute("href");

    const avatarLink = document.querySelector(".dcp-platform-account__avatar");
    const profileNameLink = document.querySelector(
      ".dcp-platform-account__profile-name"
    );

    assert.strictEqual(
      avatarLink?.getAttribute("href"),
      profileNameLink?.getAttribute("href"),
      "avatar and username target the same canonical Discourse profile"
    );
  });
});
