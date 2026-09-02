import Component from "@glimmer/component";
import FeedActions from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-actions";
import FeedNavigation from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-navigation";
import TopicContext from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-context";
import TopicPreview from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-preview";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformExplorePage extends Component {
  <template>
    <div class="dcp-popular-page dcp-explore-page container">
      <FeedNavigation />

      <header class="dcp-popular-hero dcp-explore-hero">
        <p class="dcp-eyebrow">{{i18n "community_platform.explore.eyebrow"}}</p>
        <h1>{{i18n "community_platform.explore.title"}}</h1>
        {{#if @personalized}}
          <p>{{i18n "community_platform.explore.description"}}</p>
        {{else}}
          <p>{{i18n "community_platform.explore.guest_description"}}</p>
        {{/if}}
      </header>

      <main class="dcp-popular-feed dcp-explore-feed">
        {{#each @topics as |topic|}}
          <article class="dcp-popular-card dcp-explore-card">
            <div class="dcp-popular-card__score" aria-label={{i18n "community_platform.score"}}>
              <strong>{{topic.score}}</strong>
              <span>{{i18n "community_platform.score"}}</span>
            </div>

            <div class="dcp-popular-card__content">
              <TopicContext @topic={{topic}} @community={{topic.community}} />
              <a class="dcp-popular-card__title" href={{topic.path}}>
                {{topic.title}}
              </a>
              <TopicPreview @topic={{topic}} />
              <FeedActions @topic={{topic}} />
            </div>
          </article>
        {{else}}
          <div class="dcp-empty-state dcp-popular-empty dcp-explore-empty">
            <h2>{{i18n "community_platform.explore.empty_title"}}</h2>
            <p>{{i18n "community_platform.explore.empty_description"}}</p>
          </div>
        {{/each}}
      </main>
    </div>
  </template>
}
