# frozen_string_literal: true

describe "Community Home voting" do
  fab!(:owner, :admin)
  fab!(:viewer, :user)
  fab!(:community) do
    DiscourseCommunityPlatform::Communities::Create.call(
      user: owner,
      params: {
        name: "Voting Community",
        slug: "voting-community",
        description: "A public Community used to verify Home voting end to end",
        visibility: "public",
      },
    )
  end
  fab!(:topic) { Fabricate(:topic, category: community.category, user: owner) }
  fab!(:post) do
    Fabricate(
      :post,
      topic:,
      user: owner,
      raw: "Voting must not replace Discourse posts or likes.",
    )
  end

  before { DiscourseCommunityPlatform::Memberships::Join.call(user: viewer, community:) }

  it "persists upvote, downvote, and clear-vote state without changing native Topic activity" do
    sign_in(viewer)

    native_posts_count = topic.reload.posts_count
    native_like_count = topic.like_count

    visit("/home")

    expect(page).to have_css('.dcp-platform-shell[data-platform-section="home"]')
    expect(page).to have_css(".dcp-home-card", count: 1)
    expect(page).to have_css(".dcp-home-card__title", text: topic.title)
    expect(page).to have_css(".dcp-home-card__score", text: "0")
    expect(page).to have_css('.dcp-vote-button--up[aria-pressed="false"]')
    expect(page).to have_css('.dcp-vote-button--down[aria-pressed="false"]')

    find(".dcp-vote-button--up").click

    expect(page).to have_css(".dcp-home-card__score", text: "1")
    expect(page).to have_css('.dcp-vote-button--up[aria-pressed="true"]')
    expect(page).to have_css('.dcp-vote-button--down[aria-pressed="false"]')
    expect(
      DiscourseCommunityPlatform::Vote.find_by(user: viewer, topic:)&.value,
    ).to eq(1)
    expect(DiscourseCommunityPlatform::TopicScore.find_by(topic:)&.score).to eq(1)
    expect(topic.reload.posts_count).to eq(native_posts_count)
    expect(topic.like_count).to eq(native_like_count)

    find(".dcp-vote-button--down").click

    expect(page).to have_css(".dcp-home-card__score", text: "-1")
    expect(page).to have_css('.dcp-vote-button--up[aria-pressed="false"]')
    expect(page).to have_css('.dcp-vote-button--down[aria-pressed="true"]')
    expect(
      DiscourseCommunityPlatform::Vote.find_by(user: viewer, topic:)&.value,
    ).to eq(-1)
    expect(DiscourseCommunityPlatform::TopicScore.find_by(topic:)&.score).to eq(-1)
    expect(topic.reload.posts_count).to eq(native_posts_count)
    expect(topic.like_count).to eq(native_like_count)

    find(".dcp-vote-button--down").click

    expect(page).to have_css(".dcp-home-card__score", text: "0")
    expect(page).to have_css('.dcp-vote-button--up[aria-pressed="false"]')
    expect(page).to have_css('.dcp-vote-button--down[aria-pressed="false"]')
    expect(DiscourseCommunityPlatform::Vote.find_by(user: viewer, topic:)).to be_nil
    expect(DiscourseCommunityPlatform::TopicScore.find_by(topic:)&.score).to eq(0)
    expect(topic.reload.posts_count).to eq(native_posts_count)
    expect(topic.like_count).to eq(native_like_count)
  end
end
