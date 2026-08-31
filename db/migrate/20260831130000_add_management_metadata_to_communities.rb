# frozen_string_literal: true

class AddManagementMetadataToCommunities < ActiveRecord::Migration[7.2]
  def change
    change_table :discourse_community_platform_communities, bulk: true do |t|
      t.jsonb :rules, null: false, default: []
      t.string :icon_emoji, limit: 64
      t.string :banner_color, limit: 6
    end
  end
end
