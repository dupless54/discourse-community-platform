# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class TopicPreviews
      EXCERPT_LENGTH = 280

      def self.call(topics:, guardian:)
        new(topics:, guardian:).call
      end

      def initialize(topics:, guardian:)
        @topics = topics
        @guardian = guardian
      end

      def call
        topic_ids = @topics.map(&:id).uniq
        return {} if topic_ids.empty?

        preview_topics =
          Topic
            .where(id: topic_ids)
            .includes(:image_upload, topic_thumbnails: :optimized_image)
            .index_by(&:id)

        first_posts =
          Post
            .where(
              topic_id: topic_ids,
              post_number: 1,
              deleted_at: nil,
              hidden: false,
              post_type: Post.types[:regular],
            )
            .index_by(&:topic_id)

        topic_ids.to_h do |topic_id|
          topic = preview_topics[topic_id]
          post = first_posts[topic_id]

          [topic_id, preview_for(topic, post)]
        end
      end

      private

      def preview_for(topic, post)
        return empty_preview if topic.blank? || post.blank? || !@guardian.can_see_post?(post)

        {
          excerpt: plain_excerpt(post),
          image_url: visible_image_url(topic),
        }
      end

      def plain_excerpt(post)
        excerpt = post.excerpt(EXCERPT_LENGTH, strip_links: true)
        return if excerpt.blank?

        Nokogiri::HTML5.fragment(excerpt).text.squish.presence
      end

      def visible_image_url(topic)
        upload = topic.image_upload
        return if upload.blank? || !@guardian.can_see_upload?(upload)

        topic.image_url(enqueue_if_missing: false)
      end

      def empty_preview
        { excerpt: nil, image_url: nil }
      end
    end
  end
end
