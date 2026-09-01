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

    if (payload.community?.can_manage) {
      try {
        const [rulesPayload, executionsPayload] = await Promise.all([
          ajax(`/community-platform/communities/${slug}/automod-rules.json`),
          ajax(
            `/community-platform/communities/${slug}/automod-executions.json`
          ),
        ]);
        automodRules = rulesPayload.automod_rules || [];
        automodExecutions = executionsPayload.automod_executions || [];
      } catch {
        automodRules = [];
        automodExecutions = [];
      }
    }

    return {
      community: payload.community,
      topics: feedPayload.topics || [],
      order: feedPayload.order || "hot",
      automodRules,
      automodExecutions,
    };
  }

  titleToken() {
    return this.currentModel?.community?.name;
  }
}
