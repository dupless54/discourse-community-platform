import Component from "@glimmer/component";

export default class CommunityPlatformTopicPreview extends Component {
  <template>
    {{#if @topic.image_url}}
      <a
        class="dcp-topic-preview dcp-topic-preview--image"
        href={{@topic.path}}
        aria-label={{@topic.title}}
      >
        <img src={{@topic.image_url}} alt="" loading="lazy" />
      </a>
    {{else if @topic.excerpt}}
      <a class="dcp-topic-preview dcp-topic-preview--excerpt" href={{@topic.path}}>
        <p>{{@topic.excerpt}}</p>
      </a>
    {{/if}}
  </template>
}
