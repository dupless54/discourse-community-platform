# frozen_string_literal: true

describe "Native Community Topic keyboard and composer behavior" do
  fab!(:owner, :user)
  fab!(:viewer, :user)
  fab!(:category, :category_with_definition) do
    category = Fabricate(:category_with_definition, name: "Keyboard Community")
    category.set_permissions(everyone: :full)
    category.save!
    category
  end
  fab!(:community) do
    DiscourseCommunityPlatform::Community.create!(
      name: "Keyboard Community",
      slug: "keyboard-community",
      description: "Community context should not interfere with native Topic interactions.",
      category:,
      owner:,
      visibility: "public",
      rules: ["Keep native Topic behavior intact"],
    )
  end
  fab!(:topic) { Fabricate(:topic, category:, user: owner) }
  fab!(:post) { Fabricate(:post, topic:, user: owner, raw: "Native Topic reply target") }

  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:composer) { PageObjects::Components::Composer.new }

  def active_element_matches?(selector)
    page.evaluate_script(<<~JS)
      (() => {
        const active = document.activeElement;
        return !!active && active.matches(#{selector.to_json});
      })()
    JS
  end

  it "keeps Community links keyboard reachable while preserving the native reply composer" do
    sign_in(viewer)
    visit(topic.url)

    expect(page).to have_css("[data-test-topic-community-context]")
    expect(page).to have_css("#topic .cooked", text: post.raw)
    expect(page).to have_css(
      ".dcp-topic-community-context__name[href='#{category.url}']",
      text: community.name,
    )
    expect(page).to have_css(
      ".dcp-topic-community-context__open[href='#{category.url}']",
    )

    page.execute_script(
      'document.querySelector(".dcp-topic-community-context__name").focus()',
    )
    expect(active_element_matches?(".dcp-topic-community-context__name")).to eq(true)

    page.send_keys(:tab)
    expect(active_element_matches?(".dcp-topic-community-context__open")).to eq(true)

    topic_page.click_post_action_button(post, :reply)

    expect(composer).to be_opened
    expect(page).to have_css("#reply-control")
    expect(page).to have_css("[data-test-topic-community-context]")
    expect(page).to have_css("#topic .cooked", text: post.raw)
  end
end
