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
            excerpt:
              "A bounded topic summary remains visible alongside the image preview.",
            image_url: "/uploads/default/original/1X/popular-preview.png",
            community: {
              id: 7,
              name: "Technology",
              slug: "technology",
              path: "/c/technology/7",
            },
          },
        ],
      });
    });
  });

  test("renders native community context with image and excerpt previews", async function (assert) {
    await visit("/popular");

    assert.dom(".dcp-feed-navigation").exists();
    assert.dom('[data-feed="home"]').hasAttribute("href", "/");
    assert.dom('[data-feed="following"]').hasAttribute("href", "/following");
    assert
      .dom('[data-feed="popular"]')
      .hasClass("active")
      .hasAttribute("href", "/popular");
    assert.dom(".dcp-popular-hero h1").hasText("Popular");
    assert.dom(".dcp-popular-card").exists({ count: 1 });
    assert
      .dom(".dcp-popular-card .dcp-feed-community-identity")
      .includesText("Technology")
      .hasAttribute("href", "/c/technology/7");
    assert
      .dom(".dcp-popular-card__title")
      .hasText("A fast-moving technology discussion")
      .hasAttribute("href", "/t/fast-moving-technology/201");
    assert.dom(".dcp-popular-card__score strong").hasText("18");
    assert
      .dom(".dcp-topic-preview--rich")
      .hasAttribute("href", "/t/fast-moving-technology/201")
      .hasAttribute("aria-label", "A fast-moving technology discussion");
    assert
      .dom(".dcp-topic-preview__media img")
      .hasAttribute("src", "/uploads/default/original/1X/popular-preview.png");
    assert
      .dom(".dcp-topic-preview__excerpt")
      .includesText("A bounded topic summary remains visible");
    assert.dom(".dcp-topic-preview__more").exists();
  });
});
