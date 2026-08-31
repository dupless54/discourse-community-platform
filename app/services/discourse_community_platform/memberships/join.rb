# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Memberships
    class Join
      def self.call(user:, community:)
        new(user:, community:).call
      end

      def initialize(user:, community:)
        @user = user
        @community = community
      end

      def call
        ensure_join_allowed!

        group = @community.member_group
        raise Discourse::InvalidAccess if group.blank?

        return sync_members_count(group) if group.group_users.exists?(user_id: @user.id)

        # Private communities are invitation/moderation only. Allowing an
        # arbitrary self-join would turn the membership API into an existence
        # oracle for otherwise hidden communities.
        raise Discourse::NotFound if @community.private?

        GroupManager.new(group).add([@user.id])
        sync_members_count(group)
      end

      private

      def ensure_join_allowed!
        raise Discourse::InvalidAccess if @user.blank?
        raise Discourse::InvalidAccess if @user.staged? || @user.suspended?

        guardian = Guardian.new(@user)
        raise Discourse::NotFound unless guardian.can_see_category?(@community.category)
      end

      def sync_members_count(group)
        @community.update_column(:members_count, group.reload.user_count)
        @community.reload
      end
    end
  end
end
