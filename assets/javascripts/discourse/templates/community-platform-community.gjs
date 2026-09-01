import AutomodPanel from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/automod-panel";
import CommunityPage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-page";
import ModerationInsights from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/moderation-insights";

export default <template>
  <CommunityPage
    @community={{@controller.model.community}}
    @topics={{@controller.model.topics}}
  />

  {{#if @controller.model.community.can_manage}}
    <div class="container dcp-automod-page-panel">
      {{#if @controller.model.moderationInsights}}
        <ModerationInsights @insights={{@controller.model.moderationInsights}} />
      {{/if}}

      <AutomodPanel
        @community={{@controller.model.community}}
        @rules={{@controller.model.automodRules}}
        @executions={{@controller.model.automodExecutions}}
      />
    </div>
  {{/if}}
</template>;
