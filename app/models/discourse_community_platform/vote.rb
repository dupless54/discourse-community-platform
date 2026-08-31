# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class Vote < ::ActiveRecord::Base
    self.table_name = "discourse_community_platform_votes"

    VALUES = [-1, 1].freeze

    belongs_to :community, class_name: "::DiscourseCommunityPlatform::Community"
    belongs_to :topic, class_name: "::Topic"
    belongs_to :user, class_name: "::User"

    validates :value, inclusion: { in: VALUES }
    validates :user_id, uniqueness: { scope: :topic_id }
  end
end
