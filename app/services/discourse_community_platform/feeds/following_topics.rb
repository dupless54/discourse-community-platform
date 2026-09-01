# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  module Feeds
    class FollowingTopics < HomeTopics
      DEFAULT_LIMIT = HomeTopics::DEFAULT_LIMIT

      def call
        user = @guardian.user
        return following_payload(topics: [], communities: [], login_required: true) if user.blank?

        communities = visible_joined_communities(user)
        joined_items = serialize_joined(ranked_joined_topics(communities), communities)
        followed_items = serialize_followed(followed_user_topics(user))
        followed_items = remove_duplicates(followed_items, joined_items)

        topics =
          (joined_items + followed_items)
            .sort_by { |topic| [topic[:created_at] || Time.at(0), topic[:id]] }
            .reverse
            .first(@limit)

        following_payload(topics:, communities:, login_required: false)
      end

      private

      def following_payload(topics:, communities:, login_required:)
        {
          order: "following",
          personalized: !login_required,
          login_required:,
          joined_communities:
            communities.map do |community|
              {
                id: community.id,
                name: community.name,
                slug: community.slug,
                path: "/s/#{community.slug}",
              }
            end,
          topics:,
        }
      end
    end
  end
end
