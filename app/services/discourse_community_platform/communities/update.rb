# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Communities
    class Update
      MAX_DESCRIPTION_LENGTH = 1000

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
        attributes
      end
    end
  end
end
