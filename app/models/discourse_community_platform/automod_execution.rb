# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class AutomodExecution < ActiveRecord::Base
    self.table_name = "discourse_community_platform_automod_executions"

    TRIGGERS = %w[create edit].freeze
    OUTCOMES = %w[queued_for_review already_queued].freeze
    RETENTION_DAYS = 90

    belongs_to :community, class_name: "DiscourseCommunityPlatform::Community"
    belongs_to :automod_rule, class_name: "DiscourseCommunityPlatform::AutomodRule", optional: true
    belongs_to :post

    validates :rule_name, presence: true
    validates :trigger, inclusion: { in: TRIGGERS }
    validates :outcome, inclusion: { in: OUTCOMES }
    validates :content_sha256, presence: true, length: { is: 64 }
  end
end

# == Schema Information
#
# Table name: discourse_community_platform_automod_executions
#
#  id              :bigint           not null, primary key
#  content_sha256  :string(64)       not null
#  outcome         :string           not null
#  rule_name       :string           not null
#  trigger         :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  automod_rule_id :bigint           not null
#  community_id    :bigint           not null
#  post_id         :bigint           not null
#
# Indexes
#
#  idx_dcp_automod_exec_community_created  (community_id,created_at)
#  idx_dcp_automod_exec_post               (post_id)
#  idx_dcp_automod_exec_unique_content     (automod_rule_id,post_id,content_sha256) UNIQUE
#
