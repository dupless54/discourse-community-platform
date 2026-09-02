import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformExploreRoute extends DiscourseRoute {
  async model() {
    const payload = await ajax("/community-platform/feeds/explore.json");

    return {
      topics: payload.topics || [],
      recommendedCommunities: payload.recommended_communities || [],
      recommendedPeople: payload.recommended_people || [],
      trendingTopics: payload.trending_topics || [],
      order: payload.order || "explore",
      personalized: payload.personalized || false,
    };
  }

  titleToken() {
    return i18n("community_platform.explore.title");
  }
}
