import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | popular page", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/popular.json", () => {
      return helper.response({
        order: "popular",
        topics: [
          {
            id: 201,
            title: "A fast-moving technology discussion",
            slug: "fast-moving-technology",
            path: "/t/fast-moving-technology/201",
            posts_count: 14,
            views: 420,
            like_count: 31,
            score: 18,
            upvotes: 20,
            downvotes: 2,
            user_vote: 0,
            excerpt: "This text is hidden when an image preview is available.",
            image_url: "/uploads/default/original/1X/popular-preview.png",
            community: {
              id: 7,
              name: "Technology",
              slug: "technology",
              path: "/s/technology",
            },
          },
        ],
      });
    });
  });

  test("renders cached global popular topics with community context and image previews", async function (assert) {
    await visit("/popular");

    assert.dom(".dcp-feed-navigation").exists();
    assert.dom('[data-feed="home"]').hasAttribute("href", "/home");
    assert.dom('[data-feed="following"]').hasAttribute("href", "/following");
    assert
      .dom('[data-feed="popular"]')
      .hasClass("active")
      .hasAttribute("href", "/popular");
    assert.dom(".dcp-popular-hero h1").hasText("Popular");
    assert.dom(".dcp-popular-card").exists({ count: 1 });
    assert
      .dom(".dcp-popular-card__community")
      .hasText("s/technology")
      .hasAttribute("href", "/s/technology");
    assert
      .dom(".dcp-popular-card__title")
      .hasText("A fast-moving technology discussion")
      .hasAttribute("href", "/t/fast-moving-technology/201");
    assert.dom(".dcp-popular-card__score strong").hasText("18");
    assert
      .dom(".dcp-topic-preview--image")
      .hasAttribute("href", "/t/fast-moving-technology/201")
      .hasAttribute("aria-label", "A fast-moving technology discussion");
    assert
      .dom(".dcp-topic-preview--image img")
      .hasAttribute("src", "/uploads/default/original/1X/popular-preview.png");
    assert.dom(".dcp-topic-preview--excerpt").doesNotExist();
  });
});
