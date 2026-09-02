import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import CommunityIdentity from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-identity";
import FeedActions from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-actions";
import FeedNavigation from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/feed-navigation";
import TopicContext from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-context";
import TopicPreview from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-preview";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformHomePage extends Component {
  @service currentUser;

  @tracked topics = [];
  @tracked votingTopicId = null;
  @tracked errorMessage = null;

  constructor(owner, args) {
    super(owner, args);
    this.topics = args.topics || [];
  }

  get followingFeed() {
    return this.args.feedVariant === "following";
  }

  get eyebrowKey() {
    return this.followingFeed
      ? "community_platform.following.eyebrow"
      : "community_platform.home.eyebrow";
  }

  get titleKey() {
    return this.followingFeed
      ? "community_platform.following.title"
      : "community_platform.home.title";
  }

  get descriptionKey() {
    if (this.followingFeed) {
      return this.args.loginRequired
        ? "community_platform.following.login_description"
        : "community_platform.following.description";
    }

    return this.args.personalized
      ? "community_platform.home.personalized_description"
      : "community_platform.home.fallback_description";
  }

  get emptyTitleKey() {
    if (this.followingFeed) {
      return this.args.loginRequired
        ? "community_platform.following.login_title"
        : "community_platform.following.empty_title";
    }

    return "community_platform.home.empty_title";
  }

  get emptyDescriptionKey() {
    if (this.followingFeed) {
      return this.args.loginRequired
        ? "community_platform.following.login_description"
        : "community_platform.following.empty_description";
    }

    return "community_platform.home.empty_description";
  }

  @action
  async vote(topic, value) {
    if (!this.currentUser || this.votingTopicId) {
      return;
    }

    const nextValue = topic.user_vote === value ? 0 : value;
    this.votingTopicId = topic.id;
    this.errorMessage = null;

    try {
      const response = await ajax(
        `/community-platform/topics/${topic.id}/vote.json`,
        {
          type: "PUT",
          data: { value: nextValue },
        }
      );
      const vote = response.vote;

      this.topics = this.topics.map((item) =>
        item.id === topic.id
          ? {
              ...item,
              score: vote.score,
              upvotes: vote.upvotes,
              downvotes: vote.downvotes,
              user_vote: vote.user_vote,
            }
          : item
      );
    } catch {
      this.errorMessage = i18n("community_platform.vote_error");
    } finally {
      this.votingTopicId = null;
    }
  }

  <template>
    <div class="dcp-home-page container">
      <FeedNavigation />

      <header class="dcp-home-hero">
        <div>
          <p class="dcp-eyebrow">{{i18n this.eyebrowKey}}</p>
          <h1>{{i18n this.titleKey}}</h1>
          <p>{{i18n this.descriptionKey}}</p>
        </div>

        {{#unless this.followingFeed}}
          <a class="btn btn-default dcp-home-popular-link" href="/popular">
            {{i18n "community_platform.home.open_popular"}}
          </a>
        {{/unless}}
      </header>

      {{#if @joinedCommunities.length}}
        <section class="dcp-home-communities" aria-label={{i18n "community_platform.home.joined_title"}}>
          <div class="dcp-home-communities__heading">
            <h2>{{i18n "community_platform.home.joined_title"}}</h2>
            <span>{{@joinedCommunities.length}}</span>
          </div>

          <div class="dcp-home-community-list">
            {{#each @joinedCommunities as |community|}}
              <CommunityIdentity
                @community={{community}}
                class="dcp-home-community-chip"
              />
            {{/each}}
          </div>
        </section>
      {{/if}}

      {{#if this.errorMessage}}
        <div class="alert alert-error dcp-home-feedback" role="alert">
          {{this.errorMessage}}
        </div>
      {{/if}}

      <main class="dcp-home-feed">
        {{#each this.topics as |topic|}}
          <article class="dcp-home-card">
            <div class="dcp-home-card__vote">
              {{#if this.currentUser}}
                <button
                  type="button"
                  class="dcp-vote-button dcp-vote-button--up"
                  aria-label={{i18n "community_platform.voting.upvote"}}
                  aria-pressed={{if (eq topic.user_vote 1) "true" "false"}}
                  disabled={{eq this.votingTopicId topic.id}}
                  {{on "click" (fn this.vote topic 1)}}
                >↑</button>
              {{/if}}

              <strong class="dcp-home-card__score">{{topic.score}}</strong>

              {{#if this.currentUser}}
                <button
                  type="button"
                  class="dcp-vote-button dcp-vote-button--down"
                  aria-label={{i18n "community_platform.voting.downvote"}}
                  aria-pressed={{if (eq topic.user_vote -1) "true" "false"}}
                  disabled={{eq this.votingTopicId topic.id}}
                  {{on "click" (fn this.vote topic -1)}}
                >↓</button>
              {{/if}}
            </div>

            <div class="dcp-home-card__content">
              <div class="dcp-home-card__context">
                <TopicContext @topic={{topic}} @community={{topic.community}} />

                <span class="dcp-home-card__source dcp-home-card__source--{{topic.feed_source}}">
                  {{#if (eq topic.feed_source "joined")}}
                    {{i18n "community_platform.home.source_joined"}}
                  {{else}}
                    {{#if (eq topic.feed_source "followed")}}
                      {{i18n "community_platform.home.source_followed"}}
                    {{else}}
                      {{i18n "community_platform.home.source_popular"}}
                    {{/if}}
                  {{/if}}
                </span>
              </div>

              <a class="dcp-home-card__title" href={{topic.path}}>
                {{topic.title}}
              </a>

              <TopicPreview @topic={{topic}} />
              <FeedActions @topic={{topic}} />
            </div>
          </article>
        {{else}}
          <div class="dcp-empty-state dcp-home-empty">
            <h2>{{i18n this.emptyTitleKey}}</h2>
            <p>{{i18n this.emptyDescriptionKey}}</p>

            {{#if this.followingFeed}}
              {{#if @loginRequired}}
                <a class="btn btn-primary" href="/login">
                  {{i18n "community_platform.following.log_in"}}
                </a>
              {{else}}
                <a class="btn btn-primary" href="/home">
                  {{i18n "community_platform.following.open_home"}}
                </a>
              {{/if}}
            {{else}}
              <a class="btn btn-primary" href="/popular">
                {{i18n "community_platform.home.open_popular"}}
              </a>
            {{/if}}
          </div>
        {{/each}}
      </main>
    </div>
  </template>
}
