import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import FeedActions from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-actions";
import FeedNavigation from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-navigation";
import TopicContext from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-context";
import TopicPreview from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-preview";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformExplorePage extends Component {
  @tracked recommendedCommunities = [];
  @tracked joiningCommunityId = null;
  @tracked membershipError = null;

  constructor(owner, args) {
    super(owner, args);
    this.recommendedCommunities = args.recommendedCommunities || [];
  }

  @action
  async joinCommunity(community) {
    if (!community.can_join || this.joiningCommunityId) {
      return;
    }

    this.joiningCommunityId = community.id;
    this.membershipError = null;

    try {
      const response = await ajax(
        `/community-platform/communities/${community.slug}/join.json`,
        { type: "POST" }
      );
      const joinedCommunity = response.community;

      this.recommendedCommunities = this.recommendedCommunities.map((item) =>
        item.id === community.id
          ? {
              ...item,
              members_count: joinedCommunity.members_count,
              can_join: false,
              joined: true,
            }
          : item
      );
    } catch {
      this.membershipError = i18n("community_platform.membership_error");
    } finally {
      this.joiningCommunityId = null;
    }
  }

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

      {{#if this.recommendedCommunities.length}}
        <section class="dcp-explore-communities" aria-labelledby="dcp-explore-communities-title">
          <header class="dcp-explore-communities__heading">
            <div>
              <h2 id="dcp-explore-communities-title">
                {{i18n "community_platform.explore.recommended_title"}}
              </h2>
              <p>{{i18n "community_platform.explore.recommended_description"}}</p>
            </div>
          </header>

          {{#if this.membershipError}}
            <div class="alert alert-error dcp-explore-membership-error" role="alert">
              {{this.membershipError}}
            </div>
          {{/if}}

          <div class="dcp-explore-community-grid">
            {{#each this.recommendedCommunities as |community|}}
              <article class="dcp-explore-community-card">
                <a class="dcp-explore-community-card__link" href={{community.path}}>
                  <div class="dcp-explore-community-card__top">
                    {{#if community.icon_url}}
                      <span class="dcp-explore-community-card__icon" aria-hidden="true">
                        <img src={{community.icon_url}} alt="" loading="lazy" />
                      </span>
                    {{else if community.icon_emoji}}
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

                <div class="dcp-explore-community-card__actions">
                  {{#if community.joined}}
                    <span class="dcp-explore-community-card__joined" role="status">
                      {{i18n "community_platform.joined"}}
                    </span>
                  {{else if community.can_join}}
                    <button
                      type="button"
                      class="btn btn-primary dcp-explore-community-card__join"
                      disabled={{eq this.joiningCommunityId community.id}}
                      aria-busy={{if (eq this.joiningCommunityId community.id) "true" "false"}}
                      {{on "click" (fn this.joinCommunity community)}}
                    >
                      {{#if (eq this.joiningCommunityId community.id)}}
                        {{i18n "community_platform.explore.joining"}}
                      {{else}}
                        {{i18n "community_platform.join"}}
                      {{/if}}
                    </button>
                  {{/if}}
                </div>
              </article>
            {{/each}}
          </div>
        </section>
      {{/if}}

      {{#if @recommendedPeople.length}}
        <section class="dcp-explore-people" aria-labelledby="dcp-explore-people-title">
          <header class="dcp-explore-people__heading">
            <div>
              <h2 id="dcp-explore-people-title">
                {{i18n "community_platform.explore.people_title"}}
              </h2>
              <p>{{i18n "community_platform.explore.people_description"}}</p>
            </div>
          </header>

          <div class="dcp-explore-people-grid">
            {{#each @recommendedPeople as |person|}}
              <a class="dcp-explore-person-card" href={{person.path}}>
                <div class="dcp-explore-person-card__identity">
                  <span class="dcp-explore-person-card__avatar" aria-hidden="true">@</span>
                  <div>
                    <strong>@{{person.username}}</strong>
                    {{#if person.name}}
                      <span>{{person.name}}</span>
                    {{/if}}
                  </div>
                </div>
                <p>
                  {{person.recent_public_topics_count}}
                  {{i18n "community_platform.explore.recent_public_topics"}}
                </p>
                <span class="dcp-explore-person-card__action">
                  {{i18n "community_platform.explore.open_profile"}}
                </span>
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
