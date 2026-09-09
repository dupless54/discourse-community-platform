# frozen_string_literal: true

module Jobs
  module DiscourseCommunityPlatform
    class EvaluateAutomodPost < ::Jobs::Base
      def execute(args)
        return unless SiteSetting.community_platform_enabled

        post = Post.find_by(id: args[:post_id])
        return if post.blank?

        ::DiscourseCommunityPlatform::Automod::EvaluatePost.call(
          post:,
          trigger: args[:trigger] || "create",
        )
      end
    end
  end
end
