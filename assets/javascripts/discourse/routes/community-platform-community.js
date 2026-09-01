import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class CommunityPlatformCommunityRoute extends DiscourseRoute {
  async model(params) {
    const slug = encodeURIComponent(params.slug);
    const payload = await ajax(`/community-platform/communities/${slug}.json`);
    const feedPayload = await ajax(
      `/community-platform/communities/${slug}/topics.json?order=hot`
    );
    let automodRules = [];
    let automodExecutions = [];
    let moderationInsights = null;
    let activityAnalytics = null;

    if (payload.community?.can_manage) {
      try {
        const automodPayload = await ajax(
          `/community-platform/communities/${slug}/automod-rules.json`
        );
        automodRules = automodPayload.automod_rules || [];
      } catch {
        automodRules = [];
      }

      try {
        const executionsPayload = await ajax(
          `/community-platform/communities/${slug}/automod-executions.json`
        );
        automodExecutions = executionsPayload.automod_executions || [];
      } catch {
        automodExecutions = [];
      }

      try {
        const insightsPayload = await ajax(
          `/community-platform/communities/${slug}/moderation-insights.json`
        );
        moderationInsights = insightsPayload.moderation_insights || null;
      } catch {
        moderationInsights = null;
      }

      try {
        const analyticsPayload = await ajax(
          `/community-platform/communities/${slug}/activity-analytics.json`
        );
        activityAnalytics =
          analyticsPayload.community_activity_analytics || null;
      } catch {
        activityAnalytics = null;
      }
    }

    return {
      community: payload.community,
      topics: feedPayload.topics || [],
      order: feedPayload.order || "hot",
      automodRules,
      automodExecutions,
      moderationInsights,
      activityAnalytics,
    };
  }

  titleToken() {
    return this.currentModel?.community?.name;
  }
}
