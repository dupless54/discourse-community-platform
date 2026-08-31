import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class CommunityPlatformCommunityRoute extends DiscourseRoute {
  async model(params) {
    const payload = await ajax(
      `/community-platform/communities/${encodeURIComponent(params.slug)}.json`
    );
    const community = payload.community;
    const categoryPayload = await ajax(`${community.category_url}.json`);

    return {
      community,
      topics: categoryPayload.topic_list?.topics || [],
    };
  }

  titleToken() {
    return this.currentModel?.community?.name;
  }
}
