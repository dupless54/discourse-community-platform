import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformPopularRoute extends DiscourseRoute {
  async model() {
    const payload = await ajax("/community-platform/feeds/popular.json");

    return {
      topics: payload.topics || [],
      trendingTopics: payload.trending_topics || [],
      order: payload.order || "popular",
    };
  }

  titleToken() {
    return i18n("community_platform.popular.title");
  }
}
