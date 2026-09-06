# frozen_string_literal: true

describe "Native Community browser history" do
  fab!(:owner, :user)
  fab!(:category, :category_with_definition) do
    category = Fabricate(:category_with_definition, name: "Technology")
    category.set_permissions(everyone: :full)
    category.save!
    category
  end
  fab!(:community) do
    DiscourseCommunityPlatform::Community.create!(
      name: "Technology",
      slug: "technology",
      description: "Technology discussions",
      category:,
      owner:,
      visibility: "public",
      rules: ["Be respectful"],
    )
  end
  fab!(:topic) { Fabricate(:topic, category:) }
  fab!(:post) { Fabricate(:post, topic:, raw: "Native Community history topic") }

  it "restores native Topic and Category Community surfaces across back and forward" do
    visit(topic.url)

    expect(page).to have_css("[data-test-topic-community-context]")
    expect(page).to have_css("#topic .cooked", text: post.raw)
    expect(page).to have_no_css(".dcp-native-community")

    find(".dcp-topic-community-context__name").click

    expect(page).to have_current_path(category.url, ignore_query: true)
    expect(page).to have_css(".dcp-native-community")
    expect(page).to have_no_css("[data-test-topic-community-context]")

    page.go_back

    expect(page).to have_current_path(topic.url, ignore_query: true)
    expect(page).to have_css("[data-test-topic-community-context]")
    expect(page).to have_css("#topic .cooked", text: post.raw)
    expect(page).to have_no_css(".dcp-native-community")

    page.go_forward

    expect(page).to have_current_path(category.url, ignore_query: true)
    expect(page).to have_css(".dcp-native-community")
    expect(page).to have_no_css("[data-test-topic-community-context]")
  end
end
