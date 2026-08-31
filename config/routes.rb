# frozen_string_literal: true

DiscourseCommunityPlatform::Engine.routes.draw do
  scope "/", defaults: { format: :json } do
    post "communities" => "communities#create"
    get "communities/:slug" => "communities#show"
    patch "communities/:slug" => "communities#update"
    put "communities/:slug" => "communities#update"
    post "communities/:slug/join" => "communities#join"
    delete "communities/:slug/join" => "communities#leave"
  end
end
