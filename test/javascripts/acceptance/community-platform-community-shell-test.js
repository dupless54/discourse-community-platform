import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance(
  "Community Platform | community shell integration",
  function (needs) {
    needs.pretender((server, helper) => {
      server.get("/community-platform/communities/technology.json", () => {
        return helper.response({
          community: {
            id: 1,
            name: "Technology",
            slug: "technology",
            description: "Technology discussions",
            visibility: "public",
            members_count: 42,
            category_id: 7,
            owner_id: 10,
            member_group_id: 11,
            moderator_group_id: 12,
            rules: ["Be respectful", "No spam"],
            icon_emoji: "💻",
            banner_color: "0088CC",
            created_at: "2026-08-31T12:00:00.000Z",
            path: "/s/technology",
            category_url: "/c/technology/7",
            owner_username: "owner",
            icon_url: null,
            banner_url: null,
            is_member: false,
            is_owner: false,
            is_moderator: false,
            can_join: false,
            can_leave: false,
            can_manage: false,
          },
        });
      });

      server.get(
        "/community-platform/communities/technology/topics.json",
        () => {
          return helper.response({
            community: { id: 1, slug: "technology" },
            order: "hot",
            topics: [
              {
                id: 101,
                slug: "future-of-computing",
                path: "/t/future-of-computing/101",
                title: "The future of computing",
                posts_count: 8,
                views: 120,
                like_count: 19,
                score: 9,
                upvotes: 10,
                downvotes: 1,
                user_vote: 0,
                created_at: "2026-09-01T12:00:00.000Z",
                excerpt: "A bounded preview for the Community social feed.",
                image_url: null,
                author: {
                  id: 44,
                  username: "ada",
                  name: "Ada",
                  avatar_template:
                    "/letter_avatar_proxy/v4/letter/a/41988e/{size}.png",
                  path: "/u/ada",
                },
              },
            ],
          });
        }
      );
    });

    test("uses the platform social feed contract and preserves Community details", async function (assert) {
      await visit("/s/technology");

      assert
        .dom('.dcp-platform-shell[data-platform-section="community"]')
        .exists();
      assert.dom(".dcp-community-feed-card").exists({ count: 1 });
      assert
        .dom(".dcp-community-feed-card .dcp-topic-context__author")
        .hasText("@ada")
        .hasAttribute("href", "/u/ada");
      assert.dom(".dcp-community-feed-card .dcp-topic-context__time").exists();
      assert
        .dom(".dcp-community-feed-card .dcp-topic-preview--excerpt")
        .includesText("A bounded preview for the Community social feed")
        .hasAttribute("href", "/t/future-of-computing/101");
      assert
        .dom(".dcp-community-feed-card .dcp-feed-action--discussion")
        .includesText("8 posts")
        .hasAttribute("href", "/t/future-of-computing/101");
      assert
        .dom(".dcp-community-feed-card .dcp-feed-actions")
        .includesText("120 views")
        .includesText("19 likes");
      assert.dom(".dcp-community-sidebar").exists();
      assert.dom(".dcp-community-facts").includesText("42");
      assert.dom(".dcp-rules-list li").exists({ count: 2 });
    });
  }
);
