import CommunityPage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-page";

export default <template>
  <CommunityPage
    @community={{@controller.model.community}}
    @topics={{@controller.model.topics}}
  />
</template>;
