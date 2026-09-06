import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class CommunityPlatformCommunityRoute extends DiscourseRoute {
  @service router;

  async model(params) {
    const slug = encodeURIComponent(params.slug);
    const payload = await ajax(`/community-platform/communities/${slug}.json`);

    return payload.community;
  }

  redirect(community) {
    if (community?.category_url) {
      return this.router.replaceWith(community.category_url);
    }
  }
}
