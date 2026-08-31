# frozen_string_literal: true

class CreateDiscourseCommunityPlatformCommunities < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_community_platform_communities do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :visibility, null: false, default: "public"

      t.integer :category_id, null: false
      t.integer :owner_id, null: false
      t.integer :member_group_id
      t.integer :moderator_group_id
      t.integer :icon_upload_id
      t.integer :banner_upload_id

      t.integer :members_count, null: false, default: 0
      t.timestamps null: false
    end

    add_index :discourse_community_platform_communities,
              :slug,
              unique: true,
              name: "idx_dcp_communities_slug"
    add_index :discourse_community_platform_communities,
              :category_id,
              unique: true,
              name: "idx_dcp_communities_category"
    add_index :discourse_community_platform_communities,
              :owner_id,
              name: "idx_dcp_communities_owner"
    add_index :discourse_community_platform_communities,
              :member_group_id,
              name: "idx_dcp_communities_member_group"
    add_index :discourse_community_platform_communities,
              :moderator_group_id,
              name: "idx_dcp_communities_mod_group"
  end
end
