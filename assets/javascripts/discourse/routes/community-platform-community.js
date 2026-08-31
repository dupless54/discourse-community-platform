import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class CommunityPlatformCommunityRoute extends DiscourseRoute {
  async model(params) {
    const slug = encodeURIComponent(params.slug);
    const payload = await ajax(`/community-platform/communities/${slug}.json`);
    const feedPayload = await ajax(
      `/community-platform/communities/${slug}/topics.json?order=hot`
    );

    return {
      community: payload.community,
      topics: feedPayload.topics || [],
      order: feedPayload.order || "hot",
    };
  }

  titleToken() {
    return this.currentModel?.community?.name;
  }
}
