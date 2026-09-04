# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class Community < ::ActiveRecord::Base
    self.table_name = "discourse_community_platform_communities"

    VISIBILITIES = %w[public restricted private].freeze
    MAX_RULES = 15
    MAX_RULE_LENGTH = 200

    belongs_to :category, class_name: "::Category"
    belongs_to :owner, class_name: "::User"
    belongs_to :member_group, class_name: "::Group", optional: true
    belongs_to :moderator_group, class_name: "::Group", optional: true
    belongs_to :icon_upload, class_name: "::Upload", optional: true
    belongs_to :banner_upload, class_name: "::Upload", optional: true

    before_validation :normalize_slug
    before_validation :normalize_banner_color

    validates :name, presence: true, length: { maximum: 100 }
    validates :slug, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
    validates :category_id, uniqueness: true
    validates :visibility, inclusion: { in: VISIBILITIES }
    validates :members_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :icon_emoji, length: { maximum: 64 }, allow_blank: true
    validates :banner_color,
              format: { with: /\A[0-9A-F]{6}\z/ },
              allow_blank: true

    validate :rules_are_valid

    scope :publicly_visible, -> { where(visibility: "public") }

    def path
      category.url
    end

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

    def normalize_banner_color
      self.banner_color = banner_color.to_s.delete_prefix("#").upcase.presence
    end

    def rules_are_valid
      unless rules.is_a?(Array)
        errors.add(:rules, :invalid)
        return
      end

      errors.add(:rules, :too_long, count: MAX_RULES) if rules.length > MAX_RULES

      if rules.any? { |rule| !rule.is_a?(String) || rule.blank? || rule.length > MAX_RULE_LENGTH }
        errors.add(:rules, :invalid)
      end
    end
  end
end

# == Schema Information
#
# Table name: discourse_community_platform_communities
#
#  id                 :bigint           not null, primary key
#  banner_color       :string(6)
#  description        :text
#  icon_emoji         :string(64)
#  members_count      :integer          default(0), not null
#  name               :string           not null
#  rules              :jsonb            not null
#  slug               :string           not null
#  visibility         :string           default("public"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  banner_upload_id   :integer
#  category_id        :integer          not null
#  icon_upload_id     :integer
#  member_group_id    :integer
#  moderator_group_id :integer
#  owner_id           :integer          not null
#
# Indexes
#
#  idx_dcp_communities_category      (category_id) UNIQUE
#  idx_dcp_communities_member_group  (member_group_id)
#  idx_dcp_communities_mod_group     (moderator_group_id)
#  idx_dcp_communities_owner         (owner_id)
#  idx_dcp_communities_slug          (slug) UNIQUE
#
