# frozen_string_literal: true

class CreateCommunityAutomodExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_community_platform_automod_executions do |t|
      t.bigint :community_id, null: false
      t.bigint :automod_rule_id, null: false
      t.bigint :post_id, null: false
      t.string :rule_name, null: false
      t.string :trigger, null: false
      t.string :outcome, null: false
      t.string :content_sha256, null: false, limit: 64
      t.timestamps null: false
    end

    add_index :discourse_community_platform_automod_executions,
              %i[community_id created_at],
              name: "idx_dcp_automod_exec_community_created"
    add_index :discourse_community_platform_automod_executions,
              :post_id,
              name: "idx_dcp_automod_exec_post"
    add_index :discourse_community_platform_automod_executions,
              %i[automod_rule_id post_id content_sha256],
              unique: true,
              name: "idx_dcp_automod_exec_unique_content"
  end
end
