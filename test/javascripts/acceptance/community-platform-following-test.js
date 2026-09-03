import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

function followingPayload() {
  return {
    order: "following",
    personalized: true,
    login_required: false,
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
        id: 401,
        title: "Newest post from someone I follow",
        slug: "followed-post",
        path: "/t/followed-post/401",
        posts_count: 5,
        views: 90,
        like_count: 8,
        score: 3,
        upvotes: 4,
        downvotes: 1,
        user_vote: 0,
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
        id: 402,
        title: "A post from my joined community",
        slug: "joined-post",
        path: "/t/joined-post/402",
        posts_count: 7,
        views: 130,
        like_count: 10,
        score: 5,
        upvotes: 6,
        downvotes: 1,
        user_vote: 0,
        feed_source: "joined",
        community: {
          id: 4,
          name: "Hardware",
          slug: "hardware",
          path: "/c/hardware/4",
        },
      },
    ],
  };
}

acceptance("Community Platform | Following page", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/following.json", () => {
      return helper.response(followingPayload());
    });
  });

  test("renders only joined and followed personal sources", async function (assert) {
    await visit("/following");

    assert.dom(".dcp-feed-navigation").exists();
    assert.dom('[data-feed="home"]').hasAttribute("href", "/");
    assert
      .dom('[data-feed="following"]')
      .hasClass("active")
      .hasAttribute("href", "/following");
    assert.dom('[data-feed="popular"]').hasAttribute("href", "/popular");
    assert.dom(".dcp-home-hero h1").hasText("Following");
    assert.dom(".dcp-home-popular-link").doesNotExist();
    assert.dom(".dcp-home-card").exists({ count: 2 });
    assert
      .dom(".dcp-home-card:first-child .dcp-home-card__source")
      .hasText("Following");
    assert
      .dom(".dcp-home-card:first-child .dcp-topic-context__author")
      .hasText("@followed-user")
      .hasAttribute("href", "/u/followed-user");
    assert
      .dom(".dcp-home-card:first-child .dcp-feed-community-identity")
      .hasText("Development")
      .hasAttribute("href", "/c/development/9");
    assert
      .dom(".dcp-home-card:nth-child(2) .dcp-home-card__source")
      .hasText("Joined");
    assert.dom(".dcp-home-card__source--popular").doesNotExist();
  });
});

acceptance("Community Platform | guest Following page", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/following.json", () => {
      return helper.response({
        order: "following",
        personalized: false,
        login_required: true,
        joined_communities: [],
        topics: [],
      });
    });
  });

  test("renders a login state without leaking personalized content", async function (assert) {
    await visit("/following");

    assert.dom(".dcp-feed-navigation").exists();
    assert.dom('[data-feed="home"]').hasAttribute("href", "/");
    assert.dom('[data-feed="following"]').hasClass("active");
    assert.dom(".dcp-home-hero h1").hasText("Following");
    assert.dom(".dcp-home-card").doesNotExist();
    assert.dom(".dcp-home-empty h2").hasText("Log in to view Following");
    assert
      .dom(".dcp-home-empty .btn-primary")
      .hasText("Log in")
      .hasAttribute("href", "/login");
    assert.dom(".dcp-home-popular-link").doesNotExist();
  });
});
