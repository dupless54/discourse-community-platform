import HomePage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/home-page";
import PlatformShell from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/platform-shell";

export default <template>
  <PlatformShell
    @section="following"
    @communities={{@controller.model.joinedCommunities}}
    @trendingTopics={{@controller.model.trendingTopics}}
    @sidebarHeadingKey="community_platform.home.joined_title"
  >
    <HomePage
      @topics={{@controller.model.topics}}
      @joinedCommunities={{@controller.model.joinedCommunities}}
      @personalized={{@controller.model.personalized}}
      @loginRequired={{@controller.model.loginRequired}}
      @feedVariant="following"
    />
  </PlatformShell>
</template>
