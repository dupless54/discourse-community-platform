# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class CommunityAuthorization
    def self.can_manage?(user, community)
      return false if user.blank?
      return true if user.admin? || community.owner_id == user.id

      community.moderator_group&.group_users&.exists?(user_id: user.id) || false
    end

    def self.ensure_can_manage!(user, community)
      raise Discourse::InvalidAccess unless can_manage?(user, community)
    end
  end
end
