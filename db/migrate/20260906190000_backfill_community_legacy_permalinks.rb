# frozen_string_literal: true

class BackfillCommunityLegacyPermalinks < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      INSERT INTO permalinks (url, category_id, created_at, updated_at)
      SELECT
        's/' || communities.slug,
        communities.category_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM discourse_community_platform_communities AS communities
      WHERE NOT EXISTS (
        SELECT 1
        FROM permalinks
        WHERE permalinks.url = 's/' || communities.slug
      )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
