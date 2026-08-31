# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class FeedsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def home
      limit = params[:limit].presence || Feeds::HomeTopics::DEFAULT_LIMIT

      render json: Feeds::HomeTopics.call(guardian:, limit:)
    end

    def popular
      limit = params[:limit].presence || Feeds::PopularTopics::DEFAULT_LIMIT

      render json: {
               order: "popular",
               topics: Feeds::PopularTopics.call(guardian:, limit:),
             }
    end
  end
end
