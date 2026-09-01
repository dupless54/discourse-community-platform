# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class AutomodRulesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def index
      community = find_manageable_community
      rules = AutomodRule.where(community_id: community.id).order(:id)

      render json: { automod_rules: rules.map { |rule| serialize_rule(rule) } }
    end

    def create
      community = find_manageable_community
      rule =
        AutomodRule.create!(
          rule_params.merge(
            community_id: community.id,
            created_by_id: current_user.id,
            updated_by_id: current_user.id,
          ),
        )

      render json: { automod_rule: serialize_rule(rule) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def update
      community = find_manageable_community
      rule = AutomodRule.find_by!(id: params[:id], community_id: community.id)
      rule.update!(rule_params.merge(updated_by_id: current_user.id))

      render json: { automod_rule: serialize_rule(rule) }
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def destroy
      community = find_manageable_community
      AutomodRule.find_by!(id: params[:id], community_id: community.id).destroy!

      head :no_content
    end

    private

    def rule_params
      params.require(:automod_rule).permit(:name, :enabled, :match_mode, terms: []).to_h.symbolize_keys
    end

    def find_manageable_community
      community = Community.includes(:category).find_by!(slug: params[:slug])
      raise Discourse::NotFound unless guardian.can_see_category?(community.category)

      CommunityAuthorization.ensure_can_manage!(current_user, community)
      community
    end

    def serialize_rule(rule)
      {
        id: rule.id,
        name: rule.name,
        enabled: rule.enabled,
        match_mode: rule.match_mode,
        terms: rule.terms,
        created_by_id: rule.created_by_id,
        updated_by_id: rule.updated_by_id,
        created_at: rule.created_at,
        updated_at: rule.updated_at,
      }
    end
  end
end
