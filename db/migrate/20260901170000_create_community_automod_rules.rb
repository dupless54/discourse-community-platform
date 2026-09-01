# frozen_string_literal: true

class CreateCommunityAutomodRules < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_community_platform_automod_rules do |t|
      t.bigint :community_id, null: false
      t.string :name, null: false
      t.boolean :enabled, null: false, default: true
      t.string :match_mode, null: false, default: "any"
      t.jsonb :terms, null: false, default: []
      t.bigint :created_by_id, null: false
      t.bigint :updated_by_id, null: false
      t.timestamps null: false
    end

    add_index :discourse_community_platform_automod_rules,
              %i[community_id enabled],
              name: "idx_dcp_automod_rules_community_enabled"
    add_index :discourse_community_platform_automod_rules,
              :created_by_id,
              name: "idx_dcp_automod_rules_created_by"
    add_index :discourse_community_platform_automod_rules,
              :updated_by_id,
              name: "idx_dcp_automod_rules_updated_by"
  end
end
