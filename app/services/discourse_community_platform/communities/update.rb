# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Communities
    class Update
      MAX_DESCRIPTION_LENGTH = 1000
      BRANDING_UPLOAD_FIELDS = %i[icon_upload_id banner_upload_id].freeze

      def self.call(user:, community:, params:)
        new(user:, community:, params:).call
      end

      def initialize(user:, community:, params:)
        @user = user
        @community = community
        @params = params.to_h.symbolize_keys
      end

      def call
        CommunityAuthorization.ensure_can_manage!(@user, @community)

        attributes = normalized_attributes
        next_visibility = attributes[:visibility] || @community.visibility
        previous_branding_upload_ids = branding_upload_ids

        Community.transaction do
          if next_visibility != @community.visibility
            Permissions::Apply.call(
              category: @community.category,
              visibility: next_visibility,
              member_group: @community.member_group,
              moderator_group: @community.moderator_group,
            )
          end

          if attributes.key?(:description) && attributes[:description] != @community.description
            @community.category.update!(description: attributes[:description])
          end

          @community.update!(attributes)
          sync_branding_upload_references(previous_branding_upload_ids)
        end

        @community.reload
      end

      private

      def normalized_attributes
        attributes = {}

        if @params.key?(:description)
          description = @params[:description].to_s.strip.presence
          raise Discourse::InvalidParameters.new(:description) if description&.length.to_i > MAX_DESCRIPTION_LENGTH
          attributes[:description] = description
        end

        if @params.key?(:visibility)
          visibility = @params[:visibility].to_s
          raise Discourse::InvalidParameters.new(:visibility) if Community::VISIBILITIES.exclude?(visibility)
          attributes[:visibility] = visibility
        end

        if @params.key?(:rules)
          rules = @params[:rules]
          raise Discourse::InvalidParameters.new(:rules) unless rules.is_a?(Array)
          attributes[:rules] = rules.map { |rule| rule.to_s.strip }
        end

        attributes[:icon_emoji] = @params[:icon_emoji].to_s.strip.presence if @params.key?(:icon_emoji)
        attributes[:banner_color] = @params[:banner_color].to_s.strip.presence if @params.key?(:banner_color)

        BRANDING_UPLOAD_FIELDS.each do |field|
          attributes[field] = normalized_branding_upload_id(field) if @params.key?(field)
        end

        attributes
      end

      def normalized_branding_upload_id(field)
        value = @params[field]
        return nil if value.blank?

        upload_id = Integer(value, 10)
        upload = Upload.find_by(id: upload_id)
        raise Discourse::InvalidParameters.new(field) if upload.blank?
        raise Discourse::InvalidParameters.new(field) unless FileHelper.is_supported_image?(upload.original_filename)

        existing_ids = branding_upload_ids
        unless @user.staff? || upload.user_id == @user.id || existing_ids.include?(upload.id)
          raise Discourse::InvalidParameters.new(field)
        end

        upload.id
      rescue ArgumentError, TypeError
        raise Discourse::InvalidParameters.new(field)
      end

      def branding_upload_ids
        [@community.icon_upload_id, @community.banner_upload_id].compact.uniq
      end

      def sync_branding_upload_references(previous_upload_ids)
        current_upload_ids = branding_upload_ids
        removed_upload_ids = previous_upload_ids - current_upload_ids

        if removed_upload_ids.any?
          UploadReference.where(target: @community, upload_id: removed_upload_ids).delete_all
        end

        current_upload_ids.each do |upload_id|
          UploadReference.find_or_create_by!(target: @community, upload_id: upload_id)
        end
      end
    end
  end
end
