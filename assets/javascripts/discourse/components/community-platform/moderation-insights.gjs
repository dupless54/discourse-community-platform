import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformModerationInsights extends Component {
  get sevenDays() {
    return this.args.insights?.last_7_days || {};
  }

  get thirtyDays() {
    return this.args.insights?.last_30_days || {};
  }

  get triggers() {
    return this.args.insights?.triggers_30_days || {};
  }

  get topRules() {
    return this.args.insights?.top_rules_30_days || [];
  }

  <template>
    <section
      class="dcp-sidebar-card dcp-moderation-insights"
      aria-labelledby="dcp-moderation-insights-title"
      data-test-moderation-insights
    >
      <div class="dcp-section-heading dcp-section-heading--compact">
        <div>
          <p class="dcp-eyebrow">{{i18n "community_platform.moderation_insights.eyebrow"}}</p>
          <h2 id="dcp-moderation-insights-title">
            {{i18n "community_platform.moderation_insights.title"}}
          </h2>
        </div>
      </div>

      <p class="dcp-moderation-insights__description">
        {{i18n "community_platform.moderation_insights.description"}}
      </p>

      <div class="dcp-moderation-insights__metrics">
        <article>
          <strong>{{this.sevenDays.executions}}</strong>
          <span>{{i18n "community_platform.moderation_insights.executions_7d"}}</span>
        </article>
        <article>
          <strong>{{this.sevenDays.unique_posts}}</strong>
          <span>{{i18n "community_platform.moderation_insights.unique_posts_7d"}}</span>
        </article>
        <article>
          <strong>{{this.thirtyDays.executions}}</strong>
          <span>{{i18n "community_platform.moderation_insights.executions_30d"}}</span>
        </article>
        <article>
          <strong>{{this.thirtyDays.flagged_for_review}}</strong>
          <span>{{i18n "community_platform.moderation_insights.standard_flags_30d"}}</span>
        </article>
      </div>

      <div class="dcp-moderation-insights__breakdown">
        <div>
          <h3>{{i18n "community_platform.moderation_insights.outcomes_title"}}</h3>
          <dl>
            <div>
              <dt>{{i18n "community_platform.automod.outcome_queued"}}</dt>
              <dd>{{this.thirtyDays.queued_for_review}}</dd>
            </div>
            <div>
              <dt>{{i18n "community_platform.automod.outcome_flagged"}}</dt>
              <dd>{{this.thirtyDays.flagged_for_review}}</dd>
            </div>
            <div>
              <dt>{{i18n "community_platform.automod.outcome_already_queued"}}</dt>
              <dd>{{this.thirtyDays.already_queued}}</dd>
            </div>
          </dl>
        </div>

        <div>
          <h3>{{i18n "community_platform.moderation_insights.triggers_title"}}</h3>
          <dl>
            <div>
              <dt>{{i18n "community_platform.automod.trigger_create"}}</dt>
              <dd>{{this.triggers.create}}</dd>
            </div>
            <div>
              <dt>{{i18n "community_platform.automod.trigger_edit"}}</dt>
              <dd>{{this.triggers.edit}}</dd>
            </div>
          </dl>
        </div>
      </div>

      <div class="dcp-moderation-insights__rules">
        <h3>{{i18n "community_platform.moderation_insights.top_rules_title"}}</h3>
        {{#each this.topRules as |rule|}}
          <div class="dcp-moderation-insights__rule">
            <span>{{rule.rule_name}}</span>
            <strong>{{rule.executions}}</strong>
          </div>
        {{else}}
          <p>{{i18n "community_platform.moderation_insights.no_activity"}}</p>
        {{/each}}
      </div>
    </section>
  </template>
}
