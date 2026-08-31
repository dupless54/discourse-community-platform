# frozen_string_literal: true

DiscourseCommunityPlatform::Engine.routes.draw do
  scope "/", defaults: { format: :json } do
    post "communities" => "communities#create"
    get "communities/:slug" => "communities#show"
    get "communities/:slug/topics" => "communities#topics"
    patch "communities/:slug" => "communities#update"
    put "communities/:slug" => "communities#update"
    post "communities/:slug/join" => "communities#join"
    delete "communities/:slug/join" => "communities#leave"
    get "feeds/home" => "feeds#home"
    get "feeds/popular" => "feeds#popular"
    put "topics/:topic_id/vote" => "votes#update"
  end
end
