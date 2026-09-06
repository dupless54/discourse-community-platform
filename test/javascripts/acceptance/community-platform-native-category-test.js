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
          icon_url: null,
          banner_color: "112233",
          banner_url: null,
          is_member: true,
          can_join: false,
          can_leave: false,
          can_manage: true,
        },
      });
    });

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
          icon_url: null,
          banner_color: "334455",
          banner_url: null,
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
    assert.dom("[data-test-native-community-manager-tools]").exists();
    assert.dom("[data-test-community-activity-insights]").includesText("4");
    assert.dom("[data-test-moderation-insights]").exists();
    assert.dom(".dcp-automod-form").exists();

    await visit("/c/general");

    assert.dom(".dcp-native-community").doesNotExist();
    assert.dom("[data-test-native-community-manager-tools]").doesNotExist();
    assert.dom(".topic-list").exists();
    assert.dom(document.body).doesNotHaveClass("dcp-native-community-page");
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
    assert.dom("[data-test-native-community-manager-tools]").doesNotExist();
    assert.dom(".topic-list").exists();
    assert.dom(document.body).doesNotHaveClass("dcp-native-community-page");
  });
});
