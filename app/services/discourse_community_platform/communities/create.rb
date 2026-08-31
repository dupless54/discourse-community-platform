# frozen_string_literal: true

require "digest/sha1"

module ::DiscourseCommunityPlatform
  module Communities
    class Create
      MAX_NAME_LENGTH = 100
      MAX_DESCRIPTION_LENGTH = 1000

      def self.call(user:, params:)
        new(user:, params:).call
      end

      def initialize(user:, params:)
        @user = user
        @params = params.to_h.symbolize_keys
      end

      def call
        ensure_creation_allowed!

        name = @params[:name].to_s.strip
        description = @params[:description].to_s.strip.presence
        visibility = @params[:visibility].presence || "public"
        slug = ::Slug.for(@params[:slug].presence || name)

        raise Discourse::InvalidParameters.new(:name) if name.blank? || name.length > MAX_NAME_LENGTH
        raise Discourse::InvalidParameters.new(:slug) if slug.blank?
        raise Discourse::InvalidParameters.new(:description) if description&.length.to_i > MAX_DESCRIPTION_LENGTH
        raise Discourse::InvalidParameters.new(:visibility) if Community::VISIBILITIES.exclude?(visibility)
        raise Discourse::InvalidParameters.new(:slug) if Community.where("LOWER(slug) = ?", slug.downcase).exists?

        Community.transaction do
          member_group = create_group(slug:, suffix: "members", owner: false)
          moderator_group = create_group(slug:, suffix: "mods", owner: true)
          category = create_category(name:, slug:, description:)

          configure_category_permissions(
            category:,
            visibility:,
            member_group:,
            moderator_group:,
          )

          CategoryModerationGroup.create!(category:, group: moderator_group)

          Community.create!(
            name:,
            slug:,
            description:,
            visibility:,
            category:,
            owner: @user,
            member_group:,
            moderator_group:,
            members_count: 1,
          )
        end
      end

      private

      def ensure_creation_allowed!
        raise Discourse::InvalidAccess if @user.blank?
        raise Discourse::InvalidAccess if @user.staged? || @user.suspended? || @user.silenced?
        return if @user.admin?

        raise Discourse::InvalidAccess unless SiteSetting.community_platform_allow_user_community_creation
        raise Discourse::InvalidAccess if @user.trust_level < SiteSetting.community_platform_min_trust_level_to_create

        owned_count = Community.where(owner_id: @user.id).count
        raise Discourse::InvalidAccess if owned_count >= SiteSetting.community_platform_max_communities_per_user
      end

      def create_group(slug:, suffix:, owner:)
        group =
          Group.new(
            name: group_name(slug, suffix),
            visibility_level: Group.visibility_levels[owner ? :owners : :members],
            members_visibility_level: Group.visibility_levels[:members],
            mentionable_level: Group::ALIAS_LEVELS[:nobody],
            messageable_level: Group::ALIAS_LEVELS[:nobody],
            public_admission: false,
            public_exit: false,
          )

        group.group_users.build(user: @user, owner:)
        group.save!
        group
      end

      def group_name(slug, suffix)
        stem = slug.tr("-", "_").gsub(/[^a-z0-9_]/, "_").first(18)
        digest = Digest::SHA1.hexdigest(slug).first(8)
        "dcp_#{stem}_#{digest}_#{suffix}"
      end

      def create_category(name:, slug:, description:)
        Category.create!(
          name:,
          slug:,
          description:,
          user: Discourse.system_user,
          color: "0088CC",
          text_color: "FFFFFF",
        )
      end

      def configure_category_permissions(category:, visibility:, member_group:, moderator_group:)
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
      end
    end
  end
end
