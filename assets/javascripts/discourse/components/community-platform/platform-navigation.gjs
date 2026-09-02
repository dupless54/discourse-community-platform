import { LinkTo } from "@ember/routing";
import { i18n } from "discourse-i18n";

export default <template>
  <nav
    class="dcp-platform-navigation"
    aria-label={{i18n "community_platform.navigation.aria_label"}}
  >
    <LinkTo
      @route="community-platform-home"
      class="dcp-platform-navigation__link"
      data-platform-feed="home"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">⌂</span>
      <span>{{i18n "community_platform.home.title"}}</span>
    </LinkTo>

    <LinkTo
      @route="community-platform-following"
      class="dcp-platform-navigation__link"
      data-platform-feed="following"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">◎</span>
      <span>{{i18n "community_platform.following.title"}}</span>
    </LinkTo>

    <LinkTo
      @route="community-platform-explore"
      class="dcp-platform-navigation__link"
      data-platform-feed="explore"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">◇</span>
      <span>{{i18n "community_platform.explore.title"}}</span>
    </LinkTo>

    <LinkTo
      @route="community-platform-popular"
      class="dcp-platform-navigation__link"
      data-platform-feed="popular"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">↗</span>
      <span>{{i18n "community_platform.popular.title"}}</span>
    </LinkTo>
  </nav>
</template>
