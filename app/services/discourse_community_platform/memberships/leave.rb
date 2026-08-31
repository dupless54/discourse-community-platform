# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Memberships
    class Leave
      def self.call(user:, community:)
        new(user:, community:).call
      end

      def initialize(user:, community:)
        @user = user
        @community = community
      end

      def call
        ensure_leave_allowed!

        group = @community.member_group
        raise Discourse::InvalidAccess if group.blank?

        GroupManager.new(group).remove([@user.id])
        sync_members_count(group)
      end

      private

      def ensure_leave_allowed!
        raise Discourse::InvalidAccess if @user.blank?

        guardian = Guardian.new(@user)
        raise Discourse::NotFound unless guardian.can_see_category?(@community.category)
        raise Discourse::InvalidAccess if @community.owner_id == @user.id

        moderator_group = @community.moderator_group
        if moderator_group&.group_users&.exists?(user_id: @user.id)
          raise Discourse::InvalidAccess
        end
      end

      def sync_members_count(group)
        @community.update_column(:members_count, group.reload.user_count)
        @community.reload
      end
    end
  end
end
