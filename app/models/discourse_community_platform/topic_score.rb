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

# == Schema Information
#
# Table name: discourse_community_platform_topic_scores
#
#  id           :bigint           not null, primary key
#  downvotes    :integer          default(0), not null
#  hot_score    :decimal(20, 8)   default(0.0), not null
#  score        :integer          default(0), not null
#  upvotes      :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  community_id :integer          not null
#  topic_id     :integer          not null
#
# Indexes
#
#  idx_dcp_topic_scores_community_hot    (community_id,hot_score)
#  idx_dcp_topic_scores_community_score  (community_id,score)
#  idx_dcp_topic_scores_topic            (topic_id) UNIQUE
#
