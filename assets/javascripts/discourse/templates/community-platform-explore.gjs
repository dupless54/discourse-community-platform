import ExplorePage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/explore-page";

export default <template>
  <ExplorePage
    @topics={{@controller.model.topics}}
    @recommendedCommunities={{@controller.model.recommendedCommunities}}
    @recommendedPeople={{@controller.model.recommendedPeople}}
    @personalized={{@controller.model.personalized}}
  />
</template>;
