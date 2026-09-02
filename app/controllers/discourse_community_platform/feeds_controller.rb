# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class FeedsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    TRENDING_LIMIT = 5

    def home
      limit = params[:limit].presence || Feeds::HomeTopics::DEFAULT_LIMIT
      payload = Feeds::HomeTopics.call(guardian:, limit:)

      render json: payload.merge(trending_topics: trending_topics)
    end

    def following
      limit = params[:limit].presence || Feeds::FollowingTopics::DEFAULT_LIMIT
      payload = Feeds::FollowingTopics.call(guardian:, limit:)

      render json: payload.merge(trending_topics: trending_topics)
    end

    def explore
      limit = params[:limit].presence || Feeds::ExploreTopics::DEFAULT_LIMIT
      community_limit =
        params[:community_limit].presence || Feeds::ExploreCommunities::DEFAULT_LIMIT
      people_limit = params[:people_limit].presence || Feeds::ExplorePeople::DEFAULT_LIMIT

      render json: {
               order: "explore",
               personalized: current_user.present?,
               recommended_communities:
                 Feeds::ExploreCommunities.call(guardian:, limit: community_limit),
               recommended_people: Feeds::ExplorePeople.call(guardian:, limit: people_limit),
               trending_topics: trending_topics,
               topics: Feeds::ExploreTopics.call(guardian:, limit:),
             }
    end

    def popular
      limit = params[:limit].presence || Feeds::PopularTopics::DEFAULT_LIMIT

      render json: {
               order: "popular",
               trending_topics: trending_topics,
               topics: Feeds::PopularTopics.call(guardian:, limit:),
             }
    end

    private

    def trending_topics
      @trending_topics ||=
        Feeds::PopularTopicSummaries.call(guardian:, limit: TRENDING_LIMIT)
    end
  end
end
