import Component from "@glimmer/component";

export default class CommunityPlatformCommunityIdentity extends Component {
  get initial() {
    return this.args.community?.name?.charAt(0).toUpperCase() || "C";
  }

  <template>
    <a
      class="dcp-feed-community-identity"
      href={{@community.path}}
      ...attributes
    >
      <span class="dcp-feed-community-identity__icon" aria-hidden="true">
        {{#if @community.icon_url}}
          <img src={{@community.icon_url}} alt="" />
        {{else if @community.icon_emoji}}
          <span>{{@community.icon_emoji}}</span>
        {{else}}
          <span>{{this.initial}}</span>
        {{/if}}
      </span>
      <span
        class="dcp-feed-community-identity__label"
      >{{@community.name}}</span>
    </a>
  </template>
}
