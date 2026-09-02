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
            path: "/s/hardware",
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
    assert.dom(".dcp-platform-right-rail").includesText("s/hardware");
    assert
      .dom('.dcp-platform-right-rail a[href="/s/hardware"]')
      .exists();
    assert.dom('[data-platform-feed="home"]').exists({ count: 2 });
    assert.dom('[data-platform-feed="home"]').hasClass("active");
    assert
      .dom('.dcp-platform-search input[name="q"]')
      .hasAttribute("type", "search")
      .hasAttribute("aria-label", i18n("search.title"))
      .hasAttribute("placeholder", i18n("search.title"));
    assert.dom(".dcp-platform-account__profile").exists();
  });
});
