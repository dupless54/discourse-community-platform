import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | explore page", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/explore.json", () => {
      return helper.response({
        order: "explore",
        personalized: false,
        topics: [
          {
            id: 301,
            title: "Discover a new community discussion",
            slug: "discover-new-community",
            path: "/t/discover-new-community/301",
            posts_count: 9,
            views: 180,
            like_count: 12,
            score: 7,
            upvotes: 8,
            downvotes: 1,
            user_vote: 0,
            community: {
              id: 11,
              name: "Science",
              slug: "science",
              path: "/s/science",
            },
          },
        ],
      });
    });
  });

  test("renders diversified discovery topics and marks Explore active", async function (assert) {
    await visit("/explore");

    assert.dom(".dcp-feed-navigation").exists();
    assert.dom('[data-feed="home"]').hasAttribute("href", "/home");
    assert.dom('[data-feed="following"]').hasAttribute("href", "/following");
    assert
      .dom('[data-feed="explore"]')
      .hasClass("active")
      .hasAttribute("href", "/explore");
    assert.dom('[data-feed="popular"]').hasAttribute("href", "/popular");
    assert.dom(".dcp-explore-hero h1").hasText("Explore");
    assert.dom(".dcp-explore-card").exists({ count: 1 });
    assert
      .dom(".dcp-explore-card .dcp-popular-card__community")
      .hasText("s/science")
      .hasAttribute("href", "/s/science");
    assert
      .dom(".dcp-explore-card .dcp-popular-card__title")
      .hasText("Discover a new community discussion")
      .hasAttribute("href", "/t/discover-new-community/301");
  });
});
