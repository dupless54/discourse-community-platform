import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { eq } from "discourse/truth-helpers";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformAutomodPanel extends Component {
  @tracked rules = [];
  @tracked executions = [];
  @tracked name = "";
  @tracked termsText = "";
  @tracked matchMode = "any";
  @tracked target = "all_posts";
  @tracked reviewAction = "queue_for_review";
  @tracked maxAccountAgeDays = "";
  @tracked maxTrustLevel = "";
  @tracked saving = false;
  @tracked busyRuleId = null;
  @tracked refreshingHistory = false;
  @tracked errorMessage = null;

  constructor(owner, args) {
    super(owner, args);
    this.rules = args.rules || [];
    this.executions = args.executions || [];
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
  updateTarget(event) {
    this.target = event.target.value;
  }

  @action
  updateReviewAction(event) {
    this.reviewAction = event.target.value;
  }

  @action
  updateMaxAccountAgeDays(event) {
    this.maxAccountAgeDays = event.target.value;
  }

  @action
  updateMaxTrustLevel(event) {
    this.maxTrustLevel = event.target.value;
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

    const rulePayload = {
      name: this.name.trim(),
      match_mode: this.matchMode,
      target: this.target,
      action: this.reviewAction,
      terms,
    };

    if (this.maxAccountAgeDays !== "") {
      rulePayload.max_account_age_days = Number(this.maxAccountAgeDays);
    }

    if (this.maxTrustLevel !== "") {
      rulePayload.max_trust_level = Number(this.maxTrustLevel);
    }

    this.saving = true;
    this.errorMessage = null;

    try {
      const response = await ajax(`${this.rulesUrl}.json`, {
        type: "POST",
        data: { automod_rule: rulePayload },
      });

      this.rules = [...this.rules, response.automod_rule];
      this.name = "";
      this.termsText = "";
      this.matchMode = "any";
      this.target = "all_posts";
      this.reviewAction = "queue_for_review";
      this.maxAccountAgeDays = "";
      this.maxTrustLevel = "";
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

  @action
  async refreshHistory() {
    if (this.refreshingHistory) {
      return;
    }

    this.refreshingHistory = true;
    this.errorMessage = null;

    try {
      const response = await ajax(`${this.executionsUrl}.json`);
      this.executions = response.automod_executions || [];
    } catch {
      this.errorMessage = i18n("community_platform.automod.error");
    } finally {
      this.refreshingHistory = false;
    }
  }

  get rulesUrl() {
    return `/community-platform/communities/${encodeURIComponent(this.args.community.slug)}/automod-rules`;
  }

  get executionsUrl() {
    return `/community-platform/communities/${encodeURIComponent(this.args.community.slug)}/automod-executions`;
  }

  <template>
    <section class="dcp-sidebar-card dcp-automod-card">
      <div class="dcp-section-heading dcp-section-heading--compact">
        <div>
          <p class="dcp-eyebrow">{{i18n
              "community_platform.automod.eyebrow"
            }}</p>
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
              ·
              {{#if (eq rule.target "topic_starters")}}
                {{i18n "community_platform.automod.target_topic_starters"}}
              {{else if (eq rule.target "replies")}}
                {{i18n "community_platform.automod.target_replies"}}
              {{else}}
                {{i18n "community_platform.automod.target_all_posts"}}
              {{/if}}
              ·
              {{#if (eq rule.action "flag_only")}}
                {{i18n "community_platform.automod.action_flag_only"}}
              {{else}}
                {{i18n "community_platform.automod.action_queue_for_review"}}
              {{/if}}
            </p>

            {{#if rule.max_account_age_days}}
              <p class="dcp-automod-rule__condition">
                {{i18n "community_platform.automod.condition_account_age"}}:
                {{rule.max_account_age_days}}
                {{i18n "community_platform.automod.days"}}
              </p>
            {{/if}}
            {{#if rule.max_trust_level}}
              <p class="dcp-automod-rule__condition">
                {{i18n "community_platform.automod.condition_max_trust_level"}}:
                TL{{rule.max_trust_level}}
              </p>
            {{else if (eq rule.max_trust_level 0)}}
              <p class="dcp-automod-rule__condition">
                {{i18n "community_platform.automod.condition_max_trust_level"}}:
                TL0
              </p>
            {{/if}}

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
            <option value="any">{{i18n
                "community_platform.automod.match_any"
              }}</option>
            <option value="all">{{i18n
                "community_platform.automod.match_all"
              }}</option>
          </select>
        </label>

        <label class="dcp-field">
          <span>{{i18n "community_platform.automod.target"}}</span>
          <select value={{this.target}} {{on "change" this.updateTarget}}>
            <option value="all_posts">{{i18n
                "community_platform.automod.target_all_posts"
              }}</option>
            <option value="topic_starters">{{i18n
                "community_platform.automod.target_topic_starters"
              }}</option>
            <option value="replies">{{i18n
                "community_platform.automod.target_replies"
              }}</option>
          </select>
        </label>

        <label class="dcp-field">
          <span>{{i18n "community_platform.automod.action"}}</span>
          <select
            value={{this.reviewAction}}
            {{on "change" this.updateReviewAction}}
          >
            <option value="queue_for_review">{{i18n
                "community_platform.automod.action_queue_for_review"
              }}</option>
            <option value="flag_only">{{i18n
                "community_platform.automod.action_flag_only"
              }}</option>
          </select>
        </label>

        <fieldset class="dcp-automod-conditions">
          <legend>{{i18n
              "community_platform.automod.author_conditions"
            }}</legend>
          <p>{{i18n "community_platform.automod.author_conditions_hint"}}</p>

          <label class="dcp-field">
            <span>{{i18n
                "community_platform.automod.max_account_age_days"
              }}</span>
            <input
              type="number"
              min="1"
              max="365"
              value={{this.maxAccountAgeDays}}
              data-test-automod-max-account-age
              {{on "input" this.updateMaxAccountAgeDays}}
            />
            <small>{{i18n
                "community_platform.automod.max_account_age_days_hint"
              }}</small>
          </label>

          <label class="dcp-field">
            <span>{{i18n "community_platform.automod.max_trust_level"}}</span>
            <select
              value={{this.maxTrustLevel}}
              data-test-automod-max-trust-level
              {{on "change" this.updateMaxTrustLevel}}
            >
              <option value="">{{i18n
                  "community_platform.automod.any_trust_level"
                }}</option>
              <option value="0">TL0</option>
              <option value="1">TL1</option>
              <option value="2">TL2</option>
              <option value="3">TL3</option>
              <option value="4">TL4</option>
            </select>
          </label>
        </fieldset>

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

      <div class="dcp-automod-history">
        <div class="dcp-automod-history__heading">
          <div>
            <h3>{{i18n "community_platform.automod.history_title"}}</h3>
            <p>{{i18n "community_platform.automod.history_description"}}</p>
          </div>
          <button
            type="button"
            class="btn btn-small btn-default"
            disabled={{this.refreshingHistory}}
            {{on "click" this.refreshHistory}}
          >
            {{#if this.refreshingHistory}}
              {{i18n "community_platform.automod.refreshing"}}
            {{else}}
              {{i18n "community_platform.automod.refresh"}}
            {{/if}}
          </button>
        </div>

        <div class="dcp-automod-history__list">
          {{#each this.executions as |execution|}}
            <article
              class="dcp-automod-execution"
              data-test-automod-execution={{execution.id}}
            >
              <div class="dcp-automod-execution__main">
                <strong>{{execution.rule_name}}</strong>
                <span>
                  {{#if (eq execution.trigger "edit")}}
                    {{i18n "community_platform.automod.trigger_edit"}}
                  {{else}}
                    {{i18n "community_platform.automod.trigger_create"}}
                  {{/if}}
                  ·
                  {{#if (eq execution.outcome "already_queued")}}
                    {{i18n "community_platform.automod.outcome_already_queued"}}
                  {{else if (eq execution.outcome "flagged_for_review")}}
                    {{i18n "community_platform.automod.outcome_flagged"}}
                  {{else}}
                    {{i18n "community_platform.automod.outcome_queued"}}
                  {{/if}}
                </span>
              </div>

              <div class="dcp-automod-execution__meta">
                {{#if execution.username}}
                  <span>@{{execution.username}}</span>
                {{/if}}
                <span>{{dFormatDate execution.created_at}}</span>
                {{#if execution.post_url}}
                  <a href={{execution.post_url}}>
                    {{i18n "community_platform.automod.open_post"}}
                  </a>
                {{/if}}
              </div>
            </article>
          {{else}}
            <p class="dcp-automod-empty">
              {{i18n "community_platform.automod.history_empty"}}
            </p>
          {{/each}}
        </div>
      </div>
    </section>
  </template>
}
