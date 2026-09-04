import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default <template>
  <nav
    class="dcp-platform-navigation"
    aria-label={{i18n "community_platform.navigation.aria_label"}}
  >
    <LinkTo
      @route="discovery.index"
      class={{if
        (eq @section "home")
        "dcp-platform-navigation__link active"
        "dcp-platform-navigation__link"
      }}
      aria-current={{if (eq @section "home") "page"}}
      data-platform-feed="home"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">⌂</span>
      <span>{{i18n "community_platform.home.title"}}</span>
    </LinkTo>

    <LinkTo
      @route="community-platform-following"
      class={{if
        (eq @section "following")
        "dcp-platform-navigation__link active"
        "dcp-platform-navigation__link"
      }}
      aria-current={{if (eq @section "following") "page"}}
      data-platform-feed="following"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">◎</span>
      <span>{{i18n "community_platform.following.title"}}</span>
    </LinkTo>

    <LinkTo
      @route="community-platform-explore"
      class={{if
        (eq @section "explore")
        "dcp-platform-navigation__link active"
        "dcp-platform-navigation__link"
      }}
      aria-current={{if (eq @section "explore") "page"}}
      data-platform-feed="explore"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">◇</span>
      <span>{{i18n "community_platform.explore.title"}}</span>
    </LinkTo>

    <LinkTo
      @route="community-platform-popular"
      class={{if
        (eq @section "popular")
        "dcp-platform-navigation__link active"
        "dcp-platform-navigation__link"
      }}
      aria-current={{if (eq @section "popular") "page"}}
      data-platform-feed="popular"
    >
      <span class="dcp-platform-navigation__icon" aria-hidden="true">↗</span>
      <span>{{i18n "community_platform.popular.title"}}</span>
    </LinkTo>
  </nav>
</template>
