import Component from "@glimmer/component";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import AutomodPanel from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/automod-panel";
import CommunityActivityInsights from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-activity-insights";
import ModerationInsights from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/moderation-insights";
import { i18n } from "discourse-i18n";

export default class NativeCategoryManagerTools extends Component {
  @tracked automodRules = [];
  @tracked automodExecutions = [];
  @tracked moderationInsights = null;
  @tracked activityAnalytics = null;
  @tracked loaded = false;

  constructor(owner, args) {
    super(owner, args);
    void this.load();
  }

  @action
  communityChanged() {
    this.automodRules = [];
    this.automodExecutions = [];
    this.moderationInsights = null;
    this.activityAnalytics = null;
    this.loaded = false;
    void this.load();
  }

  async load() {
    const communitySlug = this.args.community?.slug;
    if (!communitySlug) {
      this.loaded = true;
      return;
    }

    const slug = encodeURIComponent(communitySlug);
    const [rules, executions, insights, analytics] = await Promise.all([
      this.safeFetch(
        `/community-platform/communities/${slug}/automod-rules.json`
      ),
      this.safeFetch(
        `/community-platform/communities/${slug}/automod-executions.json`
      ),
      this.safeFetch(
        `/community-platform/communities/${slug}/moderation-insights.json`
      ),
      this.safeFetch(
        `/community-platform/communities/${slug}/activity-analytics.json`
      ),
    ]);

    if (this.args.community?.slug !== communitySlug) {
      return;
    }

    this.automodRules = rules?.automod_rules || [];
    this.automodExecutions = executions?.automod_executions || [];
    this.moderationInsights = insights?.moderation_insights || null;
    this.activityAnalytics = analytics?.community_activity_analytics || null;
    this.loaded = true;
  }

  async safeFetch(path) {
    try {
      return await ajax(path);
    } catch {
      return null;
    }
  }

  <template>
    <div {{didUpdate this.communityChanged @community.slug}}>
      {{#if this.loaded}}
        <div
          class="dcp-native-community-manager-tools dcp-automod-page-panel"
          data-test-native-community-manager-tools
        >
          {{#if this.activityAnalytics}}
            <CommunityActivityInsights @analytics={{this.activityAnalytics}} />
          {{/if}}

          {{#if this.moderationInsights}}
            <ModerationInsights @insights={{this.moderationInsights}} />
          {{/if}}

          <div
            role="region"
            aria-label={{i18n "community_platform.automod.title"}}
            data-test-automod-region
          >
            <AutomodPanel
              @community={{@community}}
              @rules={{this.automodRules}}
              @executions={{this.automodExecutions}}
            />
          </div>
        </div>
      {{/if}}
    </div>
  </template>
}
