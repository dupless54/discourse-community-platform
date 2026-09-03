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
               :rules,
               :icon_emoji,
               :banner_color,
               :icon_upload_id,
               :banner_upload_id,
               :created_at

    attribute :path
    attribute :category_url
    attribute :owner_username
    attribute :icon_url
    attribute :banner_url
    attribute :is_member
    attribute :is_owner
    attribute :is_moderator
    attribute :can_join
    attribute :can_leave
    attribute :can_manage

    def path
      object.path
    end

    def category_url
      object.category.url
    end

    def owner_username
      object.owner.username
    end

    def icon_url
      visible_upload_url(object.icon_upload)
    end

    def banner_url
      visible_upload_url(object.banner_upload)
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
      return false if user.blank? || object.member_group.blank? || is_member || object.private?

      scope.can_see_category?(object.category)
    end

    def can_leave
      user = scope&.user
      return false if user.blank? || !is_member || is_owner || is_moderator

      true
    end

    def can_manage
      CommunityAuthorization.can_manage?(scope&.user, object)
    end

    def include_icon_upload_id?
      can_manage
    end

    def include_banner_upload_id?
      can_manage
    end

    private

    def visible_upload_url(upload)
      return if upload.blank? || scope.blank? || !scope.can_see_upload?(upload)

      upload.url
    end
  end
end
