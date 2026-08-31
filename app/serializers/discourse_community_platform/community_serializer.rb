# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class CommunitySerializer < ::ApplicationSerializer
    attributes :id,
               :name,
               :slug,
               :description,
               :visibility,
               :members_count,
               :category_id,
               :owner_id,
               :member_group_id,
               :moderator_group_id,
               :created_at

    attribute :path
    attribute :is_member
    attribute :is_owner
    attribute :is_moderator
    attribute :can_join
    attribute :can_leave

    def path
      "/s/#{object.slug}"
    end

    def is_member
      user = scope&.user
      return false if user.blank? || object.member_group.blank?

      object.member_group.group_users.exists?(user_id: user.id)
    end

    def is_owner
      user = scope&.user
      user.present? && object.owner_id == user.id
    end

    def is_moderator
      user = scope&.user
      return false if user.blank? || object.moderator_group.blank?

      object.moderator_group.group_users.exists?(user_id: user.id)
    end

    def can_join
      user = scope&.user
      return false if user.blank? || is_member || object.private?

      scope.can_see_category?(object.category)
    end

    def can_leave
      user = scope&.user
      return false if user.blank? || !is_member || is_owner || is_moderator

      true
    end
  end
end
