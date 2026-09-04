import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import NativeCategoryCommunity from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/native-category-community";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

module("Integration | Component | NativeCategoryCommunity", function (hooks) {
  setupRenderingTest(hooks);

  test("renders Community identity on the native Category surface", async function (assert) {
    this.category = { id: 7 };
    this.community = {
      id: 1,
      name: "Technology",
      slug: "technology",
      description: "Technology discussions",
      visibility: "public",
      members_count: 42,
      category_id: 7,
      category_url: "/c/technology/7",
      owner_username: "owner",
      rules: ["Be respectful", "No spam"],
      icon_emoji: null,
      icon_url: "/uploads/default/original/1X/community-logo.png",
      banner_color: "112233",
      banner_url: "/uploads/default/original/1X/community-cover.jpg",
      is_member: false,
      can_join: true,
      can_leave: false,
    };

    await render(
      <template>
        <NativeCategoryCommunity
          @category={{this.category}}
          @community={{this.community}}
        />
      </template>
    );

    assert
      .dom(".dcp-native-community")
      .hasAttribute(
        "data-category-id",
        "7",
        "the native Category id is retained"
      );
    assert.dom(".dcp-community-title-wrap h1").hasText("Technology");
    assert.dom(".dcp-community-slug").hasText("Public");
    assert.dom(".dcp-community-description").hasText("Technology discussions");
    assert
      .dom(".dcp-community-icon img")
      .hasAttribute("src", "/uploads/default/original/1X/community-logo.png");
    assert
      .dom(".dcp-community-hero__banner-image")
      .hasAttribute("src", "/uploads/default/original/1X/community-cover.jpg");
    assert.dom(".dcp-community-action").hasText("Join");
    assert.dom(".dcp-rules-list li").exists({ count: 2 });
    assert.dom(".dcp-rules-list li:first-child").hasText("Be respectful");
    assert.dom(document.body).hasClass("dcp-native-community-page");
  });
});
