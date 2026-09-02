import PlatformShell from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/platform-shell";
import PopularPage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/popular-page";

export default <template>
  <PlatformShell
    @section="popular"
    @trendingTopics={{@controller.model.trendingTopics}}
  >
    <PopularPage @topics={{@controller.model.topics}} />
  </PlatformShell>
</template>;
