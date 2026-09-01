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
      aria-labelledby="dcp-community-activity-insights-title"
      data-test-community-activity-insights
    >
      <div class="dcp-section-heading dcp-section-heading--compact">
        <div>
          <p class="dcp-eyebrow">
            {{i18n "community_platform.community_activity_insights.eyebrow"}}
          </p>
          <h2 id="dcp-community-activity-insights-title">
            {{i18n "community_platform.community_activity_insights.title"}}
          </h2>
        </div>
      </div>

      {{#if this.ready}}
        <p class="dcp-community-activity-insights__description">
          {{i18n "community_platform.community_activity_insights.description"}}
        </p>

        <div
          class="dcp-community-activity-insights__table"
          role="table"
          aria-labelledby="dcp-community-activity-insights-title"
        >
          <div
            class="dcp-community-activity-insights__row dcp-community-activity-insights__row--header"
            role="row"
          >
            <span aria-hidden="true"></span>
            <strong role="columnheader">
              {{i18n "community_platform.community_activity_insights.window_7d"}}
            </strong>
            <strong role="columnheader">
              {{i18n "community_platform.community_activity_insights.window_30d"}}
            </strong>
          </div>

          <div class="dcp-community-activity-insights__row" role="row">
            <span role="rowheader">
              {{i18n "community_platform.community_activity_insights.new_topics"}}
            </span>
            <strong role="cell">{{this.sevenDays.new_topics}}</strong>
            <strong role="cell">{{this.thirtyDays.new_topics}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row" role="row">
            <span role="rowheader">
              {{i18n "community_platform.community_activity_insights.posts"}}
            </span>
            <strong role="cell">{{this.sevenDays.posts}}</strong>
            <strong role="cell">{{this.thirtyDays.posts}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row" role="row">
            <span role="rowheader">
              {{i18n "community_platform.community_activity_insights.replies"}}
            </span>
            <strong role="cell">{{this.sevenDays.replies}}</strong>
            <strong role="cell">{{this.thirtyDays.replies}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row" role="row">
            <span role="rowheader">
              {{i18n "community_platform.community_activity_insights.active_topics"}}
            </span>
            <strong role="cell">{{this.sevenDays.active_topics}}</strong>
            <strong role="cell">{{this.thirtyDays.active_topics}}</strong>
          </div>

          <div class="dcp-community-activity-insights__row" role="row">
            <span role="rowheader">
              {{i18n "community_platform.community_activity_insights.contributors"}}
            </span>
            <strong role="cell">{{this.sevenDays.contributors}}</strong>
            <strong role="cell">{{this.thirtyDays.contributors}}</strong>
          </div>
        </div>
      {{else}}
        <p class="dcp-community-activity-insights__warming" role="status">
          {{i18n "community_platform.community_activity_insights.warming"}}
        </p>
      {{/if}}
    </section>
  </template>
}
