# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class AutomodRule < ActiveRecord::Base
    self.table_name = "discourse_community_platform_automod_rules"

    MATCH_MODES = %w[any all].freeze
    MAX_NAME_LENGTH = 80
    MAX_RULES_PER_COMMUNITY = 25
    MAX_TERMS = 20
    MAX_TERM_LENGTH = 80

    belongs_to :community, class_name: "DiscourseCommunityPlatform::Community"
    belongs_to :created_by, class_name: "User"
    belongs_to :updated_by, class_name: "User"

    before_validation :normalize_terms

    validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
    validates :match_mode, inclusion: { in: MATCH_MODES }
    validates :terms, presence: true
    validate :validate_terms
    validate :validate_community_rule_limit, on: :create

    def matches?(text)
      haystack = text.to_s.downcase
      normalized_terms = terms.map { |term| term.to_s.downcase }

      if match_mode == "all"
        normalized_terms.all? { |term| haystack.include?(term) }
      else
        normalized_terms.any? { |term| haystack.include?(term) }
      end
    end

    private

    def normalize_terms
      self.terms = Array(terms).map { |term| term.to_s.strip.downcase }.reject(&:blank?).uniq
    end

    def validate_terms
      return errors.add(:terms, :blank) if terms.blank?

      errors.add(:terms, :too_many) if terms.length > MAX_TERMS
      errors.add(:terms, :too_long) if terms.any? { |term| term.length > MAX_TERM_LENGTH }
    end

    def validate_community_rule_limit
      return if community_id.blank?
      return if self.class.where(community_id:).count < MAX_RULES_PER_COMMUNITY

      errors.add(
        :base,
        I18n.t(
          "community_platform.automod.too_many_rules",
          count: MAX_RULES_PER_COMMUNITY,
        ),
      )
    end
  end
end

# == Schema Information
#
# Table name: discourse_community_platform_automod_rules
#
#  id            :bigint           not null, primary key
#  enabled       :boolean          default(TRUE), not null
#  match_mode    :string           default("any"), not null
#  name          :string           not null
#  terms         :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  community_id  :bigint           not null
#  created_by_id :bigint           not null
#  updated_by_id :bigint           not null
#
# Indexes
#
#  idx_dcp_automod_rules_community_enabled  (community_id,enabled)
#  idx_dcp_automod_rules_created_by         (created_by_id)
#  idx_dcp_automod_rules_updated_by         (updated_by_id)
#