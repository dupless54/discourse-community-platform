# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class Community < ::ActiveRecord::Base
    self.table_name = "discourse_community_platform_communities"

    VISIBILITIES = %w[public restricted private].freeze

    belongs_to :category, class_name: "::Category"
    belongs_to :owner, class_name: "::User"
    belongs_to :member_group, class_name: "::Group", optional: true
    belongs_to :moderator_group, class_name: "::Group", optional: true
    belongs_to :icon_upload, class_name: "::Upload", optional: true
    belongs_to :banner_upload, class_name: "::Upload", optional: true

    before_validation :normalize_slug

    validates :name, presence: true, length: { maximum: 100 }
    validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
    validates :category_id, uniqueness: true
    validates :visibility, inclusion: { in: VISIBILITIES }
    validates :members_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    scope :publicly_visible, -> { where(visibility: "public") }

    def public?
      visibility == "public"
    end

    def restricted?
      visibility == "restricted"
    end

    def private?
      visibility == "private"
    end

    private

    def normalize_slug
      source = slug.presence || name
      self.slug = ::Slug.for(source) if source.present?
    end
  end
end
