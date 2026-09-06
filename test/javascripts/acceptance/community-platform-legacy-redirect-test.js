import { currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import DiscoveryFixtures from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

function visibleCommunity() {
  return {
    id: 1,
    name: "Technology",
    slug: "technology",
    description: "Technology discussions",
    visibility: "public",
    members_count: 42,
    category_id: 7,
    category_url: "/c/technology/7",
    owner_username: "owner",
    rules: ["Be respectful"],
    icon_emoji: "💻",
    icon_url: null,
    banner_color: "112233",
    banner_url: null,
    is_member: false,
    can_join: true,
    can_leave: false,
    can_manage: false,
  };
}

acceptance("Community Platform | legacy Community redirect", function (needs) {
  needs.site({
    categories: [
      {
        id: 7,
        name: "Technology",
        slug: "technology",
        permission: null,
      },
    ],
  });

  needs.pretender((server, helper) => {
    server.get("/community-platform/communities/technology.json", () => {
      return helper.response({ community: visibleCommunity() });
    });

    server.get("/c/technology/7/l/latest.json", () => {
      return helper.response(
        DiscoveryFixtures["/latest_can_create_topic.json"]
      );
    });

    server.get("/community-platform/categories/7/community.json", () => {
      return helper.response({ community: visibleCommunity() });
    });
  });

  test(
    "replaces an old /s URL with the native Category route",
    async function (assert) {
      await visit("/s/technology");

      assert.strictEqual(currentURL(), "/c/technology/7");
      assert.dom(".dcp-native-community").exists();
      assert.dom(".dcp-community-title-wrap h1").hasText("Technology");
    }
  );
});
