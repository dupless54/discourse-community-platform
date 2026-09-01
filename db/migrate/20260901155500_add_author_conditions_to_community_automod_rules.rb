# frozen_string_literal: true

class AddAuthorConditionsToCommunityAutomodRules < ActiveRecord::Migration[7.0]
  def change
    add_column :discourse_community_platform_automod_rules, :max_account_age_days, :integer
    add_column :discourse_community_platform_automod_rules, :max_trust_level, :integer
  end
end
