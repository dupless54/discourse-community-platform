# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class ManagementController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in
    before_action :set_management_response_headers

    private

    def set_management_response_headers
      response.headers["X-Robots-Tag"] = "noindex, nofollow"
      response.headers["Cache-Control"] = "private, no-store"
    end
  end
end
