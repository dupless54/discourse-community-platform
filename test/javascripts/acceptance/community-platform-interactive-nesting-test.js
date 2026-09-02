import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const NESTED_INTERACTIVE_SELECTOR = [
  "a a",
  "a button",
  "a input",
  "a select",
  "a textarea",
  "button a",
  "button button",
  "button input",
  "button select",
  "button textarea",
].join(", ");

acceptance("Community Platform | interactive nesting", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    const community = {
      id: 4,
      name: "Hardware",
      slug: "hardware",
      path: "/s/hardware",
      icon_emoji: "🖥️",
      icon_url: null,
    };

    server.get("/community-platform/feeds/home.json", () => {
      return helper.response({
        order: "home",
        personalized: true,
        joined_communities: [community],
        trending_topics: [
          {
            id: 91,
            title: "A cached trending discussion",
            path: "/t/cached-trending-discussion/91",
            posts_count: 14,
            score: 23,
            community,
          },
        ],
        topics: [
          {
            id: 701,
            title: "A social feed discussion",
            slug: "social-feed-discussion",
            path: "/t/social-feed-discussion/701",
            posts_count: 5,
            views: 90,
            like_count: 8,
            score: 4,
            upvotes: 4,
            downvotes: 0,
            user_vote: 0,
            feed_source: "joined",
            created_at: "2026-09-01T12:00:00.000Z",
            excerpt: "A bounded visible excerpt for the regression surface.",
            author: {
              id: 42,
              username: "mert",
              name: "Mert Kaya",
              avatar_template: "/user_avatar/localhost/mert/{size}/42_2.png",
              path: "/u/mert",
            },
            community,
          },
        ],
      });
    });
  });

  test("keeps links and buttons as sibling controls throughout the shell", async function (assert) {
    await visit("/home");

    assert.dom(".dcp-platform-account__avatar").exists();
    assert.dom(".dcp-topic-context__author-avatar").exists();
    assert.dom(".dcp-vote-button").exists({ count: 2 });
    assert.dom(".dcp-topic-preview").exists();
    assert.dom(".dcp-feed-action--discussion").exists();
    assert.dom(".dcp-platform-right-rail a").exists();
    assert.dom(`.dcp-platform-shell ${NESTED_INTERACTIVE_SELECTOR}`).doesNotExist();
  });
});
