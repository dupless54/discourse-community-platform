# frozen_string_literal: true

RSpec.describe DiscourseCommunityPlatform::Feeds::TopicPreviews do
  fab!(:user)

  it "returns a bounded plain-text excerpt from a visible first post" do
    topic = Fabricate(:topic, user: user)
    post = Fabricate(:post, topic: topic, user: user, raw: "Hello **community**. " + ("Useful text " * 60))

    preview = described_class.call(topics: [topic], guardian: Guardian.new(user)).fetch(topic.id)

    expect(preview[:excerpt]).to start_with("Hello community. Useful text")
    expect(preview[:excerpt].length).to be <= described_class::EXCERPT_LENGTH + 3
    expect(preview[:excerpt]).not_to include("<", ">", "**")
  end

  it "returns the Discourse topic image when the current Guardian can see its upload" do
    upload =
      Fabricate(
        :upload,
        user_id: user.id,
        original_filename: "community-preview.png",
        extension: "png",
        width: 640,
        height: 360,
      )
    topic = Fabricate(:topic, user: user, image_upload: upload)
    Fabricate(:post, topic: topic, user: user, raw: "Image post")

    preview = described_class.call(topics: [topic], guardian: Guardian.new(user)).fetch(topic.id)

    expect(preview[:image_url]).to eq(topic.image_url(enqueue_if_missing: false))
  end

  it "does not serialize a preview for a hidden first post" do
    topic = Fabricate(:topic, user: user)
    Fabricate(:post, topic: topic, user: user, raw: "Hidden preview", hidden: true)

    preview = described_class.call(topics: [topic], guardian: Guardian.new(user)).fetch(topic.id)

    expect(preview).to eq(excerpt: nil, image_url: nil)
  end
end
