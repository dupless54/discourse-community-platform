import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

function homePayload() {
  return {
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
    topics: [
      {
        id: 301,
        title: "A discussion from a joined community",
        slug: "joined-discussion",
        path: "/t/joined-discussion/301",
        posts_count: 9,
        views: 180,
        like_count: 12,
        score: 7,
        upvotes: 8,
        downvotes: 1,
        user_vote: 0,
        excerpt:
          "A bounded preview from the first post makes the feed useful before opening the full topic.",
        image_url: null,
        feed_source: "joined",
        community: {
          id: 4,
          name: "Hardware",
          slug: "hardware",
          path: "/c/hardware/4",
        },
      },
      {
        id: 303,
        title: "A discussion from someone I follow",
        slug: "followed-discussion",
        path: "/t/followed-discussion/303",
        posts_count: 6,
        views: 240,
        like_count: 18,
        score: 11,
        upvotes: 12,
        downvotes: 1,
        user_vote: 0,
        excerpt:
          "The image and this bounded summary are intentionally visible together.",
        image_url: "/uploads/default/original/1X/followed-preview.png",
        feed_source: "followed",
        author: {
          id: 44,
          username: "followed-user",
          name: "Followed User",
          path: "/u/followed-user",
        },
        community: {
          id: 9,
          name: "Development",
          slug: "development",
          path: "/c/development/9",
        },
      },
      {
        id: 302,
        title: "A popular fallback discussion",
        slug: "popular-fallback",
        path: "/t/popular-fallback/302",
        posts_count: 16,
        views: 560,
        like_count: 34,
        score: 19,
        upvotes: 21,
        downvotes: 2,
        user_vote: 0,
        excerpt: null,
        image_url: null,
        feed_source: "popular",
        community: {
          id: 8,
          name: "Gaming",
          slug: "gaming",
          path: "/c/gaming/8",
        },
      },
    ],
  };
}

acceptance("Community Platform | personalized home page", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/home.json", () => {
      return helper.response(homePayload());
    });

    server.put("/community-platform/topics/301/vote.json", () => {
      return helper.response({
        vote: {
          topic_id: 301,
          community_id: 4,
          score: 8,
          upvotes: 9,
          downvotes: 1,
          user_vote: 1,
        },
      });
    });
  });

  test(
    "renders native category links, combined rich previews, and voting",
    async function (assert) {
      await visit("/home");

      assert.dom(".dcp-feed-navigation").exists();
      assert.dom('[data-feed="home"]').hasAttribute("href", "/");
      assert.dom('[data-feed="following"]').hasAttribute("href", "/following");
      assert.dom('[data-feed="popular"]').hasAttribute("href", "/popular");
      assert.dom(".dcp-home-hero h1").hasText("Home");
      assert
        .dom(".dcp-home-community-chip")
        .includesText("Hardware")
        .hasAttribute("href", "/c/hardware/4");
      assert.dom(".dcp-home-card").exists({ count: 3 });
      assert
        .dom(".dcp-home-card:first-child .dcp-home-card__title")
        .hasText("A discussion from a joined community")
        .hasAttribute("href", "/t/joined-discussion/301");
      assert
        .dom(".dcp-home-card:first-child .dcp-home-card__source")
        .hasText("Joined");
      assert
        .dom(".dcp-home-card:first-child .dcp-topic-preview--excerpt")
        .includesText("A bounded preview from the first post")
        .hasAttribute("href", "/t/joined-discussion/301");
      assert
        .dom(".dcp-home-card:first-child .dcp-feed-action--discussion")
        .includesText("9 posts")
        .hasAttribute("href", "/t/joined-discussion/301");
      assert
        .dom(".dcp-home-card:first-child .dcp-feed-actions")
        .includesText("180 views")
        .includesText("12 likes");
      assert
        .dom(".dcp-home-card:nth-child(2) .dcp-home-card__source")
        .hasText("Following");
      assert
        .dom(".dcp-home-card:nth-child(2) .dcp-topic-context__author")
        .hasText("@followed-user")
        .hasAttribute("href", "/u/followed-user");
      assert
        .dom(".dcp-home-card:nth-child(2) .dcp-topic-preview--rich")
        .hasAttribute("href", "/t/followed-discussion/303");
      assert
        .dom(".dcp-home-card:nth-child(2) .dcp-topic-preview__media img")
        .hasAttribute("src", "/uploads/default/original/1X/followed-preview.png");
      assert
        .dom(".dcp-home-card:nth-child(2) .dcp-topic-preview__excerpt")
        .includesText("The image and this bounded summary");
      assert
        .dom(".dcp-home-card:nth-child(2) .dcp-topic-preview__more")
        .exists();
      assert
        .dom(".dcp-home-card:nth-child(3) .dcp-home-card__source")
        .hasText("Popular");
      assert
        .dom(".dcp-home-card:nth-child(3) .dcp-topic-preview")
        .doesNotExist();

      await click(".dcp-home-card:first-child .dcp-vote-button--up");

      assert
        .dom(".dcp-home-card:first-child .dcp-home-card__score")
        .hasText("8");
      assert
        .dom(".dcp-home-card:first-child .dcp-vote-button--up")
        .hasAttribute("aria-pressed", "true");
    }
  );
});

acceptance("Community Platform | guest home page", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/home.json", () => {
      return helper.response({
        order: "home",
        personalized: false,
        joined_communities: [],
        topics: [homePayload().topics[2]],
      });
    });
  });

  test("renders the public fallback without authenticated vote controls", async function (assert) {
    await visit("/home");

    assert.dom(".dcp-feed-navigation").exists();
    assert.dom('[data-feed="home"]').hasAttribute("href", "/");
    assert.dom(".dcp-home-card").exists({ count: 1 });
    assert.dom(".dcp-home-community-chip").doesNotExist();
    assert.dom(".dcp-vote-button").doesNotExist();
    assert.dom(".dcp-home-card__source").hasText("Popular");
  });
});
