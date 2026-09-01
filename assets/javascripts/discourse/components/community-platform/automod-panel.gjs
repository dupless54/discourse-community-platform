import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformAutomodPanel extends Component {
  @tracked rules = [];
  @tracked name = "";
  @tracked termsText = "";
  @tracked matchMode = "any";
  @tracked saving = false;
  @tracked busyRuleId = null;
  @tracked errorMessage = null;

  constructor(owner, args) {
    super(owner, args);
    this.rules = args.rules || [];
  }

  @action
  updateName(event) {
    this.name = event.target.value;
  }

  @action
  updateTerms(event) {
    this.termsText = event.target.value;
  }

  @action
  updateMatchMode(event) {
    this.matchMode = event.target.value;
  }

  @action
  async createRule(event) {
    event.preventDefault();
    const terms = this.termsText
      .split(/\r?\n/)
      .map((term) => term.trim())
      .filter(Boolean);

    if (!this.name.trim() || terms.length === 0 || this.saving) {
      return;
    }

    this.saving = true;
    this.errorMessage = null;

    try {
      const response = await ajax(`${this.rulesUrl}.json`, {
        type: "POST",
        data: {
          automod_rule: {
            name: this.name.trim(),
            match_mode: this.matchMode,
            terms,
          },
        },
      });

      this.rules = [...this.rules, response.automod_rule];
      this.name = "";
      this.termsText = "";
      this.matchMode = "any";
    } catch {
      this.errorMessage = i18n("community_platform.automod.error");
    } finally {
      this.saving = false;
    }
  }

  @action
  async toggleRule(rule) {
    if (this.busyRuleId) {
      return;
    }

    this.busyRuleId = rule.id;
    this.errorMessage = null;

    try {
      const response = await ajax(`${this.rulesUrl}/${rule.id}.json`, {
        type: "PATCH",
        data: { automod_rule: { enabled: !rule.enabled } },
      });
      const updated = response.automod_rule;
      this.rules = this.rules.map((item) =>
        item.id === updated.id ? updated : item
      );
    } catch {
      this.errorMessage = i18n("community_platform.automod.error");
    } finally {
      this.busyRuleId = null;
    }
  }

  @action
  async deleteRule(rule) {
    if (this.busyRuleId) {
      return;
    }

    this.busyRuleId = rule.id;
    this.errorMessage = null;

    try {
      await ajax(`${this.rulesUrl}/${rule.id}.json`, { type: "DELETE" });
      this.rules = this.rules.filter((item) => item.id !== rule.id);
    } catch {
      this.errorMessage = i18n("community_platform.automod.error");
    } finally {
      this.busyRuleId = null;
    }
  }

  get rulesUrl() {
    return `/community-platform/communities/${encodeURIComponent(this.args.community.slug)}/automod-rules`;
  }

  <template>
    <section class="dcp-sidebar-card dcp-automod-card">
      <div class="dcp-section-heading dcp-section-heading--compact">
        <div>
          <p class="dcp-eyebrow">{{i18n "community_platform.automod.eyebrow"}}</p>
          <h2>{{i18n "community_platform.automod.title"}}</h2>
        </div>
      </div>

      <p class="dcp-automod-description">
        {{i18n "community_platform.automod.description"}}
      </p>

      {{#if this.errorMessage}}
        <p class="alert alert-error dcp-automod-error" role="alert">
          {{this.errorMessage}}
        </p>
      {{/if}}

      <div class="dcp-automod-rules">
        {{#each this.rules as |rule|}}
          <article class="dcp-automod-rule">
            <div class="dcp-automod-rule__heading">
              <strong>{{rule.name}}</strong>
              <span class="dcp-automod-rule__state">
                {{#if rule.enabled}}
                  {{i18n "community_platform.automod.enabled"}}
                {{else}}
                  {{i18n "community_platform.automod.disabled"}}
                {{/if}}
              </span>
            </div>

            <p class="dcp-automod-rule__mode">
              {{#if (eq rule.match_mode "all")}}
                {{i18n "community_platform.automod.match_all"}}
              {{else}}
                {{i18n "community_platform.automod.match_any"}}
              {{/if}}
            </p>

            <div class="dcp-automod-terms">
              {{#each rule.terms as |term|}}
                <span>{{term}}</span>
              {{/each}}
            </div>

            <div class="dcp-automod-rule__actions">
              <button
                type="button"
                class="btn btn-small btn-default"
                disabled={{this.busyRuleId}}
                {{on "click" (fn this.toggleRule rule)}}
              >
                {{#if rule.enabled}}
                  {{i18n "community_platform.automod.disable"}}
                {{else}}
                  {{i18n "community_platform.automod.enable"}}
                {{/if}}
              </button>
              <button
                type="button"
                class="btn btn-small btn-danger"
                disabled={{this.busyRuleId}}
                {{on "click" (fn this.deleteRule rule)}}
              >
                {{i18n "community_platform.automod.delete"}}
              </button>
            </div>
          </article>
        {{else}}
          <p class="dcp-automod-empty">
            {{i18n "community_platform.automod.empty"}}
          </p>
        {{/each}}
      </div>

      <form class="dcp-automod-form" {{on "submit" this.createRule}}>
        <label class="dcp-field">
          <span>{{i18n "community_platform.automod.name"}}</span>
          <input
            type="text"
            maxlength="80"
            value={{this.name}}
            {{on "input" this.updateName}}
          />
        </label>

        <label class="dcp-field">
          <span>{{i18n "community_platform.automod.match_mode"}}</span>
          <select value={{this.matchMode}} {{on "change" this.updateMatchMode}}>
            <option value="any">{{i18n "community_platform.automod.match_any"}}</option>
            <option value="all">{{i18n "community_platform.automod.match_all"}}</option>
          </select>
        </label>

        <label class="dcp-field">
          <span>{{i18n "community_platform.automod.terms"}}</span>
          <textarea
            rows="5"
            value={{this.termsText}}
            {{on "input" this.updateTerms}}
          ></textarea>
          <small>{{i18n "community_platform.automod.terms_hint"}}</small>
        </label>

        <button
          type="submit"
          class="btn btn-primary dcp-automod-add"
          disabled={{this.saving}}
        >
          {{#if this.saving}}
            {{i18n "community_platform.automod.saving"}}
          {{else}}
            {{i18n "community_platform.automod.add"}}
          {{/if}}
        </button>
      </form>
    </section>
  </template>
}
