import Component from "@glimmer/component";
import FeedNavigation from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-navigation";
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

      {{#if @recommendedCommunities.length}}
        <section class="dcp-explore-communities" aria-labelledby="dcp-explore-communities-title">
          <header class="dcp-explore-communities__heading">
            <div>
              <h2 id="dcp-explore-communities-title">
                {{i18n "community_platform.explore.recommended_title"}}
              </h2>
              <p>{{i18n "community_platform.explore.recommended_description"}}</p>
            </div>
          </header>

          <div class="dcp-explore-community-grid">
            {{#each @recommendedCommunities as |community|}}
              <a class="dcp-explore-community-card" href={{community.path}}>
                <div class="dcp-explore-community-card__top">
                  {{#if community.icon_emoji}}
                    <span class="dcp-explore-community-card__icon" aria-hidden="true">
                      {{community.icon_emoji}}
                    </span>
                  {{/if}}
                  <div>
                    <strong>s/{{community.slug}}</strong>
                    <span>{{community.name}}</span>
                  </div>
                </div>

                {{#if community.description}}
                  <p>{{community.description}}</p>
                {{/if}}

                <div class="dcp-explore-community-card__meta">
                  <span>{{community.members_count}} {{i18n "community_platform.members"}}</span>
                  <span>
                    {{community.recent_topics_count}}
                    {{i18n "community_platform.explore.active_topics"}}
                  </span>
                </div>
              </a>
            {{/each}}
          </div>
        </section>
      {{/if}}

      <main class="dcp-popular-feed dcp-explore-feed">
        {{#each @topics as |topic|}}
          <article class="dcp-popular-card dcp-explore-card">
            <div class="dcp-popular-card__score" aria-label={{i18n "community_platform.score"}}>
              <strong>{{topic.score}}</strong>
              <span>{{i18n "community_platform.score"}}</span>
            </div>

            <div class="dcp-popular-card__content">
              <a class="dcp-popular-card__community" href={{topic.community.path}}>
                s/{{topic.community.slug}}
              </a>
              <a class="dcp-popular-card__title" href={{topic.path}}>
                {{topic.title}}
              </a>
              <div class="dcp-topic-card__meta">
                <span>{{topic.posts_count}} {{i18n "community_platform.posts"}}</span>
                <span>{{topic.views}} {{i18n "community_platform.views"}}</span>
                <span>{{topic.like_count}} {{i18n "community_platform.likes"}}</span>
              </div>
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
