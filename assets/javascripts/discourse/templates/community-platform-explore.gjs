import ExplorePage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/explore-page";

export default <template>
  <ExplorePage
    @topics={{@controller.model.topics}}
    @personalized={{@controller.model.personalized}}
  />
</template>;
