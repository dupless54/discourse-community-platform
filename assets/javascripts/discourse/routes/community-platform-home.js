import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformHomeRoute extends DiscourseRoute {
  async model() {
    const payload = await ajax("/community-platform/feeds/home.json");

    return {
      topics: payload.topics || [],
      joinedCommunities: payload.joined_communities || [],
      personalized: payload.personalized || false,
      order: payload.order || "home",
    };
  }

  titleToken() {
    return i18n("community_platform.home.title");
  }
}
