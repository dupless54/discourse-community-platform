import TopicCommunityContext from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/topic-community-context";

export default <template>
  <TopicCommunityContext @topic={{@outletArgs.model}} />
</template>
