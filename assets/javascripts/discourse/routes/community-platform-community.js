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

    if (payload.community?.can_manage) {
      try {
        const automodPayload = await ajax(
          `/community-platform/communities/${slug}/automod-rules.json`
        );
        automodRules = automodPayload.automod_rules || [];
      } catch {
        automodRules = [];
      }
    }

    return {
      community: payload.community,
      topics: feedPayload.topics || [],
      order: feedPayload.order || "hot",
      automodRules,
    };
  }

  titleToken() {
    return this.currentModel?.community?.name;
  }
}
