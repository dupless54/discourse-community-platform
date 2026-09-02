import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import CommunityIdentity from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/community-identity";
import PlatformNavigation from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/platform-navigation";
import DUserAvatar from "discourse/ui-kit/d-user-avatar";
import { i18n } from "discourse-i18n";

export default class CommunityPlatformShell extends Component {
  @service currentUser;
  @service siteSettings;

  get profilePath() {
    return this.currentUser ? `/u/${this.currentUser.username}` : null;
  }

  get sidebarCommunities() {
    return (this.args.communities || []).slice(0, 5);
  }

  get hasSidebarCommunities() {
    return this.sidebarCommunities.length > 0;
  }

  <template>
    <div class="dcp-platform-shell" data-platform-section={{@section}}>
      <header class="dcp-platform-header">
        <div class="dcp-platform-header__inner">
          <LinkTo
            @route="community-platform-home"
            class="dcp-platform-brand"
            aria-label={{this.siteSettings.title}}
          >
            <span class="dcp-platform-brand__mark" aria-hidden="true">s/</span>
            <span class="dcp-platform-brand__name">{{this.siteSettings.title}}</span>
          </LinkTo>

          <form class="dcp-platform-search" action="/search" method="get" role="search">
            <span class="dcp-platform-search__icon" aria-hidden="true">⌕</span>
            <input
              type="search"
              name="q"
              aria-label={{i18n "search.title"}}
              placeholder={{i18n "search.title"}}
              autocomplete="off"
            />
          </form>

          <div class="dcp-platform-account">
            {{#if this.currentUser}}
              <a class="dcp-platform-account__profile" href={{this.profilePath}}>
                <DUserAvatar @user={{this.currentUser}} @size="small" />
                <span>@{{this.currentUser.username}}</span>
              </a>
            {{else}}
              <a class="btn btn-primary dcp-platform-account__login" href="/login">
                {{i18n "log_in"}}
              </a>
            {{/if}}
          </div>
        </div>

        <div class="dcp-platform-mobile-navigation">
          <PlatformNavigation />
        </div>
      </header>

      <div class="dcp-platform-layout">
        <aside class="dcp-platform-sidebar">
          <div class="dcp-platform-sidebar__sticky">
            <PlatformNavigation />
          </div>
        </aside>

        <div class="dcp-platform-content" id="dcp-platform-content">
          {{yield}}
        </div>

        <aside
          class="dcp-platform-right-rail"
          aria-label={{i18n "community_platform.explore.title"}}
        >
          <div class="dcp-platform-right-rail__sticky">
            {{#if @currentCommunity}}
              <section class="dcp-platform-rail-card">
                <h2>{{i18n "community_platform.about"}}</h2>
                <CommunityIdentity
                  @community={{@currentCommunity}}
                  class="dcp-platform-rail-community"
                />
              </section>
            {{/if}}

            {{#if this.hasSidebarCommunities}}
              <section class="dcp-platform-rail-card">
                <h2>{{i18n @sidebarHeadingKey}}</h2>
                <div class="dcp-platform-rail-community-list">
                  {{#each this.sidebarCommunities as |community|}}
                    <CommunityIdentity
                      @community={{community}}
                      class="dcp-platform-rail-community"
                    />
                  {{/each}}
                </div>
              </section>
            {{/if}}

            <section class="dcp-platform-rail-card dcp-platform-rail-card--discover">
              <h2>{{i18n "community_platform.explore.title"}}</h2>
              <p>{{i18n "community_platform.explore.description"}}</p>
              <div class="dcp-platform-rail-actions">
                <LinkTo @route="community-platform-explore" class="btn btn-default">
                  {{i18n "community_platform.explore.title"}}
                </LinkTo>
                <LinkTo @route="community-platform-popular" class="btn btn-default">
                  {{i18n "community_platform.popular.title"}}
                </LinkTo>
              </div>
            </section>
          </div>
        </aside>
      </div>
    </div>
  </template>
}
