import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | Explore quick join", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/explore.json", () => {
      return helper.response({
        order: "explore",
        personalized: true,
        recommended_communities: [
          {
            id: 17,
            name: "Hardware",
            slug: "hardware",
            path: "/s/hardware",
            description: "PC hardware discussions.",
            members_count: 84,
            icon_emoji: "🖥️",
            icon_url: null,
            banner_color: "334455",
            recent_topics_count: 6,
            can_join: true,
          },
        ],
        recommended_people: [],
        topics: [],
      });
    });

    server.post("/community-platform/communities/hardware/join.json", () => {
      return helper.response({
        community: {
          id: 17,
          name: "Hardware",
          slug: "hardware",
          path: "/s/hardware",
          members_count: 85,
          is_member: true,
          can_join: false,
        },
      });
    });
  });

  test("keeps one rail-owned join state while preserving separate navigation", async function (assert) {
    await visit("/explore");

    assert.dom("[data-test-explore-discovery]").exists({ count: 1 });
    assert.dom(".dcp-explore-communities").doesNotExist();
    assert
      .dom(".dcp-explore-community-card__link")
      .hasAttribute("href", "/s/hardware")
      .includesText("s/hardware");
    assert
      .dom(".dcp-explore-community-card__join")
      .hasText("Join")
      .isNotDisabled();

    await click(".dcp-explore-community-card__join");

    assert.dom(".dcp-explore-community-card__join").doesNotExist();
    assert.dom(".dcp-explore-community-card__joined").hasText("Joined");
    assert.dom(".dcp-explore-community-card__meta").includesText("85 members");
    assert.dom(".dcp-explore-membership-error").doesNotExist();
    assert.dom("[data-test-explore-discovery]").exists({ count: 1 });
  });
});
