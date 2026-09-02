import ExplorePage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/explore-page";
import PlatformShell from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/platform-shell";

export default <template>
  <PlatformShell
    @section="explore"
    @communities={{@controller.model.recommendedCommunities}}
    @sidebarHeadingKey="community_platform.explore.recommended_title"
  >
    <ExplorePage
      @topics={{@controller.model.topics}}
      @recommendedCommunities={{@controller.model.recommendedCommunities}}
      @recommendedPeople={{@controller.model.recommendedPeople}}
      @personalized={{@controller.model.personalized}}
    />
  </PlatformShell>
</template>;
