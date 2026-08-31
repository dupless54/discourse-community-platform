# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class CommunitiesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in, only: %i[create join leave]

    def create
      community = Communities::Create.call(user: current_user, params: community_params)

      render_serialized(
        community,
        CommunitySerializer,
        root: :community,
        status: :created,
      )
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def show
      render_serialized(find_visible_community, CommunitySerializer, root: :community)
    end

    def join
      community = Memberships::Join.call(user: current_user, community: find_visible_community)
      render_serialized(community, CommunitySerializer, root: :community)
    end

    def leave
      community = Memberships::Leave.call(user: current_user, community: find_visible_community)
      render_serialized(community, CommunitySerializer, root: :community)
    end

    private

    def community_params
      params.require(:community).permit(:name, :slug, :description, :visibility)
    end

    def find_visible_community
      community =
        Community.includes(:category, :owner, :member_group, :moderator_group).find_by!(slug: params[:slug])

      # Do not reveal that a private/restricted community exists unless Discourse's
      # own category permission model allows the current guardian to see it.
      raise Discourse::NotFound unless guardian.can_see_category?(community.category)

      community
    end
  end
end
