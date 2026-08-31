# frozen_string_literal: true

class AddVoteRankingIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :discourse_community_platform_votes,
              %i[community_id updated_at],
              name: "idx_dcp_votes_community_updated"
  end
end
