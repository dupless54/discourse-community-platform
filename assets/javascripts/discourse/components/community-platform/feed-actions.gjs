import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default <template>
  <div class="dcp-feed-actions">
    <a class="dcp-feed-action dcp-feed-action--discussion" href={{@topic.path}}>
      {{dIcon "comment"}}
      <span>{{@topic.posts_count}} {{i18n "community_platform.posts"}}</span>
    </a>

    <span class="dcp-feed-action dcp-feed-action--metric">
      {{dIcon "eye"}}
      <span>{{@topic.views}} {{i18n "community_platform.views"}}</span>
    </span>

    <span class="dcp-feed-action dcp-feed-action--metric">
      {{dIcon "heart"}}
      <span>{{@topic.like_count}} {{i18n "community_platform.likes"}}</span>
    </span>
  </div>
</template>;
