# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class ExploreTopics < PopularTopics
      CANDIDATE_MULTIPLIER = 6
      MAX_TOPICS_PER_COMMUNITY = 2

      def call
        candidate_ids =
          PopularTopics.cached_topic_ids.first(
            [@limit * CANDIDATE_MULTIPLIER, PopularTopics::CANDIDATE_LIMIT].min,
          )
        topics_by_id = Topic.where(id: candidate_ids).includes(:category).index_by(&:id)
        communities =
          Community
            .where(category_id: topics_by_id.values.map(&:category_id), visibility: "public")
            .index_by(&:category_id)
        joined_category_ids = joined_category_ids_for(@guardian.user)
        community_counts = Hash.new(0)
        ranked_candidate_ids = rank_candidates(candidate_ids, topics_by_id, communities)

        topics =
          ranked_candidate_ids.filter_map do |topic_id|
            topic = topics_by_id[topic_id]
            community = communities[topic&.category_id]
            next if topic.blank? || community.blank?
            next if joined_category_ids[topic.category_id]
            next unless @guardian.can_see_topic?(topic)
            next if community_counts[community.id] >= MAX_TOPICS_PER_COMMUNITY

            community_counts[community.id] += 1
            [topic, community]
          end.first(@limit)

        serialize_topics(topics)
      end

      private

      def rank_candidates(candidate_ids, topics_by_id, communities)
        recommendation_rank =
          ExploreCommunities.cached_signals.each_with_index.to_h do |signal, index|
            [signal.first, index]
          end
        popular_rank = candidate_ids.each_with_index.to_h

        candidate_ids.sort_by do |topic_id|
          community = communities[topics_by_id[topic_id]&.category_id]

          [
            recommendation_rank.fetch(community&.id, recommendation_rank.length),
            popular_rank.fetch(topic_id),
          ]
        end
      end

      def joined_category_ids_for(user)
        return {} if user.blank?

        group_ids = GroupUser.where(user_id: user.id).pluck(:group_id)
        return {} if group_ids.empty?

        Community
          .where(member_group_id: group_ids)
          .pluck(:category_id)
          .to_h { |category_id| [category_id, true] }
      end

      def serialize_topics(topic_communities)
        topics = topic_communities.map(&:first)
        scores = TopicScore.where(topic_id: topics.map(&:id)).index_by(&:topic_id)
        votes = user_votes(topics)

        topic_communities.map do |topic, community|
          score = scores[topic.id]

          {
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
            community: {
              id: community.id,
              name: community.name,
              slug: community.slug,
              path: "/s/#{community.slug}",
            },
          }
        end
      end
    end
  end
end
