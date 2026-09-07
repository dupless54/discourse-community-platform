# frozen_string_literal: true

describe "Responsive Home rich topic previews" do
  fab!(:owner, :admin)
  fab!(:viewer, :user)
  fab!(:community) do
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "Photography",
        slug: "photography",
        description: "Share photos and camera techniques",
        visibility: "public",
      },
    )
  end
  fab!(:upload) do
    Fabricate(
      :upload,
      user_id: owner.id,
      original_filename: "mobile-rich-preview.png",
      extension: "png",
      width: 1200,
      height: 800,
    )
  end
  fab!(:topic) do
    Fabricate(:topic, category: community.category, user: owner, image_upload: upload)
  end
  fab!(:post) do
    Fabricate(
      :post,
      topic:,
      user: owner,
      raw: "A mobile rich preview should keep this useful first-post summary visible. " +
        ("Detailed camera notes remain bounded. " * 20),
    )
  end

  before do
    community.update!(rules: ["Be constructive"])
    DiscourseCommunityPlatform::Memberships::Join.call(user: viewer, community:)
  end

  def element_metrics(selector)
    page.evaluate_script(<<~JS)
      (() => {
        const element = document.querySelector(#{selector.to_json});
        const rect = element.getBoundingClientRect();

        return {
          left: rect.left,
          right: rect.right,
          width: rect.width,
          scrollWidth: element.scrollWidth,
          clientWidth: element.clientWidth,
        };
      })()
    JS
  end

  it "keeps image, excerpt, and vote controls separated without horizontal overflow on mobile" do
    sign_in(viewer)

    resize_window(width: 500, height: 900) do
      visit("/home")

      expect(page).to have_css('.dcp-platform-shell[data-platform-section="home"]')
      expect(page).to have_css(".dcp-home-card", count: 1)
      expect(page).to have_css(".dcp-home-card__vote")
      expect(page).to have_css(".dcp-vote-button", count: 2)
      expect(page).to have_css(".dcp-topic-preview--rich")
      expect(page).to have_css(".dcp-topic-preview__media img")
      expect(page).to have_css(
        ".dcp-topic-preview__excerpt",
        text: "A mobile rich preview should keep this useful first-post summary visible.",
      )

      viewport_width = page.evaluate_script("window.innerWidth")
      card = element_metrics(".dcp-home-card")
      vote = element_metrics(".dcp-home-card__vote")
      content = element_metrics(".dcp-home-card__content")
      preview = element_metrics(".dcp-topic-preview--rich")

      expect(card["left"]).to be >= 0
      expect(card["right"]).to be <= viewport_width + 1
      expect(preview["left"]).to be >= 0
      expect(preview["right"]).to be <= viewport_width + 1
      expect(preview["scrollWidth"]).to be <= preview["clientWidth"] + 1
      expect(content["scrollWidth"]).to be <= content["clientWidth"] + 1
      expect(vote["right"]).to be <= content["left"]
    end
  end
end
