import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformTopicPreview extends Component {
  <template>
    {{#if @topic.image_url}}
      <a
        class="dcp-topic-preview dcp-topic-preview--rich"
        href={{@topic.path}}
        aria-label={{@topic.title}}
      >
        <span class="dcp-topic-preview__media">
          <img src={{@topic.image_url}} alt="" loading="lazy" />
        </span>
        {{#if @topic.excerpt}}
          <span class="dcp-topic-preview__body">
            <span class="dcp-topic-preview__excerpt">{{@topic.excerpt}}</span>
            <span class="dcp-topic-preview__more">
              {{i18n "community_platform.read_more"}}
            </span>
          </span>
        {{/if}}
      </a>
    {{else if @topic.excerpt}}
      <a
        class="dcp-topic-preview dcp-topic-preview--excerpt"
        href={{@topic.path}}
      >
        <span class="dcp-topic-preview__excerpt">{{@topic.excerpt}}</span>
        <span class="dcp-topic-preview__more">
          {{i18n "community_platform.read_more"}}
        </span>
      </a>
    {{/if}}
  </template>
}
