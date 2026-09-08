import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import CommunityActivityInsights from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-activity-insights";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

module("Integration | Component | CommunityActivityInsights", function (hooks) {
  setupRenderingTest(hooks);

  test("exposes ready activity metrics with named table semantics", async function (assert) {
    this.analytics = {
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
    };

    await render(
      <template>
        <CommunityActivityInsights @analytics={{this.analytics}} />
      </template>
    );

    assert
      .dom("[data-test-community-activity-insights]")
      .hasAttribute("aria-labelledby", "dcp-community-activity-insights-title");
    assert
      .dom("#dcp-community-activity-insights-title")
      .hasText("Activity insights");
    assert
      .dom(".dcp-community-activity-insights__table")
      .hasAttribute("role", "table")
      .hasAttribute("aria-labelledby", "dcp-community-activity-insights-title")
      .includesText("New topics")
      .includesText("Posts")
      .includesText("Replies")
      .includesText("Active topics")
      .includesText("Contributors");
    assert.dom("[role='row']").exists({ count: 6 });
    assert.dom("[role='columnheader']").exists({ count: 2 });
    assert.dom("[role='rowheader']").exists({ count: 5 });
    assert.dom("[role='cell']").exists({ count: 10 });
  });

  test("exposes warming as a non-interactive status without a keyboard trap", async function (assert) {
    this.analytics = {
      status: "warming",
      last_7_days: {},
      last_30_days: {},
    };

    await render(
      <template>
        <button type="button" data-test-focus-sentinel>Keep keyboard focus</button>
        <CommunityActivityInsights @analytics={{this.analytics}} />
      </template>
    );

    const sentinel = document.querySelector("[data-test-focus-sentinel]");
    const warmingStatus = document.querySelector(
      ".dcp-community-activity-insights__warming"
    );
    sentinel.focus();

    assert.strictEqual(document.activeElement, sentinel);
    assert
      .dom(".dcp-community-activity-insights__warming")
      .hasAttribute("role", "status")
      .doesNotHaveAttribute("tabindex")
      .hasText(
        "Activity analytics are warming up. The next background rebuild will populate this panel."
      );
    assert.strictEqual(
      warmingStatus.querySelectorAll(
        "a, button, input, select, textarea, [tabindex]"
      ).length,
      0,
      "the asynchronous status introduces no keyboard targets"
    );
    assert.strictEqual(
      document.activeElement,
      sentinel,
      "rendering the warming status does not steal existing focus"
    );
    assert.dom(".dcp-community-activity-insights__table").doesNotExist();
  });
});
