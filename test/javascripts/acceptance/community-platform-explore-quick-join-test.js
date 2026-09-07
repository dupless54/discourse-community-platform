import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | Explore quick join", function (needs) {
  let joinResponseStatus = 200;

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
            path: "/c/hardware/17",
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
      if (joinResponseStatus !== 200) {
        return helper.response(joinResponseStatus, {});
      }

      return helper.response({
        community: {
          id: 17,
          name: "Hardware",
          slug: "hardware",
          path: "/c/hardware/17",
          members_count: 85,
          is_member: true,
          can_join: false,
        },
      });
    });
  });

  test("keeps navigation and join as separate keyboard targets and announces success", async function (assert) {
    joinResponseStatus = 200;
    await visit("/explore");

    assert.dom("[data-test-explore-discovery]").exists({ count: 1 });
    assert.dom(".dcp-explore-communities").doesNotExist();
    assert
      .dom(".dcp-explore-community-card__link")
      .hasAttribute("href", "/c/hardware/17")
      .includesText("Hardware");
    assert
      .dom(".dcp-explore-community-card__join")
      .hasText("Join")
      .isNotDisabled();

    const communityLink = document.querySelector(
      ".dcp-explore-community-card__link"
    );
    const joinButton = document.querySelector(
      ".dcp-explore-community-card__join"
    );

    assert.strictEqual(communityLink?.tagName, "A");
    assert.strictEqual(joinButton?.tagName, "BUTTON");
    assert.strictEqual(communityLink?.tabIndex, 0);
    assert.strictEqual(joinButton?.tabIndex, 0);
    assert.false(communityLink?.contains(joinButton));
    assert.false(joinButton?.contains(communityLink));

    await click(".dcp-explore-community-card__join");

    assert.dom(".dcp-explore-community-card__join").doesNotExist();
    assert
      .dom(".dcp-explore-community-card__joined")
      .hasText("Joined")
      .hasAttribute("role", "status");
    assert.dom(".dcp-explore-community-card__meta").includesText("85 members");
    assert.dom(".dcp-explore-membership-error").doesNotExist();
    assert.dom("[data-test-explore-discovery]").exists({ count: 1 });
  });

  test("announces membership errors and restores the join control", async function (assert) {
    joinResponseStatus = 500;
    await visit("/explore");

    await click(".dcp-explore-community-card__join");

    assert
      .dom(".dcp-explore-membership-error")
      .exists({ count: 1 })
      .hasAttribute("role", "alert");
    assert
      .dom(".dcp-explore-community-card__join")
      .exists({ count: 1 })
      .hasText("Join")
      .isNotDisabled();
    assert.dom(".dcp-explore-community-card__joined").doesNotExist();
  });
});
