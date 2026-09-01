import Component from "@glimmer/component";
import CommunityIdentity from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-identity";
import FeedNavigation from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-navigation";
import TopicPreview from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-preview";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformPopularPage extends Component {
  <template>
    <div class="dcp-popular-page container">
      <FeedNavigation />

      <header class="dcp-popular-hero">
        <p class="dcp-eyebrow">{{i18n "community_platform.popular.eyebrow"}}</p>
        <h1>{{i18n "community_platform.popular.title"}}</h1>
        <p>{{i18n "community_platform.popular.description"}}</p>
      </header>

      <main class="dcp-popular-feed">
        {{#each @topics as |topic|}}
          <article class="dcp-popular-card">
            <div class="dcp-popular-card__score" aria-label={{i18n "community_platform.score"}}>
              <strong>{{topic.score}}</strong>
              <span>{{i18n "community_platform.score"}}</span>
            </div>

            <div class="dcp-popular-card__content">
              <CommunityIdentity
                @community={{topic.community}}
                class="dcp-popular-card__community"
              />
              <a class="dcp-popular-card__title" href={{topic.path}}>
                {{topic.title}}
              </a>
              <TopicPreview @topic={{topic}} />
              <div class="dcp-topic-card__meta">
                <span>{{topic.posts_count}} {{i18n "community_platform.posts"}}</span>
                <span>{{topic.views}} {{i18n "community_platform.views"}}</span>
                <span>{{topic.like_count}} {{i18n "community_platform.likes"}}</span>
              </div>
            </div>
          </article>
        {{else}}
          <div class="dcp-empty-state dcp-popular-empty">
            <h2>{{i18n "community_platform.popular.empty_title"}}</h2>
            <p>{{i18n "community_platform.popular.empty_description"}}</p>
          </div>
        {{/each}}
      </main>
    </div>
  </template>
}
