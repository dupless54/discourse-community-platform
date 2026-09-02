import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

function topic(community) {
  return {
    id: 701,
    title: "A branded community discussion",
    slug: "branded-community-discussion",
    path: "/t/branded-community-discussion/701",
    posts_count: 5,
    views: 90,
    like_count: 8,
    score: 4,
    upvotes: 4,
    downvotes: 0,
    user_vote: 0,
    feed_source: "joined",
    created_at: "2026-09-01T12:00:00.000Z",
    author: {
      id: 42,
      username: "mert",
      name: "Mert Kaya",
      avatar_template: "/user_avatar/localhost/mert/{size}/42_2.png",
      path: "/u/mert",
    },
    community,
  };
}

acceptance("Community Platform | Home community identity", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    const community = {
      id: 17,
      name: "Hardware",
      slug: "hardware",
      path: "/s/hardware",
      icon_emoji: "🖥️",
      icon_url: "/uploads/default/original/1X/hardware-logo.png",
    };

    server.get("/community-platform/feeds/home.json", () => {
      return helper.response({
        order: "home",
        personalized: true,
        joined_communities: [community],
        topics: [topic(community)],
      });
    });
  });

  test("renders community, author, and time context in Home cards", async function (assert) {
    await visit("/home");

    assert
      .dom(".dcp-home-community-chip")
      .hasAttribute("href", "/s/hardware")
      .includesText("s/hardware");
    assert
      .dom(".dcp-home-community-chip .dcp-feed-community-identity__icon img")
      .hasAttribute("src", "/uploads/default/original/1X/hardware-logo.png");
    assert
      .dom(".dcp-home-card .dcp-feed-community-identity")
      .hasAttribute("href", "/s/hardware")
      .includesText("s/hardware");
    assert
      .dom(".dcp-home-card .dcp-feed-community-identity__icon img")
      .hasAttribute("src", "/uploads/default/original/1X/hardware-logo.png");
    assert
      .dom(".dcp-home-card .dcp-topic-context__author")
      .hasAttribute("href", "/u/mert")
      .includesText("@mert");
    assert.dom(".dcp-home-card .dcp-topic-context__author .avatar").exists();
    assert.dom(".dcp-home-card .dcp-topic-context__time").exists();
  });
});

acceptance("Community Platform | Popular community identity", function (needs) {
  needs.pretender((server, helper) => {
    const community = {
      id: 18,
      name: "Technology",
      slug: "technology",
      path: "/s/technology",
      icon_emoji: "💻",
      icon_url: "/uploads/default/original/1X/technology-logo.png",
    };

    server.get("/community-platform/feeds/popular.json", () => {
      return helper.response({
        order: "popular",
        topics: [topic(community)],
      });
    });
  });

  test("renders community, author, and time context in Popular cards", async function (assert) {
    await visit("/popular");

    assert
      .dom(".dcp-popular-card .dcp-feed-community-identity")
      .hasAttribute("href", "/s/technology")
      .includesText("s/technology");
    assert
      .dom(".dcp-popular-card .dcp-feed-community-identity__icon img")
      .hasAttribute("src", "/uploads/default/original/1X/technology-logo.png");
    assert
      .dom(".dcp-popular-card .dcp-topic-context__author")
      .hasAttribute("href", "/u/mert")
      .includesText("@mert");
    assert.dom(".dcp-popular-card .dcp-topic-context__author .avatar").exists();
    assert.dom(".dcp-popular-card .dcp-topic-context__time").exists();
  });
});
