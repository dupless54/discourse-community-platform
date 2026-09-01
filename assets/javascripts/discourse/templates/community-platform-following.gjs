import HomePage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/home-page";

export default <template>
  <HomePage
    @topics={{@controller.model.topics}}
    @joinedCommunities={{@controller.model.joinedCommunities}}
    @personalized={{@controller.model.personalized}}
    @loginRequired={{@controller.model.loginRequired}}
    @feedVariant="following"
  />
</template>;
