# frozen_string_literal: true

class AddScopeAndActionToCommunityAutomodRules < ActiveRecord::Migration[7.0]
  def change
    add_column :discourse_community_platform_automod_rules,
               :target,
               :string,
               null: false,
               default: "all_posts"
    add_column :discourse_community_platform_automod_rules,
               :action,
               :string,
               null: false,
               default: "queue_for_review"
  end
end
