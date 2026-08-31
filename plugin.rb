# frozen_string_literal: true

# name: discourse-community-platform
# about: Adds Reddit-inspired communities, membership, moderation, ranking, and discovery while preserving Discourse core behavior.
# version: 0.1.0
# authors: dupless54
# url: https://github.com/dupless54/discourse-community-platform
# required_version: 3.5.0

enabled_site_setting :community_platform_enabled

module ::DiscourseCommunityPlatform
  PLUGIN_NAME = "discourse-community-platform"
end

require_relative "lib/discourse_community_platform/engine"
