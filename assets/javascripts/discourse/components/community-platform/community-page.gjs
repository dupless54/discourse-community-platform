import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformCommunityPage extends Component {
  @tracked community;
  @tracked membershipBusy = false;
  @tracked saving = false;
  @tracked errorMessage = null;
  @tracked savedMessage = null;
  @tracked description = "";
  @tracked visibility = "public";
  @tracked iconEmoji = "";
  @tracked bannerColor = "";
  @tracked rulesText = "";

  constructor(owner, args) {
    super(owner, args);
    this.community = args.community;
    this.syncManagementForm();
  }

  get topics() {
    return (this.args.topics || []).map((topic) => ({
      ...topic,
      url: `/t/${topic.slug}/${topic.id}`,
    }));
  }

  get communityInitial() {
    return this.community.name?.charAt(0).toUpperCase() || "S";
  }

  get bannerStyle() {
    const color = this.community.banner_color || "0088CC";
    return htmlSafe(`--dcp-community-banner: #${color}`);
  }

  get visibilityLabel() {
    return i18n(
      `community_platform.visibility.${this.community.visibility || "public"}`
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

  @action
  updateDescription(event) {
    this.description = event.target.value;
  }

  @action
  updateVisibility(event) {
    this.visibility = event.target.value;
  }

  @action
  updateIconEmoji(event) {
    this.iconEmoji = event.target.value;
  }

  @action
  updateBannerColor(event) {
    this.bannerColor = event.target.value;
  }

  @action
  updateRules(event) {
    this.rulesText = event.target.value;
  }

  @action
  async saveManagement() {
    this.saving = true;
    this.errorMessage = null;
    this.savedMessage = null;

    try {
      const response = await ajax(
        `/community-platform/communities/${encodeURIComponent(this.community.slug)}.json`,
        {
          type: "PATCH",
          data: {
            community: {
              description: this.description,
              visibility: this.visibility,
              icon_emoji: this.iconEmoji,
              banner_color: this.bannerColor,
              rules: this.rulesText
                .split(/\r?\n/)
                .map((rule) => rule.trim())
                .filter(Boolean),
            },
          },
        }
      );

      this.community = response.community;
      this.syncManagementForm();
      this.savedMessage = i18n("community_platform.management.saved");
    } catch {
      this.errorMessage = i18n("community_platform.management.error");
    } finally {
      this.saving = false;
    }
  }

  async updateMembership(type) {
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

  syncManagementForm() {
    this.description = this.community.description || "";
    this.visibility = this.community.visibility || "public";
    this.iconEmoji = this.community.icon_emoji || "";
    this.bannerColor = this.community.banner_color || "";
    this.rulesText = (this.community.rules || []).join("\n");
  }

  <template>
    <div class="dcp-community-page container">
      <section class="dcp-community-hero" style={{this.bannerStyle}}>
        <div class="dcp-community-hero__banner"></div>
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
              <p class="dcp-community-slug">s/{{this.community.slug}}</p>
              <h1>{{this.community.name}}</h1>
              {{#if this.community.description}}
                <p class="dcp-community-description">{{this.community.description}}</p>
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

            <a class="btn btn-default" href={{this.community.category_url}}>
              {{i18n "community_platform.open_category"}}
            </a>
          </div>
        </div>
      </section>

      {{#if this.errorMessage}}
        <div class="alert alert-error dcp-community-feedback" role="alert">
          {{this.errorMessage}}
        </div>
      {{/if}}

      <div class="dcp-community-layout">
        <main class="dcp-community-main">
          <div class="dcp-section-heading">
            <div>
              <p class="dcp-eyebrow">{{i18n "community_platform.feed.eyebrow"}}</p>
              <h2>{{i18n "community_platform.feed.latest"}}</h2>
            </div>
            <span class="dcp-section-count">
              {{this.community.members_count}}
              {{i18n "community_platform.members"}}
            </span>
          </div>

          <div class="dcp-topic-feed">
            {{#each this.topics as |topic|}}
              <article class="dcp-topic-card">
                <a class="dcp-topic-card__title" href={{topic.url}}>
                  {{topic.title}}
                </a>
                <div class="dcp-topic-card__meta">
                  <span>{{topic.posts_count}} {{i18n "community_platform.posts"}}</span>
                  <span>{{topic.views}} {{i18n "community_platform.views"}}</span>
                  <span>{{topic.like_count}} {{i18n "community_platform.likes"}}</span>
                </div>
              </article>
            {{else}}
              <div class="dcp-empty-state">
                <h3>{{i18n "community_platform.feed.empty_title"}}</h3>
                <p>{{i18n "community_platform.feed.empty_description"}}</p>
                <a class="btn btn-primary" href={{this.community.category_url}}>
                  {{i18n "community_platform.feed.create_topic"}}
                </a>
              </div>
            {{/each}}
          </div>
        </main>

        <aside class="dcp-community-sidebar">
          <section class="dcp-sidebar-card">
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

          <section class="dcp-sidebar-card">
            <div class="dcp-section-heading dcp-section-heading--compact">
              <div>
                <p class="dcp-eyebrow">{{i18n "community_platform.rules.eyebrow"}}</p>
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

          {{#if this.community.can_manage}}
            <section class="dcp-sidebar-card dcp-management-card">
              <div class="dcp-section-heading dcp-section-heading--compact">
                <div>
                  <p class="dcp-eyebrow">{{i18n "community_platform.management.eyebrow"}}</p>
                  <h2>{{i18n "community_platform.management.title"}}</h2>
                </div>
              </div>

              <label class="dcp-field">
                <span>{{i18n "community_platform.management.description"}}</span>
                <textarea
                  rows="4"
                  maxlength="1000"
                  value={{this.description}}
                  {{on "input" this.updateDescription}}
                ></textarea>
              </label>

              <label class="dcp-field">
                <span>{{i18n "community_platform.management.visibility"}}</span>
                <select value={{this.visibility}} {{on "change" this.updateVisibility}}>
                  <option value="public">{{i18n "community_platform.visibility.public"}}</option>
                  <option value="restricted">{{i18n "community_platform.visibility.restricted"}}</option>
                  <option value="private">{{i18n "community_platform.visibility.private"}}</option>
                </select>
              </label>

              <div class="dcp-field-row">
                <label class="dcp-field">
                  <span>{{i18n "community_platform.management.icon"}}</span>
                  <input
                    type="text"
                    maxlength="64"
                    value={{this.iconEmoji}}
                    {{on "input" this.updateIconEmoji}}
                  />
                </label>

                <label class="dcp-field">
                  <span>{{i18n "community_platform.management.banner_color"}}</span>
                  <input
                    type="text"
                    maxlength="7"
                    placeholder="#0088CC"
                    value={{this.bannerColor}}
                    {{on "input" this.updateBannerColor}}
                  />
                </label>
              </div>

              <label class="dcp-field">
                <span>{{i18n "community_platform.management.rules"}}</span>
                <textarea
                  rows="6"
                  value={{this.rulesText}}
                  {{on "input" this.updateRules}}
                ></textarea>
                <small>{{i18n "community_platform.management.rules_hint"}}</small>
              </label>

              {{#if this.savedMessage}}
                <p class="dcp-save-success" role="status">{{this.savedMessage}}</p>
              {{/if}}

              <button
                type="button"
                class="btn btn-primary dcp-save-button"
                disabled={{this.saving}}
                {{on "click" this.saveManagement}}
              >
                {{#if this.saving}}
                  {{i18n "community_platform.management.saving"}}
                {{else}}
                  {{i18n "community_platform.management.save"}}
                {{/if}}
              </button>
            </section>
          {{/if}}
        </aside>
      </div>
    </div>
  </template>
}
