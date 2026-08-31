# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class CommunitiesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def show
      community =
        Community.includes(:category, :owner, :member_group, :moderator_group).find_by!(slug: params[:slug])

      # Do not reveal that a private/restricted community exists unless Discourse's
      # own category permission model allows the current guardian to see it.
      raise Discourse::NotFound unless guardian.can_see_category?(community.category)

      render_serialized(community, CommunitySerializer, root: :community)
    end
  end
end
