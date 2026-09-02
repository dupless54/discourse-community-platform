import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";

acceptance("Community Platform | feed order accessibility", function (needs) {
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
          rules: [],
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
      () => helper.response({ community: { id: 1, slug: "technology" }, order: "hot", topics: [] })
    );
  });

  test("exposes the order controls as one named pressed-state group", async function (assert) {
    await visit("/s/technology");

    assert
      .dom(".dcp-feed-order")
      .hasAttribute("role", "group")
      .hasAttribute("aria-label", i18n("community_platform.feed.eyebrow"));
    assert.dom(".dcp-feed-order__button").exists({ count: 4 });
    assert
      .dom('.dcp-feed-order__button:nth-child(1)')
      .hasAttribute("aria-pressed", "true");
    assert
      .dom('.dcp-feed-order__button:nth-child(2)')
      .hasAttribute("aria-pressed", "false");
  });
});
