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
        path: "/s/hardware",
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
          path: "/s/hardware",
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
        excerpt: "This excerpt is hidden because the topic has an image.",
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
          path: "/s/development",
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
          path: "/s/gaming",
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

  test("renders joined, followed, popular, and rich preview sources and allows voting", async function (assert) {
    await visit("/home");

    assert.dom(".dcp-feed-navigation").exists();
    assert.dom('[data-feed="home"]').hasClass("active").hasAttribute("href", "/home");
    assert.dom('[data-feed="following"]').hasAttribute("href", "/following");
    assert.dom('[data-feed="popular"]').hasAttribute("href", "/popular");
    assert.dom(".dcp-home-hero h1").hasText("Home");
    assert
      .dom(".dcp-home-community-chip")
      .hasText("s/hardware")
      .hasAttribute("href", "/s/hardware");
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
      .dom(".dcp-home-card:nth-child(2) .dcp-home-card__source")
      .hasText("Following");
    assert
      .dom(".dcp-home-card:nth-child(2) .dcp-home-card__author")
      .hasText("@followed-user")
      .hasAttribute("href", "/u/followed-user");
    assert
      .dom(".dcp-home-card:nth-child(2) .dcp-topic-preview--image img")
      .hasAttribute("src", "/uploads/default/original/1X/followed-preview.png");
    assert
      .dom(".dcp-home-card:nth-child(2) .dcp-topic-preview--excerpt")
      .doesNotExist();
    assert
      .dom(".dcp-home-card:nth-child(3) .dcp-home-card__source")
      .hasText("Popular");
    assert
      .dom(".dcp-home-card:nth-child(3) .dcp-topic-preview")
      .doesNotExist();

    await click(".dcp-home-card:first-child .dcp-vote-button--up");

    assert.dom(".dcp-home-card:first-child .dcp-home-card__score").hasText("8");
    assert
      .dom(".dcp-home-card:first-child .dcp-vote-button--up")
      .hasAttribute("aria-pressed", "true");
  });
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
    assert.dom('[data-feed="home"]').hasClass("active");
    assert.dom(".dcp-home-card").exists({ count: 1 });
    assert.dom(".dcp-home-community-chip").doesNotExist();
    assert.dom(".dcp-vote-button").doesNotExist();
    assert.dom(".dcp-home-card__source").hasText("Popular");
  });
});
