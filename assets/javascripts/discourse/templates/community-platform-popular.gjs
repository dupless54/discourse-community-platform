import PopularPage from "discourse/plugins/discourse-community-platform/discourse/components/community-platform/popular-page";

export default <template>
  <PopularPage @topics={{@controller.model.topics}} />
</template>;
