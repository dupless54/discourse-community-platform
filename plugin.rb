# frozen_string_literal: true

# name: discourse-community-platform
# about: Adds Reddit-inspired communities, membership, moderation, ranking, and discovery while preserving Discourse core behavior.
# version: 0.1.0
# authors: dupless54
# url: https://github.com/dupless54/discourse-community-platform
# required_version: 3.5.0

enabled_site_setting :community_platform_enabled
register_asset "stylesheets/community-platform.scss"
register_asset "stylesheets/community-platform-voting.scss"
register_asset "stylesheets/community-platform-home.scss"
register_asset "stylesheets/community-platform-social-discovery.scss"
register_asset "stylesheets/community-platform-automod.scss"
register_asset "stylesheets/community-platform-analytics.scss"

register_homepage(
  "community-home",
  name: "community_platform.homepage.title",
  path: "/home",
  route: "discourse_community_platform/home#index",
  anonymous: true,
  server_side: false,
)

module ::DiscourseCommunityPlatform
  PLUGIN_NAME = "discourse-community-platform"
end

require_relative "lib/discourse_community_platform/engine"
require_relative "lib/discourse_community_platform/community_authorization"

after_initialize do
  Discourse::Application.routes.append do
    mount ::DiscourseCommunityPlatform::Engine, at: "/community-platform"
  end
end

on(:post_created) do |post|
  next unless SiteSetting.community_platform_enabled
  next if post.topic&.category_id.blank?

  Jobs.enqueue(
    Jobs::DiscourseCommunityPlatform::EvaluateAutomodPost,
    post_id: post.id,
    trigger: "create",
  )
end

on(:post_edited) do |post, _, revisor|
  next unless SiteSetting.community_platform_enabled
  next if post.topic&.category_id.blank?
  next unless revisor&.reviewable_content_changed?

  Jobs.enqueue(
    Jobs::DiscourseCommunityPlatform::EvaluateAutomodPost,
    post_id: post.id,
    trigger: "edit",
  )
end
