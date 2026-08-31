# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class TopicScore < ::ActiveRecord::Base
    self.table_name = "discourse_community_platform_topic_scores"

    belongs_to :community, class_name: "::DiscourseCommunityPlatform::Community"
    belongs_to :topic, class_name: "::Topic"

    validates :topic_id, uniqueness: true
    validates :upvotes, :downvotes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :score, numericality: { only_integer: true }
  end
end
