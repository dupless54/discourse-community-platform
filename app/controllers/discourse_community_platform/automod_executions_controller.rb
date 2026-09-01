# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class AutomodExecutionsController < ManagementController
    HISTORY_LIMIT = 50

    def index
      community = find_manageable_community
      executions =
        AutomodExecution
          .includes(post: :user)
          .where(community_id: community.id)
          .order(created_at: :desc, id: :desc)
          .limit(HISTORY_LIMIT)

      render json: { automod_executions: executions.map { |execution| serialize_execution(execution) } }
    end

    def insights
      community = find_manageable_community

      render json: { moderation_insights: Automod::Insights.call(community:) }
    end

    private

    def find_manageable_community
      community = Community.includes(:category).find_by!(slug: params[:slug])
      raise Discourse::NotFound unless guardian.can_see_category?(community.category)

      CommunityAuthorization.ensure_can_manage!(current_user, community)
      community
    end

    def serialize_execution(execution)
      post = execution.post
      visible_post = post if guardian.can_see_post?(post)

      {
        id: execution.id,
        post_id: execution.post_id,
        post_url: visible_post&.url,
        username: visible_post&.user&.username,
        rule_name: execution.rule_name,
        trigger: execution.trigger,
        outcome: execution.outcome,
        created_at: execution.created_at,
      }
    end
  end
end
