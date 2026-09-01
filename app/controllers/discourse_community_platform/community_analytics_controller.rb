# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class CommunityAnalyticsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def show
      community = find_manageable_community

      render json: {
               community_activity_analytics: Analytics::CommunityActivity.call(community:),
             }
    end

    private

    def find_manageable_community
      community = Community.includes(:category).find_by!(slug: params[:slug])
      raise Discourse::NotFound unless guardian.can_see_category?(community.category)

      CommunityAuthorization.ensure_can_manage!(current_user, community)
      community
    end
  end
end
