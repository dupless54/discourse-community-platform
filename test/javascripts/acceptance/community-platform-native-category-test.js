import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import DiscoveryFixtures from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | native Category Community", function (needs) {
  needs.user();

  needs.site({
    categories: [
      {
        id: 7,
        name: "Technology",
        slug: "technology",
        permission: null,
      },
      {
        id: 8,
        name: "General",
        slug: "general",
        permission: null,
      },
    ],
  });

  needs.pretender((server, helper) => {
    server.get("/c/technology/7/l/latest.json", () => {
      return helper.response(
        DiscoveryFixtures["/latest_can_create_topic.json"]
      );
    });

    server.get("/c/general/8/l/latest.json", () => {
      return helper.response(
        DiscoveryFixtures["/latest_can_create_topic.json"]
      );
    });

    server.get("/community-platform/categories/7/community.json", () => {
      return helper.response({
        community: {
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
        },
      });
    });

    server.get("/community-platform/categories/8/community.json", () => {
      return helper.response(404, {});
    });
  });

  test("enriches a mapped Category and clears Community state on native navigation", async function (assert) {
    await visit("/c/technology");

    assert.dom(".dcp-native-community").exists();
    assert.dom(".dcp-community-title-wrap h1").hasText("Technology");
    assert.dom(".dcp-community-action").hasText("Join");
    assert.dom(".topic-list").exists();
    assert.dom(document.body).hasClass("dcp-native-community-page");

    await visit("/c/general");

    assert.dom(".dcp-native-community").doesNotExist();
    assert.dom(".topic-list").exists();
    assert.dom(document.body).doesNotHaveClass("dcp-native-community-page");
  });

  test("leaves an ordinary native Category unchanged", async function (assert) {
    await visit("/c/general");

    assert.dom(".dcp-native-community").doesNotExist();
    assert.dom(".topic-list").exists();
    assert.dom(document.body).doesNotHaveClass("dcp-native-community-page");
  });
});
