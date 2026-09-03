import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import DUserAvatar from "discourse/ui-kit/d-user-avatar";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformExploreDiscoveryRail extends Component {
  @tracked recommendedCommunities = [];
  @tracked joiningCommunityId = null;
  @tracked membershipError = null;

  constructor(owner, args) {
    super(owner, args);
    this.recommendedCommunities = args.recommendedCommunities || [];
  }

  get communities() {
    return this.recommendedCommunities.slice(0, 6);
  }

  get people() {
    return (this.args.recommendedPeople || []).slice(0, 6);
  }

  get hasCommunities() {
    return this.communities.length > 0;
  }

  get hasPeople() {
    return this.people.length > 0;
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
    <div class="dcp-explore-discovery" data-test-explore-discovery>
      {{#if this.hasCommunities}}
        <section
          class="dcp-platform-rail-card dcp-explore-discovery__section"
          aria-labelledby="dcp-explore-discovery-communities-title"
        >
          <h2 id="dcp-explore-discovery-communities-title">
            {{i18n "community_platform.explore.recommended_title"}}
          </h2>

          {{#if this.membershipError}}
            <div
              class="alert alert-error dcp-explore-membership-error"
              role="alert"
            >
              {{this.membershipError}}
            </div>
          {{/if}}

          <div class="dcp-explore-discovery__community-list">
            {{#each this.communities as |community|}}
              <article class="dcp-explore-discovery-community">
                <a
                  class="dcp-explore-community-card__link dcp-explore-discovery-community__link"
                  href={{community.path}}
                >
                  {{#if community.icon_url}}
                    <span
                      class="dcp-explore-discovery-community__icon"
                      aria-hidden="true"
                    >
                      <img src={{community.icon_url}} alt="" loading="lazy" />
                    </span>
                  {{else if community.icon_emoji}}
                    <span
                      class="dcp-explore-discovery-community__icon"
                      aria-hidden="true"
                    >
                      {{community.icon_emoji}}
                    </span>
                  {{else}}
                    <span
                      class="dcp-explore-discovery-community__icon"
                      aria-hidden="true"
                    >
                      C
                    </span>
                  {{/if}}

                  <span class="dcp-explore-discovery-community__identity">
                    <strong>{{community.name}}</strong>
                    <span>{{community.slug}}</span>
                  </span>
                </a>

                <div
                  class="dcp-explore-community-card__meta dcp-explore-discovery-community__meta"
                >
                  <span>{{community.members_count}}
                    {{i18n "community_platform.members"}}</span>
                  <span>
                    {{community.recent_topics_count}}
                    {{i18n "community_platform.explore.active_topics"}}
                  </span>
                </div>

                <div
                  class="dcp-explore-community-card__actions dcp-explore-discovery-community__actions"
                >
                  {{#if community.joined}}
                    <span
                      class="dcp-explore-community-card__joined"
                      role="status"
                    >
                      {{i18n "community_platform.joined"}}
                    </span>
                  {{else if community.can_join}}
                    <button
                      type="button"
                      class="btn btn-primary dcp-explore-community-card__join"
                      disabled={{eq this.joiningCommunityId community.id}}
                      aria-busy={{if
                        (eq this.joiningCommunityId community.id)
                        "true"
                        "false"
                      }}
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

      {{#if this.hasPeople}}
        <section
          class="dcp-platform-rail-card dcp-explore-discovery__section"
          aria-labelledby="dcp-explore-discovery-people-title"
        >
          <h2 id="dcp-explore-discovery-people-title">
            {{i18n "community_platform.explore.people_title"}}
          </h2>

          <div class="dcp-explore-discovery__people-list">
            {{#each this.people as |person|}}
              <article class="dcp-explore-discovery-person">
                <DUserAvatar
                  @user={{person}}
                  @size="small"
                  @href={{person.path}}
                  class="dcp-explore-discovery-person__avatar"
                />

                <div class="dcp-explore-discovery-person__body">
                  <a
                    class="dcp-explore-discovery-person__username"
                    href={{person.path}}
                  >
                    @{{person.username}}
                  </a>
                  {{#if person.name}}
                    <span
                      class="dcp-explore-discovery-person__name"
                    >{{person.name}}</span>
                  {{/if}}
                  <span class="dcp-explore-discovery-person__meta">
                    {{person.recent_public_topics_count}}
                    {{i18n "community_platform.explore.recent_public_topics"}}
                  </span>
                </div>
              </article>
            {{/each}}
          </div>
        </section>
      {{/if}}
    </div>
  </template>
}
