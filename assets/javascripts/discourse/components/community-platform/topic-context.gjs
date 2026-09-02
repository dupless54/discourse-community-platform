import Component from "@glimmer/component";
import CommunityIdentity from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-identity";
import DRelativeDate from "discourse/ui-kit/d-relative-date";
import DUserAvatar from "discourse/ui-kit/d-user-avatar";

export default class CommunityPlatformTopicContext extends Component {
  <template>
    <div class="dcp-topic-context">
      {{#if @community}}
        <CommunityIdentity
          @community={{@community}}
          class="dcp-topic-context__community"
        />
      {{/if}}

      {{#if @topic.author}}
        {{#if @community}}
          <span class="dcp-topic-context__separator" aria-hidden="true">·</span>
        {{/if}}

        <a class="dcp-topic-context__author" href={{@topic.author.path}}>
          <DUserAvatar @user={{@topic.author}} @size="tiny" />
          <span>@{{@topic.author.username}}</span>
        </a>
      {{/if}}

      {{#if @topic.created_at}}
        <span class="dcp-topic-context__separator" aria-hidden="true">·</span>
        <span class="dcp-topic-context__time">
          <DRelativeDate @date={{@topic.created_at}} />
        </span>
      {{/if}}
    </div>
  </template>
}
