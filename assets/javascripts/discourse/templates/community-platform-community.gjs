import AutomodPanel from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/automod-panel";
import CommunityActivityInsights from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-activity-insights";
import CommunityPage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-page";
import ModerationInsights from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/moderation-insights";
import PlatformShell from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/platform-shell";

export default <template>
  <PlatformShell
    @section="community"
    @currentCommunity={{@controller.model.community}}
  >
    <CommunityPage
      @community={{@controller.model.community}}
      @topics={{@controller.model.topics}}
    />

    {{#if @controller.model.community.can_manage}}
      <div class="container dcp-automod-page-panel">
        {{#if @controller.model.activityAnalytics}}
          <CommunityActivityInsights @analytics={{@controller.model.activityAnalytics}} />
        {{/if}}

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
  </PlatformShell>
</template>;
