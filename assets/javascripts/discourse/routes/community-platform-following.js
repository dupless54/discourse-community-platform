import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformFollowingRoute extends DiscourseRoute {
  async model() {
    const payload = await ajax("/community-platform/feeds/following.json");

    return {
      topics: payload.topics || [],
      joinedCommunities: payload.joined_communities || [],
      trendingTopics: payload.trending_topics || [],
      personalized: payload.personalized || false,
      loginRequired: payload.login_required || false,
      order: payload.order || "following",
    };
  }

  titleToken() {
    return i18n("community_platform.following.title");
  }
}
