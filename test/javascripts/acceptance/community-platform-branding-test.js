import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Community Platform | rich community branding", function (needs) {
  needs.user();

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
          owner_id: 1,
          member_group_id: 11,
          moderator_group_id: 12,
          rules: [],
          icon_emoji: "💻",
          banner_color: "0088CC",
          icon_upload_id: 501,
          banner_upload_id: 502,
          created_at: "2026-09-02T00:00:00.000Z",
          path: "/s/technology",
          category_url: "/c/technology/7",
          owner_username: "owner",
          icon_url: "/uploads/default/original/1X/community-logo.png",
          banner_url: "/uploads/default/original/1X/community-cover.jpg",
          is_member: true,
          is_owner: true,
          is_moderator: true,
          can_join: false,
          can_leave: false,
          can_manage: true,
        },
      });
    });

    server.get(
      "/community-platform/communities/technology/topics.json",
      () =>
        helper.response({
          community: { id: 1, slug: "technology" },
          order: "hot",
          topics: [
            {
              id: 101,
              title: "A text-first community discussion",
              slug: "text-first-community-discussion",
              path: "/t/text-first-community-discussion/101",
              posts_count: 3,
              views: 88,
              like_count: 4,
              score: 6,
              upvotes: 6,
              downvotes: 0,
              user_vote: 0,
              excerpt:
                "The community feed now shows a short first-post preview when no image is available.",
              image_url: null,
            },
          ],
        })
    );

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
            last_7_days: {
              executions: 0,
              unique_posts: 0,
              queued_for_review: 0,
              flagged_for_review: 0,
              already_queued: 0,
            },
            last_30_days: {
              executions: 0,
              unique_posts: 0,
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
            status: "warming",
            generated_at: null,
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
  });

  test("renders saved logo, cover, upload controls, and a text preview", async function (assert) {
    await visit("/s/technology");

    assert
      .dom(".dcp-community-icon img")
      .hasAttribute("src", "/uploads/default/original/1X/community-logo.png");
    assert
      .dom(".dcp-community-hero__banner-image")
      .hasAttribute("src", "/uploads/default/original/1X/community-cover.jpg");
    assert.dom("#dcp-community-logo-uploader").exists().hasClass("has-image");
    assert.dom("#dcp-community-banner-uploader").exists().hasClass("has-image");
    assert.dom(".dcp-management-card").includesText("Community logo");
    assert.dom(".dcp-management-card").includesText("Cover image");
    assert
      .dom(".dcp-topic-preview--excerpt")
      .includesText("The community feed now shows a short first-post preview")
      .hasAttribute("href", "/t/text-first-community-discussion/101");
  });
});
