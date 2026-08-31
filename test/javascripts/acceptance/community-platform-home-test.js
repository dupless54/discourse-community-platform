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
        feed_source: "joined",
        community: {
          id: 4,
          name: "Hardware",
          slug: "hardware",
          path: "/s/hardware",
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

  test("renders joined communities first and allows voting from the home feed", async function (assert) {
    await visit("/home");

    assert.dom(".dcp-home-hero h1").hasText("Home");
    assert
      .dom(".dcp-home-community-chip")
      .hasText("s/hardware")
      .hasAttribute("href", "/s/hardware");
    assert.dom(".dcp-home-card").exists({ count: 2 });
    assert
      .dom(".dcp-home-card:first-child .dcp-home-card__title")
      .hasText("A discussion from a joined community")
      .hasAttribute("href", "/t/joined-discussion/301");
    assert
      .dom(".dcp-home-card:first-child .dcp-home-card__source")
      .hasText("Joined");
    assert
      .dom(".dcp-home-card:nth-child(2) .dcp-home-card__source")
      .hasText("Popular");

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
        topics: [homePayload().topics[1]],
      });
    });
  });

  test("renders the public fallback without authenticated vote controls", async function (assert) {
    await visit("/home");

    assert.dom(".dcp-home-card").exists({ count: 1 });
    assert.dom(".dcp-home-community-chip").doesNotExist();
    assert.dom(".dcp-vote-button").doesNotExist();
    assert.dom(".dcp-home-card__source").hasText("Popular");
  });
});
