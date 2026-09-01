import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformCommunityActivityInsights extends Component {
  get ready() {
    return this.args.analytics?.status === "ready";
  }

  get sevenDays() {
    return this.args.analytics?.last_7_days || {};
  }

  get thirtyDays() {
    return this.args.analytics?.last_30_days || {};
  }

  <template>
    <section
      class="dcp-sidebar-card dcp-community-activity-insights"
      data-test-community-activity-insights
    >
      <div class="dcp-section-heading dcp-section-heading--compact">
        <div>
          <p class="dcp-eyebrow">
            {{i18n "community_platform.community_activity_insights.eyebrow"}}
          </p>
          <h2>{{i18n "community_platform.community_activity_insights.title"}}</h2>
        </div>
      </div>

      {{#if this.ready}}
        <p class="dcp-community-activity-insights__description">
          {{i18n "community_platform.community_activity_insights.description"}}
        </p>

        <div class="dcp-community-activity-insights__table">
          <div class="dcp-community-activity-insights__row dcp-community-activity-insights__row--header">
            <span></span>
            <strong>{{i18n "community_platform.community_activity_insights.window_7d"}}</strong>
            <strong>{{i18n "community_platform.community_activity_insights.window_30d"}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row">
            <span>{{i18n "community_platform.community_activity_insights.new_topics"}}</span>
            <strong>{{this.sevenDays.new_topics}}</strong>
            <strong>{{this.thirtyDays.new_topics}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row">
            <span>{{i18n "community_platform.community_activity_insights.posts"}}</span>
            <strong>{{this.sevenDays.posts}}</strong>
            <strong>{{this.thirtyDays.posts}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row">
            <span>{{i18n "community_platform.community_activity_insights.replies"}}</span>
            <strong>{{this.sevenDays.replies}}</strong>
            <strong>{{this.thirtyDays.replies}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row">
            <span>{{i18n "community_platform.community_activity_insights.active_topics"}}</span>
            <strong>{{this.sevenDays.active_topics}}</strong>
            <strong>{{this.thirtyDays.active_topics}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row">
            <span>{{i18n "community_platform.community_activity_insights.contributors"}}</span>
            <strong>{{this.sevenDays.contributors}}</strong>
            <strong>{{this.thirtyDays.contributors}}</strong>
          </div>
        </div>
      {{else}}
        <p class="dcp-community-activity-insights__warming">
          {{i18n "community_platform.community_activity_insights.warming"}}
        </p>
      {{/if}}
    </section>
  </template>
}
