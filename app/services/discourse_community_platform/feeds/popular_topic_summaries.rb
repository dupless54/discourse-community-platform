# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class PopularTopicSummaries
      DEFAULT_LIMIT = 5
      MAX_LIMIT = 8

      def self.call(guardian:, limit: DEFAULT_LIMIT)
        new(guardian:, limit:).call
      end

      def initialize(guardian:, limit:)
        @guardian = guardian
        @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
      end

      def call
        topic_ids = Discourse.cache.read(PopularTopics::CACHE_KEY).presence || []
        return [] if topic_ids.empty?

        topics_by_id = Topic.where(id: topic_ids).includes(:category).index_by(&:id)
        topics =
          topic_ids.filter_map do |topic_id|
            topic = topics_by_id[topic_id]
            topic if topic && @guardian.can_see_topic?(topic)
          end.first(@limit)

        scores = TopicScore.where(topic_id: topics.map(&:id)).index_by(&:topic_id)
        communities =
          Community
            .where(category_id: topics.map(&:category_id))
            .includes(:icon_upload)
            .index_by(&:category_id)

        topics.filter_map do |topic|
          community = communities[topic.category_id]
          next if community.blank? || !community.public?

          {
            id: topic.id,
            title: topic.title,
            path: topic.relative_url,
            posts_count: topic.posts_count,
            score: scores[topic.id]&.score || 0,
            community: community_identity(community),
          }
        end
      end

      private

      def community_identity(community)
        icon_upload = community.icon_upload
        icon_url = icon_upload&.url if icon_upload.blank? || @guardian.can_see_upload?(icon_upload)

        {
          id: community.id,
          name: community.name,
          slug: community.slug,
          path: "/s/#{community.slug}",
          icon_emoji: community.icon_emoji,
          icon_url:,
        }
      end
    end
  end
end
