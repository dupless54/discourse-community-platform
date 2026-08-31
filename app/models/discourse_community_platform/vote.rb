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

# == Schema Information
#
# Table name: discourse_community_platform_votes
#
#  id           :bigint           not null, primary key
#  value        :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  community_id :integer          not null
#  topic_id     :bigint           not null
#  user_id      :integer          not null
#
# Indexes
#
#  idx_dcp_votes_community_topic  (community_id,topic_id)
#  idx_dcp_votes_topic            (topic_id)
#  idx_dcp_votes_user_topic       (user_id,topic_id) UNIQUE
#
