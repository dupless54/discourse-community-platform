# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class LegacyCommunitiesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def show
      community = Community.includes(:category).find_by!(slug: params[:slug])
      raise Discourse::NotFound unless guardian.can_see_category?(community.category)

      redirect_to(
        community.category.url,
        status: :moved_permanently,
        allow_other_host: false,
      )
    end
  end
end
