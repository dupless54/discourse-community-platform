import ExplorePage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/explore-page";
import PlatformShell from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/platform-shell";

export default <template>
  <PlatformShell
    @section="explore"
    @trendingTopics={{@controller.model.trendingTopics}}
    @recommendedCommunities={{@controller.model.recommendedCommunities}}
    @recommendedPeople={{@controller.model.recommendedPeople}}
  >
    <ExplorePage
      @topics={{@controller.model.topics}}
      @personalized={{@controller.model.personalized}}
    />
  </PlatformShell>
</template>
