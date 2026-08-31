# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseCommunityPlatform
  end
end

DiscourseCommunityPlatform::Engine.routes.draw do
  get "/communities/:slug" => "communities#show", defaults: { format: :json }
end

Discourse::Application.routes.append do
  mount ::DiscourseCommunityPlatform::Engine, at: "/community-platform"
end
