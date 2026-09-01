# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class AutomodRule < ActiveRecord::Base
    MATCH_MODES = %w[any all].freeze
    MAX_NAME_LENGTH = 80
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
  end
end
