import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
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

  get descriptionKey() {
    return this.args.personalized
      ? "community_platform.home.personalized_description"
      : "community_platform.home.fallback_description";
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
      <header class="dcp-home-hero">
        <div>
          <p class="dcp-eyebrow">{{i18n "community_platform.home.eyebrow"}}</p>
          <h1>{{i18n "community_platform.home.title"}}</h1>
          <p>{{i18n this.descriptionKey}}</p>
        </div>

        <a class="btn btn-default dcp-home-popular-link" href="/popular">
          {{i18n "community_platform.home.open_popular"}}
        </a>
      </header>

      {{#if @joinedCommunities.length}}
        <section class="dcp-home-communities" aria-label={{i18n "community_platform.home.joined_title"}}>
          <div class="dcp-home-communities__heading">
            <h2>{{i18n "community_platform.home.joined_title"}}</h2>
            <span>{{@joinedCommunities.length}}</span>
          </div>

          <div class="dcp-home-community-list">
            {{#each @joinedCommunities as |community|}}
              <a class="dcp-home-community-chip" href={{community.path}}>
                s/{{community.slug}}
              </a>
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
                <a href={{topic.community.path}}>s/{{topic.community.slug}}</a>
                <span class="dcp-home-card__source dcp-home-card__source--{{topic.feed_source}}">
                  {{#if (eq topic.feed_source "joined")}}
                    {{i18n "community_platform.home.source_joined"}}
                  {{else}}
                    {{i18n "community_platform.home.source_popular"}}
                  {{/if}}
                </span>
              </div>

              <a class="dcp-home-card__title" href={{topic.path}}>
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
          <div class="dcp-empty-state dcp-home-empty">
            <h2>{{i18n "community_platform.home.empty_title"}}</h2>
            <p>{{i18n "community_platform.home.empty_description"}}</p>
            <a class="btn btn-primary" href="/popular">
              {{i18n "community_platform.home.open_popular"}}
            </a>
          </div>
        {{/each}}
      </main>
    </div>
  </template>
}
