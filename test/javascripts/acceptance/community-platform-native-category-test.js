import { click, fillIn, select, visit } from "@ember/test-helpers";
import { test } from "qunit";
import DiscoveryFixtures from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | native Category Community", function (needs) {
  needs.user();

  let lastTechnologyPatchBody;

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
      {
        id: 9,
        name: "Gaming",
        slug: "gaming",
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

    server.get("/c/gaming/9/l/latest.json", () => {
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
          icon_upload_id: 501,
          icon_url: "/uploads/default/original/1X/community-logo.png",
          banner_color: "112233",
          banner_upload_id: 502,
          banner_url: "/uploads/default/original/1X/community-cover.jpg",
          is_member: true,
          can_join: false,
          can_leave: false,
          can_manage: true,
        },
      });
    });

    server.patch(
      "/community-platform/communities/technology.json",
      (request) => {
        lastTechnologyPatchBody = new URLSearchParams(request.requestBody);

        return helper.response({
          community: {
            id: 1,
            name: "Technology",
            slug: "technology",
            description: "Updated native description",
            visibility: "restricted",
            members_count: 42,
            category_id: 7,
            category_url: "/c/technology/7",
            owner_username: "owner",
            rules: ["First native rule", "Second native rule"],
            icon_emoji: "🚀",
            icon_upload_id: 501,
            icon_url: "/uploads/default/original/1X/community-logo.png",
            banner_color: "445566",
            banner_upload_id: 502,
            banner_url: "/uploads/default/original/1X/community-cover.jpg",
            is_member: true,
            can_join: false,
            can_leave: false,
            can_manage: true,
          },
        });
      }
    );

    server.get("/community-platform/categories/9/community.json", () => {
      return helper.response({
        community: {
          id: 2,
          name: "Gaming",
          slug: "gaming",
          description: "Gaming discussions",
          visibility: "public",
          members_count: 21,
          category_id: 9,
          category_url: "/c/gaming/9",
          owner_username: "owner",
          rules: ["Keep spoilers tagged"],
          icon_emoji: "🎮",
          icon_upload_id: 601,
          icon_url: "/uploads/default/original/1X/gaming-logo.png",
          banner_color: "334455",
          banner_upload_id: 602,
          banner_url: "/uploads/default/original/1X/gaming-cover.jpg",
          is_member: true,
          can_join: false,
          can_leave: false,
          can_manage: true,
        },
      });
    });

    server.get(
      "/community-platform/communities/technology/automod-rules.json",
      () => helper.response({ automod_rules: [] })
    );

    server.get(
      "/community-platform/communities/technology/automod-executions.json",
      () => helper.response({ automod_executions: [] })
    );

    server.get(
      "/community-platform/communities/technology/moderation-insights.json",
      () =>
        helper.response({
          moderation_insights: {
            last_7_days: { executions: 0, unique_posts: 0 },
            last_30_days: {
              executions: 0,
              queued_for_review: 0,
              flagged_for_review: 0,
              already_queued: 0,
            },
            triggers_30_days: { create: 0, edit: 0 },
            top_rules_30_days: [],
          },
        })
    );

    server.get(
      "/community-platform/communities/technology/activity-analytics.json",
      () =>
        helper.response({
          community_activity_analytics: {
            status: "ready",
            last_7_days: {
              new_topics: 1,
              posts: 4,
              replies: 3,
              active_topics: 1,
              contributors: 2,
            },
            last_30_days: {
              new_topics: 5,
              posts: 18,
              replies: 13,
              active_topics: 4,
              contributors: 7,
            },
          },
        })
    );

    server.get(
      "/community-platform/communities/gaming/automod-rules.json",
      () => helper.response({ automod_rules: [] })
    );

    server.get(
      "/community-platform/communities/gaming/automod-executions.json",
      () => helper.response({ automod_executions: [] })
    );

    server.get(
      "/community-platform/communities/gaming/moderation-insights.json",
      () =>
        helper.response({
          moderation_insights: {
            last_7_days: { executions: 2, unique_posts: 2 },
            last_30_days: {
              executions: 6,
              queued_for_review: 3,
              flagged_for_review: 2,
              already_queued: 1,
            },
            triggers_30_days: { create: 4, edit: 2 },
            top_rules_30_days: [],
          },
        })
    );

    server.get(
      "/community-platform/communities/gaming/activity-analytics.json",
      () =>
        helper.response({
          community_activity_analytics: {
            status: "ready",
            last_7_days: {
              new_topics: 9,
              posts: 99,
              replies: 90,
              active_topics: 8,
              contributors: 15,
            },
            last_30_days: {
              new_topics: 30,
              posts: 240,
              replies: 210,
              active_topics: 24,
              contributors: 55,
            },
          },
        })
    );

    server.get("/community-platform/categories/8/community.json", () => {
      return helper.response(404, {});
    });
  });

  test("enriches a mapped Category and clears Community state on native navigation", async function (assert) {
    await visit("/c/technology");

    assert.dom(".dcp-native-community").exists();
    assert.dom(".dcp-community-title-wrap h1").hasText("Technology");
    assert.dom(".dcp-community-member-state").exists();
    assert.dom(".topic-list").exists();
    assert.dom(document.body).hasClass("dcp-native-community-page");
    assert.dom("[data-test-native-community-management]").exists();
    assert.dom("#dcp-native-community-logo-uploader").hasClass("has-image");
    assert.dom("#dcp-native-community-banner-uploader").hasClass("has-image");
    assert.dom("[data-test-native-community-manager-tools]").exists();
    assert.dom("[data-test-community-activity-insights]").includesText("4");
    assert.dom("[data-test-moderation-insights]").exists();
    assert.dom(".dcp-automod-form").exists();

    await visit("/c/general");

    assert.dom(".dcp-native-community").doesNotExist();
    assert.dom("[data-test-native-community-management]").doesNotExist();
    assert.dom("[data-test-native-community-manager-tools]").doesNotExist();
    assert.dom(".topic-list").exists();
    assert.dom(document.body).doesNotHaveClass("dcp-native-community-page");
  });

  test("saves native Community settings and refreshes the visible Community state", async function (assert) {
    lastTechnologyPatchBody = null;
    await visit("/c/technology");

    await fillIn(
      "[data-test-native-community-description]",
      "Updated native description"
    );
    await select("[data-test-native-community-visibility]", "restricted");
    await fillIn("[data-test-native-community-icon-emoji]", "🚀");
    await fillIn("[data-test-native-community-banner-color]", "445566");
    await fillIn(
      "[data-test-native-community-rules]",
      "First native rule\nSecond native rule"
    );
    await click("[data-test-native-community-save]");

    assert.ok(lastTechnologyPatchBody, "the manager PATCH request is sent");
    assert.strictEqual(
      lastTechnologyPatchBody.get("community[description]"),
      "Updated native description"
    );
    assert.strictEqual(
      lastTechnologyPatchBody.get("community[visibility]"),
      "restricted"
    );
    assert.strictEqual(
      lastTechnologyPatchBody.get("community[icon_emoji]"),
      "🚀"
    );
    assert.strictEqual(
      lastTechnologyPatchBody.get("community[banner_color]"),
      "445566"
    );
    assert.strictEqual(
      lastTechnologyPatchBody.get("community[icon_upload_id]"),
      "501",
      "the existing logo attachment remains in the PATCH contract"
    );
    assert.strictEqual(
      lastTechnologyPatchBody.get("community[banner_upload_id]"),
      "502",
      "the existing cover attachment remains in the PATCH contract"
    );
    assert.deepEqual(lastTechnologyPatchBody.getAll("community[rules][]"), [
      "First native rule",
      "Second native rule",
    ]);

    assert
      .dom(".dcp-community-description")
      .hasText("Updated native description");
    assert.dom(".dcp-community-slug").hasText("Restricted");
    assert.dom(".dcp-rules-list li").exists({ count: 2 });
    assert.dom(".dcp-rules-list li:first-child").hasText("First native rule");
    assert
      .dom("[data-test-native-community-management] [role='status']")
      .includesText("Community settings saved");
    assert.dom("#dcp-native-community-logo-uploader").hasClass("has-image");
    assert.dom("#dcp-native-community-banner-uploader").hasClass("has-image");
  });

  test("resets unsaved manager form state between mapped Categories", async function (assert) {
    await visit("/c/technology");

    await fillIn(
      "[data-test-native-community-description]",
      "Unsaved technology draft"
    );
    await fillIn(
      "[data-test-native-community-rules]",
      "Unsaved technology rule"
    );

    await visit("/c/gaming");

    assert.dom(".dcp-community-title-wrap h1").hasText("Gaming");
    assert
      .dom("[data-test-native-community-description]")
      .hasValue("Gaming discussions");
    assert
      .dom("[data-test-native-community-rules]")
      .hasValue("Keep spoilers tagged");
    assert.dom("[data-test-native-community-visibility]").hasValue("public");
    assert.dom("#dcp-native-community-logo-uploader").hasClass("has-image");
    assert.dom("#dcp-native-community-banner-uploader").hasClass("has-image");
  });

  test("reloads manager data when navigating between mapped Categories", async function (assert) {
    await visit("/c/technology");

    assert.dom(".dcp-community-title-wrap h1").hasText("Technology");
    assert.dom("[data-test-community-activity-insights]").includesText("4");

    await visit("/c/gaming");

    assert.dom(".dcp-community-title-wrap h1").hasText("Gaming");
    assert.dom("[data-test-native-community-manager-tools]").exists();
    assert.dom("[data-test-community-activity-insights]").includesText("99");
    assert.dom("[data-test-moderation-insights]").includesText("6");
  });

  test("leaves an ordinary native Category unchanged", async function (assert) {
    await visit("/c/general");

    assert.dom(".dcp-native-community").doesNotExist();
    assert.dom("[data-test-native-community-management]").doesNotExist();
    assert.dom("[data-test-native-community-manager-tools]").doesNotExist();
    assert.dom(".topic-list").exists();
    assert.dom(document.body).doesNotHaveClass("dcp-native-community-page");
  });
});
