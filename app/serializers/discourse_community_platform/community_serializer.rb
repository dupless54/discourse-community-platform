# frozen_string_literal: true

module ::DiscourseCommunityPlatform
  class CommunitySerializer < ::ApplicationSerializer
    attributes :id,
               :name,
               :slug,
               :description,
               :visibility,
               :members_count,
               :category_id,
               :owner_id,
               :member_group_id,
               :moderator_group_id,
               :created_at

    attribute :path

    def path
      "/s/#{object.slug}"
    end
  end
end
