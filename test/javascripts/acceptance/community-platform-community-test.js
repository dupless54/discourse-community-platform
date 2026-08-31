import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | community page", function (needs) {
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

    server.get("/c/technology/7.json", () => {
      return helper.response({
        topic_list: {
          topics: [
            {
              id: 101,
              slug: "future-of-computing",
              title: "The future of computing",
              posts_count: 8,
              views: 120,
              like_count: 19,
            },
          ],
        },
      });
    });
  });

  test("renders community metadata, rules, and real category topics", async function (assert) {
    await visit("/s/technology");

    assert.dom(".dcp-community-title-wrap h1").hasText("Technology");
    assert.dom(".dcp-community-slug").hasText("s/technology");
    assert.dom(".dcp-topic-card").exists({ count: 1 });
    assert
      .dom(".dcp-topic-card__title")
      .hasText("The future of computing")
      .hasAttribute("href", "/t/future-of-computing/101");
    assert.dom(".dcp-rules-list li").exists({ count: 2 });
    assert.dom(".dcp-management-card").doesNotExist();
  });
});
