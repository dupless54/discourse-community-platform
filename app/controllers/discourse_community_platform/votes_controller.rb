# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class VotesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def update
      topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound if topic.blank?

      community = Community.find_by(category_id: topic.category_id)
      raise Discourse::NotFound if community.blank?
      raise Discourse::NotFound unless guardian.can_see_category?(community.category)
      raise Discourse::NotFound unless guardian.can_see_topic?(topic)

      render json: { vote: Votes::Cast.call(user: current_user, topic:, value: params[:value]) }
    end
  end
end
