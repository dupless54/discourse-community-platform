import Component from "@glimmer/component";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import bodyClass from "discourse/helpers/body-class";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class NativeCategoryCommunity extends Component {
  @tracked community = null;
  @tracked membershipBusy = false;
  @tracked errorMessage = null;

  constructor(owner, args) {
    super(owner, args);

    if (args.community) {
      this.community = args.community;
    } else {
      void this.loadCommunity();
    }
  }

  get communityInitial() {
    return this.community?.name?.charAt(0).toUpperCase() || "C";
  }

  get bannerStyle() {
    const color = this.community?.banner_color || "0088CC";
    return htmlSafe(`--dcp-community-banner: #${color}`);
  }

  get visibilityLabel() {
    return i18n(
      `community_platform.visibility.${this.community?.visibility || "public"}`
    );
  }

  @action
  async join() {
    await this.updateMembership("POST");
  }

  @action
  async leave() {
    await this.updateMembership("DELETE");
  }

  async loadCommunity() {
    const categoryId = this.args.category?.id;
    if (!categoryId) {
      return;
    }

    try {
      const response = await ajax(
        `/community-platform/categories/${categoryId}/community.json`
      );
      this.community = response.community;
    } catch {
      // Ordinary Discourse categories intentionally have no Community mapping.
      // The native category page should remain unchanged in that case.
    }
  }

  async updateMembership(type) {
    if (!this.community || this.membershipBusy) {
      return;
    }

    this.membershipBusy = true;
    this.errorMessage = null;

    try {
      const response = await ajax(
        `/community-platform/communities/${encodeURIComponent(this.community.slug)}/join.json`,
        { type }
      );
      this.community = response.community;
    } catch {
      this.errorMessage = i18n("community_platform.membership_error");
    } finally {
      this.membershipBusy = false;
    }
  }

  <template>
    {{#if this.community}}
      {{bodyClass "dcp-native-community-page"}}

      <div
        class="dcp-native-community"
        data-community-id={{this.community.id}}
        data-category-id={{this.community.category_id}}
      >
        <section class="dcp-community-hero" style={{this.bannerStyle}}>
          <div class="dcp-community-hero__banner">
            {{#if this.community.banner_url}}
              <img
                class="dcp-community-hero__banner-image"
                src={{this.community.banner_url}}
                alt=""
              />
            {{/if}}
          </div>

          <div class="dcp-community-hero__content">
            <div class="dcp-community-identity">
              <div class="dcp-community-icon" aria-hidden="true">
                {{#if this.community.icon_url}}
                  <img src={{this.community.icon_url}} alt="" />
                {{else if this.community.icon_emoji}}
                  <span>{{this.community.icon_emoji}}</span>
                {{else}}
                  <span>{{this.communityInitial}}</span>
                {{/if}}
              </div>

              <div class="dcp-community-title-wrap">
                <p class="dcp-community-slug">{{this.visibilityLabel}}</p>
                <h1>{{this.community.name}}</h1>
                {{#if this.community.description}}
                  <p class="dcp-community-description">
                    {{this.community.description}}
                  </p>
                {{/if}}
              </div>
            </div>

            <div class="dcp-community-actions">
              {{#if this.community.can_join}}
                <button
                  type="button"
                  class="btn btn-primary dcp-community-action"
                  disabled={{this.membershipBusy}}
                  {{on "click" this.join}}
                >
                  {{i18n "community_platform.join"}}
                </button>
              {{else if this.community.can_leave}}
                <button
                  type="button"
                  class="btn btn-default dcp-community-action"
                  disabled={{this.membershipBusy}}
                  {{on "click" this.leave}}
                >
                  {{i18n "community_platform.leave"}}
                </button>
              {{else if this.community.is_member}}
                <span class="dcp-community-member-state">
                  {{i18n "community_platform.joined"}}
                </span>
              {{/if}}
            </div>
          </div>
        </section>

        {{#if this.errorMessage}}
          <div class="alert alert-error dcp-community-feedback" role="alert">
            {{this.errorMessage}}
          </div>
        {{/if}}

        <div class="dcp-native-community__details">
          <section class="dcp-sidebar-card dcp-native-community__about">
            <p class="dcp-eyebrow">{{i18n "community_platform.about"}}</p>
            <dl class="dcp-community-facts">
              <div>
                <dt>{{i18n "community_platform.owner"}}</dt>
                <dd>@{{this.community.owner_username}}</dd>
              </div>
              <div>
                <dt>{{i18n "community_platform.visibility_label"}}</dt>
                <dd>{{this.visibilityLabel}}</dd>
              </div>
              <div>
                <dt>{{i18n "community_platform.members"}}</dt>
                <dd>{{this.community.members_count}}</dd>
              </div>
            </dl>
          </section>

          <section class="dcp-sidebar-card dcp-native-community__rules">
            <div class="dcp-section-heading dcp-section-heading--compact">
              <div>
                <p class="dcp-eyebrow">
                  {{i18n "community_platform.rules.eyebrow"}}
                </p>
                <h2>{{i18n "community_platform.rules.title"}}</h2>
              </div>
            </div>

            <ol class="dcp-rules-list">
              {{#each this.community.rules as |rule|}}
                <li>{{rule}}</li>
              {{else}}
                <li class="dcp-rules-list__empty">
                  {{i18n "community_platform.rules.empty"}}
                </li>
              {{/each}}
            </ol>
          </section>
        </div>
      </div>
    {{/if}}
  </template>
}
