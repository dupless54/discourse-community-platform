import Component from "@glimmer/component";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class TopicCommunityContext extends Component {
  @tracked community = null;

  constructor(owner, args) {
    super(owner, args);
    void this.loadCommunity();
  }

  get communityInitial() {
    return this.community?.name?.charAt(0).toUpperCase() || "C";
  }

  get visibilityLabel() {
    return i18n(
      `community_platform.visibility.${this.community?.visibility || "public"}`
    );
  }

  @action
  topicChanged() {
    this.community = null;
    void this.loadCommunity();
  }

  async loadCommunity() {
    const topicId = this.args.topic?.id;
    const categoryId = this.args.topic?.category_id;

    if (
      !topicId ||
      !categoryId ||
      this.args.topic?.archetype === "private_message"
    ) {
      return;
    }

    try {
      const response = await ajax(
        `/community-platform/categories/${categoryId}/community.json`
      );

      if (
        this.args.topic?.id === topicId &&
        this.args.topic?.category_id === categoryId
      ) {
        this.community = response.community;
      }
    } catch {
      // An unmapped or Guardian-invisible Category should leave the native
      // Discourse Topic page untouched.
      if (
        this.args.topic?.id === topicId &&
        this.args.topic?.category_id === categoryId
      ) {
        this.community = null;
      }
    }
  }

  <template>
    <div
      class="dcp-topic-community-context-mount"
      {{didUpdate this.topicChanged @topic.id @topic.category_id}}
    >
      {{#if this.community}}
        <div class="container dcp-topic-community-context-container">
          <aside
            class="dcp-topic-community-context"
            aria-label={{i18n "community_platform.about"}}
            data-test-topic-community-context
          >
            <div class="dcp-topic-community-context__identity">
              <span
                class="dcp-topic-community-context__icon"
                aria-hidden="true"
              >
                {{#if this.community.icon_url}}
                  <img src={{this.community.icon_url}} alt="" />
                {{else if this.community.icon_emoji}}
                  <span>{{this.community.icon_emoji}}</span>
                {{else}}
                  <span>{{this.communityInitial}}</span>
                {{/if}}
              </span>

              <div class="dcp-topic-community-context__copy">
                <p class="dcp-eyebrow">{{i18n "community_platform.about"}}</p>
                <a
                  class="dcp-topic-community-context__name"
                  href={{this.community.category_url}}
                >
                  {{this.community.name}}
                </a>
                {{#if this.community.description}}
                  <p class="dcp-topic-community-context__description">
                    {{this.community.description}}
                  </p>
                {{/if}}
              </div>
            </div>

            <div class="dcp-topic-community-context__meta">
              <span>{{this.visibilityLabel}}</span>
              <span>
                {{this.community.members_count}}
                {{i18n "community_platform.members"}}
              </span>
              <a
                class="btn btn-default btn-small dcp-topic-community-context__open"
                href={{this.community.category_url}}
              >
                {{i18n "community_platform.open_category"}}
              </a>
            </div>
          </aside>
        </div>
      {{/if}}
    </div>
  </template>
}
