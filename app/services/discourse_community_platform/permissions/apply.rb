# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Permissions
    class Apply
      def self.call(category:, visibility:, member_group:, moderator_group:)
        raise Discourse::InvalidParameters.new(:visibility) if Community::VISIBILITIES.exclude?(visibility)
        raise Discourse::InvalidAccess if category.blank? || member_group.blank? || moderator_group.blank?

        permissions =
          case visibility
          when "public"
            { everyone: :full }
          when "restricted"
            { everyone: :readonly, member_group => :full, moderator_group => :full }
          when "private"
            { member_group => :full, moderator_group => :full }
          end

        category.set_permissions(permissions)
        category.save!
        category
      end
    end
  end
end
