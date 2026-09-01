import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

function communityPayload() {
  return {
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
  };
}

function topicPayload(order = "hot", score = 9, userVote = 0) {
  return {
    community: { id: 1, slug: "technology" },
    order,
    topics: [
      {
        id: 101,
        slug: "future-of-computing",
        path: "/t/future-of-computing/101",
        title:
          order === "new"
            ? "Newest computing topic"
            : "The future of computing",
        posts_count: 8,
        views: 120,
        like_count: 19,
        score,
        upvotes: Math.max(score, 0),
        downvotes: 0,
        user_vote: userVote,
      },
    ],
  };
}

acceptance("Community Platform | community page", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/community-platform/communities/technology.json", () => {
      return helper.response(communityPayload());
    });

    server.get(
      "/community-platform/communities/technology/topics.json",
      (request) => helper.response(topicPayload(request.queryParams.order || "hot"))
    );
  });

  test("renders ranked community topics and changes feed order", async function (assert) {
    await visit("/s/technology");

    assert.dom(".dcp-community-title-wrap h1").hasText("Technology");
    assert.dom(".dcp-community-slug").hasText("s/technology");
    assert.dom(".dcp-topic-card").exists({ count: 1 });
    assert
      .dom(".dcp-topic-card__title")
      .hasText("The future of computing")
      .hasAttribute("href", "/t/future-of-computing/101");
    assert.dom(".dcp-topic-vote__score").hasText("9");
    assert.dom(".dcp-rules-list li").exists({ count: 2 });
    assert.dom(".dcp-management-card").doesNotExist();
    assert.dom(".dcp-automod-card").doesNotExist();
    assert.dom(".dcp-vote-button").doesNotExist();

    await click('.dcp-feed-order__button:nth-child(2)');

    assert.dom(".dcp-topic-card__title").hasText("Newest computing topic");
    assert
      .dom('.dcp-feed-order__button:nth-child(2)')
      .hasAttribute("aria-pressed", "true");
  });
});

acceptance("Community Platform | voting", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/community-platform/communities/technology.json", () => {
      return helper.response(communityPayload());
    });

    server.get(
      "/community-platform/communities/technology/topics.json",
      () => helper.response(topicPayload("hot", 9, 0))
    );

    server.put("/community-platform/topics/101/vote.json", () => {
      return helper.response({
        vote: {
          topic_id: 101,
          community_id: 1,
          score: 10,
          upvotes: 10,
          downvotes: 0,
          user_vote: 1,
        },
      });
    });
  });

  test("shows voting controls to authenticated users and casts an upvote", async function (assert) {
    await visit("/s/technology");

    assert.dom(".dcp-vote-button").exists({ count: 2 });

    await click(".dcp-vote-button--up");

    assert.dom(".dcp-topic-vote__score").hasText("9");
  });
});

acceptance("Community Platform | AutoModerator management", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/community-platform/communities/technology.json", () => {
      const payload = communityPayload();
      payload.community.can_manage = true;
      payload.community.is_owner = true;
      return helper.response(payload);
    });

    server.get(
      "/community-platform/communities/technology/topics.json",
      () => helper.response(topicPayload())
    );

    server.get(
      "/community-platform/communities/technology/automod-rules.json",
      () =>
        helper.response({
          automod_rules: [
            {
              id: 1,
              name: "Spam phrases",
              enabled: true,
              match_mode: "any",
              terms: ["buy now", "telegram"],
            },
          ],
        })
    );

    server.get(
      "/community-platform/communities/technology/automod-executions.json",
      () =>
        helper.response({
          automod_executions: [
            {
              id: 10,
              post_id: 101,
              post_url: "/t/future-of-computing/101/1",
              username: "spammer",
              rule_name: "Spam phrases",
              trigger: "edit",
              outcome: "queued_for_review",
              created_at: "2026-09-01T14:30:00.000Z",
            },
          ],
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
            terms: ["guaranteed profit"],
          },
        })
    );
  });

  test("renders manager-only rules, audit history, and adds a rule", async function (assert) {
    await visit("/s/technology");

    assert.dom(".dcp-automod-card").exists();
    assert.dom(".dcp-automod-rule").exists({ count: 1 });
    assert.dom(".dcp-automod-rule").includesText("Spam phrases");
    assert.dom(".dcp-automod-terms").includesText("telegram");
    assert.dom("[data-test-automod-execution]").exists({ count: 1 });
    assert.dom(".dcp-automod-history").includesText("Spam phrases");
    assert.dom(".dcp-automod-history").includesText("@spammer");
    assert
      .dom(".dcp-automod-execution__meta a")
      .hasAttribute("href", "/t/future-of-computing/101/1");

    await fillIn(".dcp-automod-form input", "Scam links");
    await fillIn(".dcp-automod-form textarea", "guaranteed profit");
    await click(".dcp-automod-add");

    assert.dom(".dcp-automod-rule").exists({ count: 2 });
    assert.dom(".dcp-automod-rules").includesText("Scam links");
  });
});
