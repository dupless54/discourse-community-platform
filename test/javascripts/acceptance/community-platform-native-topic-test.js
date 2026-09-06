import { click, currentURL, settled, visit } from "@ember/test-helpers";
import { test } from "qunit";
import DiscoveryFixtures from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance(
  "Community Platform | native Topic Community context",
  function (needs) {
    let mappedCommunity;

    needs.hooks.beforeEach(() => {
      mappedCommunity = true;
    });

    needs.site({
      categories: [
        {
          id: 2,
          name: "Technology",
          slug: "technology",
          permission: null,
        },
      ],
    });

    needs.pretender((server, helper) => {
      server.get("/c/technology/2/l/latest.json", () => {
        return helper.response(
          DiscoveryFixtures["/latest_can_create_topic.json"]
        );
      });

      server.get("/community-platform/categories/2/community.json", () => {
        if (!mappedCommunity) {
          return helper.response(404, {});
        }

        return helper.response({
          community: {
            id: 1,
            name: "Technology",
            slug: "technology",
            description: "Technology discussions",
            visibility: "public",
            members_count: 42,
            category_id: 2,
            category_url: "/c/technology/2",
            owner_username: "owner",
            rules: ["Be respectful"],
            icon_emoji: "💻",
            icon_url: "/uploads/default/original/1X/community-logo.png",
            banner_color: "112233",
            banner_url: null,
            is_member: false,
            can_join: true,
            can_leave: false,
            can_manage: false,
          },
        });
      });
    });

    test("adds Community context without replacing the native Topic renderer", async function (assert) {
      await visit("/t/internationalization-localization/280/1");

      assert.dom("[data-test-topic-community-context]").exists();
      assert
        .dom(".dcp-topic-community-context__name")
        .hasText("Technology")
        .hasAttribute("href", "/c/technology/2");
      assert
        .dom(".dcp-topic-community-context__description")
        .hasText("Technology discussions");
      assert
        .dom(".dcp-topic-community-context__meta")
        .includesText("Public")
        .includesText("42 members");

      assert.dom("#topic").exists("the native Topic renderer remains mounted");
      assert
        .dom("#topic .cooked")
        .exists("the native Discourse Post Stream remains visible");
    });

    test("leaves an unmapped native Topic unchanged", async function (assert) {
      mappedCommunity = false;

      await visit("/t/internationalization-localization/280/1");

      assert.dom("[data-test-topic-community-context]").doesNotExist();
      assert.dom("#topic").exists();
      assert.dom("#topic .cooked").exists();
    });

    test("restores the correct Community surface across browser back and forward", async function (assert) {
      await visit("/t/internationalization-localization/280/1");

      assert.dom(".dcp-native-community").doesNotExist();
      assert.dom("[data-test-topic-community-context]").exists();
      assert.dom("#topic .cooked").exists();

      await click(".dcp-topic-community-context__name");

      assert.true(currentURL().startsWith("/c/technology/2"));
      assert.dom(".dcp-native-community").exists();
      assert.dom("[data-test-topic-community-context]").doesNotExist();

      window.history.back();
      await settled();

      assert.strictEqual(
        currentURL(),
        "/t/internationalization-localization/280/1"
      );
      assert.dom(".dcp-native-community").doesNotExist();
      assert.dom("[data-test-topic-community-context]").exists();
      assert.dom("#topic .cooked").exists();

      window.history.forward();
      await settled();

      assert.true(currentURL().startsWith("/c/technology/2"));
      assert.dom(".dcp-native-community").exists();
      assert.dom("[data-test-topic-community-context]").doesNotExist();
    });
  }
);
