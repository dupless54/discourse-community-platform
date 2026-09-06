# frozen_string_literal: true

describe "Native Community responsive surfaces" do
  fab!(:owner, :user)
  fab!(:category, :category_with_definition) do
    category = Fabricate(:category_with_definition, name: "Responsive Technology")
    category.set_permissions(everyone: :full)
    category.save!
    category
  end
  fab!(:community) do
    DiscourseCommunityPlatform::Community.create!(
      name: "Long Technology Community Name That Must Stay Inside Narrow Native Layouts",
      slug: "responsive-technology",
      description:
        "A deliberately long Community description used to exercise the native Category and Topic responsive layout without replacing Discourse rendering.",
      category:,
      owner:,
      visibility: "public",
      rules: ["Keep discussions useful and respectful"],
    )
  end
  fab!(:topic) { Fabricate(:topic, category:) }
  fab!(:post) { Fabricate(:post, topic:, raw: "Responsive native Community topic") }

  let(:topic_list) { PageObjects::Components::TopicList.new }

  def expect_surface_within_viewport(selector)
    expect(
      page.evaluate_script(<<~JS),
        (() => {
          const element = document.querySelector(#{selector.to_json});
          if (!element) {
            return false;
          }

          const rect = element.getBoundingClientRect();
          return (
            rect.left >= -1 &&
            rect.right <= window.innerWidth + 1 &&
            element.scrollWidth <= element.clientWidth + 1
          );
        })()
      JS
    ).to eq(true)
  end

  it "keeps native Category and Topic Community context inside tablet and mobile viewports" do
    [900, 500].each do |width|
      resize_window(width:, height: 900) do
        visit(category.url)

        expect(page).to have_css(".dcp-native-community")
        expect(page).to have_css(".dcp-community-hero")
        expect(page).to have_css(".dcp-native-community__details")
        expect(topic_list).to have_topic(topic)
        expect_surface_within_viewport(".dcp-native-community")
        expect_surface_within_viewport(".dcp-community-hero")

        topic_list.visit_topic(topic)

        expect(page).to have_css("[data-test-topic-community-context]")
        expect(page).to have_css("#topic .cooked", text: post.raw)
        expect_surface_within_viewport(".dcp-topic-community-context")
      end
    end
  end
end
