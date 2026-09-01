# frozen_string_literal: true

module DiscourseCommunityPlatform
  class HomeController < ApplicationController
    requires_plugin PLUGIN_NAME
    skip_before_action :check_xhr

    def index
      render "default/empty"
    end
  end
end
