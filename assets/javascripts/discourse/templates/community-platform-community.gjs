import AutomodPanel from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/automod-panel";
import CommunityPage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-page";

export default <template>
  <CommunityPage
    @community={{@controller.model.community}}
    @topics={{@controller.model.topics}}
  />

  {{#if @controller.model.community.can_manage}}
    <div class="container dcp-automod-page-panel">
      <AutomodPanel
        @community={{@controller.model.community}}
        @rules={{@controller.model.automodRules}}
      />
    </div>
  {{/if}}
</template>;
