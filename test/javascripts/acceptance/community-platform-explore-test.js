import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | explore page", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/community-platform/feeds/explore.json", () => {
      return helper.response({
        order: "explore",
        personalized: false,
        recommended_communities: [
          {
            id: 12,
            name: "Research",
            slug: "research",
            path: "/s/research",
            description: "A community for active research discussions.",
            members_count: 84,
            icon_emoji: "🔬",
            icon_url: "/uploads/default/original/1X/research-logo.png",
            banner_color: "334455",
            recent_topics_count: 6,
          },
        ],
        recommended_people: [
          {
            id: 41,
            username: "ada",
            name: "Ada Lovelace",
            path: "/u/ada",
            avatar_template: "/user_avatar/example.com/ada/{size}/41_2.png",
            recent_public_topics_count: 3,
          },
        ],
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
            excerpt:
              "Explore cards also show a bounded first-post preview when the topic has no image.",
            image_url: null,
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

  test("renders community branding, people, and rich topic discovery surfaces", async function (assert) {
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
    assert.dom(".dcp-explore-community-card").exists({ count: 1 });
    assert
      .dom(".dcp-explore-community-card")
      .hasAttribute("href", "/s/research");
    assert.dom(".dcp-explore-community-card__top strong").hasText("s/research");
    assert
      .dom(".dcp-explore-community-card__icon img")
      .hasAttribute("src", "/uploads/default/original/1X/research-logo.png");
    assert
      .dom(".dcp-explore-community-card__meta")
      .includesText("6 active topics");
    assert.dom(".dcp-explore-person-card").exists({ count: 1 });
    assert.dom(".dcp-explore-person-card").hasAttribute("href", "/u/ada");
    assert.dom(".dcp-explore-person-card__identity strong").hasText("@ada");
    assert.dom(".dcp-explore-person-card").includesText("3 recent public topics");
    assert.dom(".dcp-explore-card").exists({ count: 1 });
    assert
      .dom(".dcp-explore-card .dcp-popular-card__community")
      .includesText("s/science")
      .hasAttribute("href", "/s/science");
    assert
      .dom(".dcp-explore-card .dcp-popular-card__title")
      .hasText("Discover a new community discussion")
      .hasAttribute("href", "/t/discover-new-community/301");
    assert
      .dom(".dcp-explore-card .dcp-topic-preview--excerpt")
      .includesText("Explore cards also show a bounded first-post preview");
  });
});
