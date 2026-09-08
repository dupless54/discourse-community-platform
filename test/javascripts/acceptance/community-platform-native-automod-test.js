import { click, fillIn, select, visit } from "@ember/test-helpers";
import { test } from "qunit";
import DiscoveryFixtures from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance(
  "Community Platform | native Category AutoModerator",
  function (needs) {
    needs.user();

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
      server.get("/c/technology/7/l/latest.json", () => {
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
                new_topics: 0,
                posts: 0,
                replies: 0,
                active_topics: 0,
                contributors: 0,
              },
              last_30_days: {
                new_topics: 0,
                posts: 0,
                replies: 0,
                active_topics: 0,
                contributors: 0,
              },
            },
          })
      );

      server.post(
        "/community-platform/communities/technology/automod-rules.json",
        () =>
          helper.response(201, {
            automod_rule: {
              id: 2,
              name: "Scam links",
              enabled: true,
              match_mode: "any",
              target: "all_posts",
              action: "queue_for_review",
              max_account_age_days: 7,
              max_trust_level: 0,
              terms: ["guaranteed profit"],
            },
          })
      );
    });

    test("creates an AutoModerator rule from the native Category manager surface", async function (assert) {
      await visit("/c/technology/7");

      assert
        .dom("[data-test-community-activity-insights]")
        .hasAttribute(
          "aria-labelledby",
          "dcp-community-activity-insights-title"
        );
      assert
        .dom("[data-test-moderation-insights]")
        .hasAttribute("aria-labelledby", "dcp-moderation-insights-title");
      assert
        .dom("[data-test-automod-region]")
        .hasAttribute("role", "region")
        .hasAttribute("aria-label", "AutoModerator");

      await fillIn('.dcp-automod-form input[type="text"]', "Scam links");
      await fillIn("[data-test-automod-max-account-age]", "7");
      await select("[data-test-automod-max-trust-level]", "0");
      await fillIn(".dcp-automod-form textarea", "guaranteed profit");
      await click(".dcp-automod-add");

      assert.dom(".dcp-automod-rule").exists({ count: 1 });
      assert.dom(".dcp-automod-rule").includesText("Scam links");
      assert
        .dom(".dcp-automod-rule")
        .includesText("Maximum account age: 7 days");
      assert.dom(".dcp-automod-rule").includesText("Maximum trust level: TL0");
    });
  }
);
