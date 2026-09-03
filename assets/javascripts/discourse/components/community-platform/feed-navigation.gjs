import { LinkTo } from "@ember/routing";
import DHorizontalOverflowNav from "discourse/ui-kit/d-horizontal-overflow-nav";
import { i18n } from "discourse-i18n";

export default <template>
  <section class="dcp-feed-navigation-shell">
    <DHorizontalOverflowNav
      @ariaLabel={{i18n "community_platform.navigation.aria_label"}}
      @className="dcp-feed-navigation"
    >
      <li>
        <LinkTo
          @route="discovery.index"
          class="dcp-feed-navigation__link"
          data-feed="home"
        >
          {{i18n "community_platform.home.title"}}
        </LinkTo>
      </li>
      <li>
        <LinkTo
          @route="community-platform-following"
          class="dcp-feed-navigation__link"
          data-feed="following"
        >
          {{i18n "community_platform.following.title"}}
        </LinkTo>
      </li>
      <li>
        <LinkTo
          @route="community-platform-explore"
          class="dcp-feed-navigation__link"
          data-feed="explore"
        >
          {{i18n "community_platform.explore.title"}}
        </LinkTo>
      </li>
      <li>
        <LinkTo
          @route="community-platform-popular"
          class="dcp-feed-navigation__link"
          data-feed="popular"
        >
          {{i18n "community_platform.popular.title"}}
        </LinkTo>
      </li>
    </DHorizontalOverflowNav>
  </section>
</template>
