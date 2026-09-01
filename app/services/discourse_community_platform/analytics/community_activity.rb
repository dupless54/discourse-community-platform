# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Analytics
    class CommunityActivity
      CACHE_KEY = "discourse-community-platform:community-activity-analytics:v1"
      CACHE_TTL = 30.minutes
      WINDOW_7_DAYS = 7.days
      WINDOW_30_DAYS = 30.days

      class << self
        def call(community:)
          cached_snapshots[community.id] || warming_snapshot
        end

        def rebuild_cache(now: Time.current)
          snapshots =
            Community.pluck(:id).to_h { |community_id| [community_id, ready_snapshot(now)] }

          apply_topic_metrics!(snapshots, now:)
          apply_post_metrics!(snapshots, now:)

          Discourse.cache.write(CACHE_KEY, snapshots, expires_in: CACHE_TTL)
          snapshots
        end

        def cached_snapshots
          Discourse.cache.read(CACHE_KEY) || {}
        end

        private

        def apply_topic_metrics!(snapshots, now:)
          cutoff_7_days = now - WINDOW_7_DAYS
          cutoff_30_days = now - WINDOW_30_DAYS
          quoted_7_days = ActiveRecord::Base.connection.quote(cutoff_7_days)

          topic_scope(cutoff_30_days)
            .group("dcp_activity_communities.id")
            .pluck(
              Arel.sql("dcp_activity_communities.id"),
              Arel.sql(
                "SUM(CASE WHEN topics.created_at >= #{quoted_7_days} THEN 1 ELSE 0 END)",
              ),
              Arel.sql("COUNT(*)"),
            )
            .each do |community_id, topics_7_days, topics_30_days|
              snapshot = snapshots[community_id.to_i]
              next if snapshot.blank?

              snapshot[:last_7_days][:new_topics] = topics_7_days.to_i
              snapshot[:last_30_days][:new_topics] = topics_30_days.to_i
            end
        end

        def apply_post_metrics!(snapshots, now:)
          cutoff_7_days = now - WINDOW_7_DAYS
          cutoff_30_days = now - WINDOW_30_DAYS
          quoted_7_days = ActiveRecord::Base.connection.quote(cutoff_7_days)

          post_scope(cutoff_30_days)
            .group("dcp_activity_communities.id")
            .pluck(
              Arel.sql("dcp_activity_communities.id"),
              Arel.sql(
                "SUM(CASE WHEN posts.created_at >= #{quoted_7_days} THEN 1 ELSE 0 END)",
              ),
              Arel.sql("COUNT(*)"),
              Arel.sql(
                "SUM(CASE WHEN posts.created_at >= #{quoted_7_days} AND posts.post_number > 1 THEN 1 ELSE 0 END)",
              ),
              Arel.sql("SUM(CASE WHEN posts.post_number > 1 THEN 1 ELSE 0 END)"),
              Arel.sql(
                "COUNT(DISTINCT CASE WHEN posts.created_at >= #{quoted_7_days} THEN posts.topic_id END)",
              ),
              Arel.sql("COUNT(DISTINCT posts.topic_id)"),
              Arel.sql(
                "COUNT(DISTINCT CASE WHEN posts.created_at >= #{quoted_7_days} THEN posts.user_id END)",
              ),
              Arel.sql("COUNT(DISTINCT posts.user_id)"),
            )
            .each do |row|
              community_id,
                posts_7_days,
                posts_30_days,
                replies_7_days,
                replies_30_days,
                active_topics_7_days,
                active_topics_30_days,
                contributors_7_days,
                contributors_30_days = row
              snapshot = snapshots[community_id.to_i]
              next if snapshot.blank?

              snapshot[:last_7_days].merge!(
                posts: posts_7_days.to_i,
                replies: replies_7_days.to_i,
                active_topics: active_topics_7_days.to_i,
                contributors: contributors_7_days.to_i,
              )
              snapshot[:last_30_days].merge!(
                posts: posts_30_days.to_i,
                replies: replies_30_days.to_i,
                active_topics: active_topics_30_days.to_i,
                contributors: contributors_30_days.to_i,
              )
            end
        end

        def topic_scope(cutoff)
          Topic
            .where(deleted_at: nil, visible: true, archetype: Archetype.default)
            .where("topics.created_at >= ?", cutoff)
            .where.not(user_id: Discourse.system_user.id)
            .where.not(id: category_topic_ids)
            .joins(
              <<~SQL.squish,
                INNER JOIN discourse_community_platform_communities dcp_activity_communities
                  ON dcp_activity_communities.category_id = topics.category_id
              SQL
            )
        end

        def post_scope(cutoff)
          Post
            .joins(:topic)
            .where(posts: { deleted_at: nil, post_type: Post.types[:regular] })
            .where("posts.created_at >= ?", cutoff)
            .where(topics: { deleted_at: nil, visible: true, archetype: Archetype.default })
            .where.not(posts: { user_id: Discourse.system_user.id, topic_id: category_topic_ids })
            .joins(
              <<~SQL.squish,
                INNER JOIN discourse_community_platform_communities dcp_activity_communities
                  ON dcp_activity_communities.category_id = topics.category_id
              SQL
            )
        end

        def category_topic_ids
          Category.where.not(topic_id: nil).select(:topic_id)
        end

        def ready_snapshot(now)
          {
            status: "ready",
            generated_at: now,
            last_7_days: empty_period,
            last_30_days: empty_period,
          }
        end

        def warming_snapshot
          {
            status: "warming",
            generated_at: nil,
            last_7_days: empty_period,
            last_30_days: empty_period,
          }
        end

        def empty_period
          { new_topics: 0, posts: 0, replies: 0, active_topics: 0, contributors: 0 }
        end
      end
    end
  end
end
