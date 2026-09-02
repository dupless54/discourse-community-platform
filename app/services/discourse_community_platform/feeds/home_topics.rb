# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class HomeTopics
      DEFAULT_LIMIT = PopularTopics::DEFAULT_LIMIT
      MAX_LIMIT = PopularTopics::MAX_LIMIT
      CANDIDATE_MULTIPLIER = 3
      FOLLOWED_TOPIC_RATIO = 0.25

      def self.call(guardian:, limit: DEFAULT_LIMIT)
        new(guardian:, limit:).call
      end

      def initialize(guardian:, limit:)
        @guardian = guardian
        @limit = [[limit.to_i, 1].max, MAX_LIMIT].min
      end

      def call
        user = @guardian.user
        return popular_fallback_payload if user.blank?

        communities = visible_joined_communities(user)
        joined_topics = ranked_joined_topics(communities)
        joined_items = serialize_joined(joined_topics, communities)

        followed_topics = followed_user_topics(user)
        followed_items = serialize_followed(followed_topics)
        followed_items = remove_duplicates(followed_items, joined_items)
        followed_items = followed_items.first(followed_topic_limit(joined_items))

        joined_items = joined_items.first(@limit - followed_items.length)
        personalized_items = joined_items + followed_items

        return popular_fallback_payload if communities.empty? && followed_items.empty?

        fallback_items = popular_fallback(personalized_items)

        payload(
          topics: (personalized_items + fallback_items).first(@limit),
          communities:,
          personalized: true,
        )
      end

      private

      def visible_joined_communities(user)
        group_ids = ::GroupUser.where(user_id: user.id).pluck(:group_id)
        return [] if group_ids.empty?

        Community
          .where(member_group_id: group_ids)
          .includes(:category, :icon_upload)
          .order(:id)
          .select { |community| @guardian.can_see_category?(community.category) }
      end

      def ranked_joined_topics(communities)
        return [] if communities.empty?

        category_ids = communities.map(&:category_id)
        category_topic_ids = communities.filter_map { |community| community.category.topic_id }

        scope =
          Topic
            .where(category_id: category_ids, deleted_at: nil, visible: true)
            .where(archetype: Archetype.default)
            .includes(:user)
            .joins(
              <<~SQL.squish,
                LEFT JOIN discourse_community_platform_topic_scores dcp_home_scores
                  ON dcp_home_scores.topic_id = topics.id
              SQL
            )

        scope = scope.where.not(id: category_topic_ids) if category_topic_ids.any?

        topics =
          scope
            .order(
              Arel.sql(
                "COALESCE(dcp_home_scores.hot_score, " \
                  "(EXTRACT(EPOCH FROM topics.created_at) - #{CommunityTopics::HOT_EPOCH_SECONDS}) / 45000.0) DESC, " \
                  "topics.id DESC",
              ),
            )
            .limit(@limit * CANDIDATE_MULTIPLIER)
            .to_a

        topics.select! { |topic| @guardian.can_see_topic?(topic) }
        topics.first(@limit)
      end

      def followed_user_topics(user)
        return [] unless follow_integration_available?

        topics =
          ::UserFollower
            .topics_for(
              user,
              current_user: user,
              limit: @limit * CANDIDATE_MULTIPLIER,
            )
            .to_a

        ActiveRecord::Associations::Preloader.new(records: topics, associations: :user).call if topics.any?

        communities =
          Community.where(category_id: topics.map(&:category_id)).includes(:category).index_by(&:category_id)

        topics.select do |topic|
          community = communities[topic.category_id]
          community.present? && topic.id != community.category.topic_id && @guardian.can_see_topic?(topic)
        end.first(@limit)
      end

      def follow_integration_available?
        return false unless defined?(::UserFollower)

        SiteSetting.discourse_follow_enabled
      rescue NoMethodError
        false
      end

      def followed_topic_limit(joined_items)
        return @limit if joined_items.empty?

        (@limit * FOLLOWED_TOPIC_RATIO).floor
      end

      def serialize_joined(topics, communities)
        scores = TopicScore.where(topic_id: topics.map(&:id)).index_by(&:topic_id)
        communities_by_category = communities.index_by(&:category_id)
        votes = user_votes(topics)
        previews = TopicPreviews.call(topics:, guardian: @guardian)

        topics.filter_map do |topic|
          community = communities_by_category[topic.category_id]
          next if community.blank?

          serialize_topic(
            topic,
            community,
            scores[topic.id],
            votes,
            previews,
            feed_source: "joined",
          )
        end
      end

      def serialize_followed(topics)
        scores = TopicScore.where(topic_id: topics.map(&:id)).index_by(&:topic_id)
        communities =
          Community
            .where(category_id: topics.map(&:category_id))
            .includes(:icon_upload)
            .index_by(&:category_id)
        votes = user_votes(topics)
        previews = TopicPreviews.call(topics:, guardian: @guardian)

        topics.filter_map do |topic|
          community = communities[topic.category_id]
          next if community.blank?

          serialize_topic(
            topic,
            community,
            scores[topic.id],
            votes,
            previews,
            feed_source: "followed",
          )
        end
      end

      def serialize_topic(topic, community, score, votes, previews, feed_source:)
        preview = previews.fetch(topic.id, {})
        item = {
          id: topic.id,
          title: topic.title,
          slug: topic.slug,
          path: topic.relative_url,
          posts_count: topic.posts_count,
          views: topic.views,
          like_count: topic.like_count,
          created_at: topic.created_at,
          last_posted_at: topic.last_posted_at,
          score: score&.score || 0,
          upvotes: score&.upvotes || 0,
          downvotes: score&.downvotes || 0,
          user_vote: votes.fetch(topic.id, 0),
          excerpt: preview[:excerpt],
          image_url: preview[:image_url],
          feed_source:,
          community: community_identity(community),
        }

        item[:author] = topic_author(topic) if topic.user
        item
      end

      def topic_author(topic)
        {
          id: topic.user.id,
          username: topic.user.username,
          name: topic.user.name,
          avatar_template: topic.user.avatar_template,
          path: "/u/#{topic.user.username}",
        }
      end

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

      def remove_duplicates(items, existing_items)
        existing_ids = existing_items.to_h { |topic| [topic[:id], true] }
        items.reject { |topic| existing_ids[topic[:id]] }
      end

      def popular_fallback(existing_items)
        remaining = @limit - existing_items.length
        return [] unless remaining.positive?

        existing_ids = existing_items.to_h { |topic| [topic[:id], true] }

        PopularTopics
          .call(guardian: @guardian, limit: @limit)
          .filter_map do |topic|
            next if existing_ids[topic[:id]]

            topic.merge(feed_source: "popular")
          end
          .first(remaining)
      end

      def popular_fallback_payload
        topics = PopularTopics.call(guardian: @guardian, limit: @limit)
        payload(topics: mark_popular(topics), communities: [], personalized: false)
      end

      def user_votes(topics)
        user = @guardian.user
        return {} if user.blank? || topics.empty?

        Vote.where(user_id: user.id, topic_id: topics.map(&:id)).pluck(:topic_id, :value).to_h
      end

      def mark_popular(topics)
        topics.map { |topic| topic.merge(feed_source: "popular") }
      end

      def payload(topics:, communities:, personalized:)
        {
          order: "home",
          personalized:,
          joined_communities: communities.map { |community| community_identity(community) },
          topics:,
        }
      end
    end
  end
end
