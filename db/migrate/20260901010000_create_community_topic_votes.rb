# frozen_string_literal: true

class CreateCommunityTopicVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :discourse_community_platform_votes do |t|
      t.integer :community_id, null: false
      t.integer :topic_id, null: false
      t.integer :user_id, null: false
      t.integer :value, null: false, limit: 2
      t.timestamps null: false
    end

    add_index :discourse_community_platform_votes,
              %i[user_id topic_id],
              unique: true,
              name: "idx_dcp_votes_user_topic"
    add_index :discourse_community_platform_votes,
              %i[community_id topic_id],
              name: "idx_dcp_votes_community_topic"
    add_index :discourse_community_platform_votes,
              :topic_id,
              name: "idx_dcp_votes_topic"

    add_check_constraint :discourse_community_platform_votes,
                         "value IN (-1, 1)",
                         name: "dcp_votes_value"

    create_table :discourse_community_platform_topic_scores do |t|
      t.integer :community_id, null: false
      t.integer :topic_id, null: false
      t.integer :upvotes, null: false, default: 0
      t.integer :downvotes, null: false, default: 0
      t.integer :score, null: false, default: 0
      t.decimal :hot_score, null: false, default: 0, precision: 20, scale: 8
      t.timestamps null: false
    end

    add_index :discourse_community_platform_topic_scores,
              :topic_id,
              unique: true,
              name: "idx_dcp_topic_scores_topic"
    add_index :discourse_community_platform_topic_scores,
              %i[community_id score],
              name: "idx_dcp_topic_scores_community_score"
    add_index :discourse_community_platform_topic_scores,
              %i[community_id hot_score],
              name: "idx_dcp_topic_scores_community_hot"
  end
end
