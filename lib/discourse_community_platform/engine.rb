# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseCommunityPlatform
  end
end
