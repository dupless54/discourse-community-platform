# frozen_string_literal: true

DiscourseCommunityPlatform::Engine.routes.draw do
  scope "/", defaults: { format: :json } do
    get "communities/:slug" => "communities#show"
  end
end
