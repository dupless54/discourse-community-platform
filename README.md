# Discourse Community Platform

A first-class community experience for Discourse. The plugin adds community membership, voting/ranking, discovery, personalized feeds, rich social topic cards, branding, analytics, and community-scoped safety automation while keeping native Discourse categories, topics, posts, permissions, search, review, and SEO as the source of truth.

> Status: `v0.1.0-rc.1` is the currently published prerelease. RC2 was validated internally but was not published; development has moved to the approved RC3 native-Community architecture. Deploy an exact tested tag/commit rather than the moving `main` branch.

## Product direction

This project is not a Reddit clone and does not maintain a second forum model.

- `/` is the Community product homepage through Discourse's supported registered-homepage mechanism.
- Communities are real Discourse Categories and user-facing Community links use `Category#url` (`/c/...`).
- Discussions are real Discourse Topics and keep their normal `/t/...` URLs.
- Replies remain real Discourse Posts rendered through the normal Post Stream/composer.
- Membership is backed by real Discourse Groups.
- Visibility and authorization remain controlled by Guardian/category/group permissions.
- Search, notifications, bookmarks, moderation/review, crawler behavior, and topic SEO remain native Discourse behavior.
- No second public `/s/...` Community tree or alternate topic URL is required for the RC3 product direction.

The frontend can therefore look and behave like the approved **Senin Community** product while the underlying forum remains Discourse.

## Compatibility

- Plugin metadata currently requires Discourse `3.5.0` or newer.
- The plugin is checked against current Discourse core through Official Discourse Plugin CI before merge/release decisions.
- Intended for self-hosted Discourse installations where third-party plugins can be installed.
- No Discourse core patches are required.

Because the project is pre-stable, test upgrades on staging before production deployment.

## Installation

Back up the Discourse database, then add the repository to the normal plugin section of `/var/discourse/containers/app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/dupless54/discourse-community-platform.git
```

Rebuild Discourse:

```bash
cd /var/discourse
./launcher rebuild app
```

After the rebuild, enable **Community Platform** in site settings. To make the Community feed the real site homepage, select the registered **Community Home** option as Discourse's `default_homepage`; Discourse then exposes that registered homepage at `/` while keeping its implementation route internal/compatible.

For a release candidate, deploy the exact tested tag or commit.

## Architecture principles

- Discourse is the source of truth for users, topics, posts, categories, groups, tags, uploads, notifications, search, bookmarks, moderation, and review.
- A Community is plugin-owned metadata mapped 1:1 to a real Discourse Category.
- Community navigation uses the native Category URL; topic navigation uses the native Topic URL.
- Community permissions extend/defer to Guardian and Discourse category/group permissions.
- Public feeds filter visibility before serialization.
- Heavy ranking/recommendation/analytics work is background cached rather than rebuilt per request.
- Community managers never gain global staff privileges merely by managing a Community.
- User-follow personalization integrates with Discourse Follow when available rather than creating a parallel follow graph.
- Feed previews summarize already-visible topics and never create a second content store.
- Community logo/cover branding reuses Discourse Upload records and supported uploader UI.
- Community automation remains category scoped and reuses Discourse review/moderation primitives.

## Implemented foundations

- atomic Community + Category + member/moderator Group creation
- join/leave membership and community-scoped owner/moderator management
- rules and appearance metadata
- Community logo and cover-image branding through Discourse uploads, with emoji/banner-color fallbacks
- hot/new/top/rising topic ordering
- upvote/downvote persistence and ranking scores without replacing Discourse likes/posts
- bounded rich topic cards with Guardian-visible topic images and bounded plain-text first-post excerpts
- image and excerpt can be rendered together; cards link to the real `/t/...` topic
- cached public `/popular` feed
- personalized Community Home feed
- focused `/following` feed using joined communities and Discourse Follow
- diversified `/explore` feed excluding joined communities and capping per-community dominance
- scheduled Explore community activity scoring stored in cache
- recommended Community cards and Explore quick join
- people discovery sourced from visible cached public activity while respecting Discourse Follow opt-out behavior
- Community-scoped AutoModerator phrase rules with bounded `any` / `all` matching
- AutoModerator targets for all posts, topic starters, or replies
- optional bounded author conditions for account age and trust level
- review-first actions for priority review queue or standard Discourse flag
- manager-only AutoModerator CRUD, audit history, moderation insights, and activity analytics
- async/idempotent post-create/edit evaluation using Discourse `DistributedMutex` and `PostActionCreator`
- 90-day bounded audit retention
- cached 7/30-day Community activity analytics without user-identifying/raw-content payloads
- management JSON hardening with `X-Robots-Tag: noindex, nofollow` and `Cache-Control: private, no-store`

## RC3 native-route migration

The RC3 migration intentionally separates product presentation from content ownership:

```text
/                     -> Senin Community home feed
/popular              -> popular Community feed
/explore              -> discovery
/following            -> joined/followed personal feed
/c/<category>/...     -> Community page (native Discourse Category)
/t/<topic>/<id>       -> discussion page (native Discourse Topic)
```

`/home` may remain temporarily as the registered homepage implementation/compatibility path, but primary navigation points to `/`. Legacy `/s/:slug` UI code is transitional only while Category-page management features are ported; new product work must not depend on it.

The next native-UI slices will enrich Category pages with Community hero/membership/rules/branding/manager tools and enrich Topic pages with Community context while retaining the native Discourse Post Stream and composer.

## Feed backend contracts

```text
GET /community-platform/feeds/home.json
GET /community-platform/feeds/following.json
GET /community-platform/feeds/explore.json
GET /community-platform/feeds/popular.json
GET /community-platform/communities/:slug/topics.json
```

These are JSON service endpoints, not alternate public content documents. Feed items use native Topic URLs and Community identities use native Category URLs.

All feeds filter through current Guardian visibility before serialization. After a Topic passes that boundary, a feed may include a bounded plain-text excerpt from its visible first regular post and a Guardian-visible Discourse topic image. Raw post content and cooked HTML are not part of the feed contract.

Explore recommendation signals are calculated asynchronously. A cold recommendation cache fails soft instead of running an expensive aggregate rebuild inside the request.

## Community branding contract

Community records own optional `icon_upload_id` and `banner_upload_id` references. Managers edit these through Discourse's image uploader UI. Branding assignment is image-only and validates that the manager owns the upload or that it is already attached to the Community; staff retain normal administrative authority.

Attached branding uploads are retained with explicit `UploadReference` rows. Internal upload IDs are serialized only to authorized Community managers. Emoji and banner color remain fallbacks.

## Manager analytics contract

```text
GET /community-platform/communities/:slug/activity-analytics.json
```

Only authorized Community managers can read the activity endpoint. It contains cached numerical 7/30-day aggregates for new topics, posts, replies, active topics, and unique contributors. It does not expose contributor identities, topic/post URLs or IDs, raw content, email, IP, or device data. A cold cache returns a bounded `warming` response instead of performing an emergency synchronous aggregate scan.

## AutoModerator contracts

```text
GET    /community-platform/communities/:slug/automod-rules.json
POST   /community-platform/communities/:slug/automod-rules.json
PATCH  /community-platform/communities/:slug/automod-rules/:id.json
DELETE /community-platform/communities/:slug/automod-rules/:id.json
GET    /community-platform/communities/:slug/automod-executions.json
GET    /community-platform/communities/:slug/moderation-insights.json
```

These management endpoints may continue using the plugin Community slug as an API identifier; this does not create a second public Community document URL.

Rules are evaluated only for posts in the Community's mapped Category. New posts and meaningful edits are processed asynchronously. Identical rule/post/content SHA-256 combinations are deduplicated. Matches reuse the normal Discourse review system through `PostActionCreator`; the plugin does not directly delete content, ban/silence users, execute arbitrary user regex, or grant global moderation privileges.

Management-only AutoModerator and analytics endpoints are marked `noindex, nofollow` and `private, no-store` in addition to normal authorization.

## SEO contract

- Native Discourse Topic URLs are the only public Topic documents.
- Native Discourse Category URLs are the Community landing URLs.
- Feed cards are summaries/navigation, not alternate documents.
- Do not create independently indexable aliases for the same Topic or Community.
- Guardian/category visibility remains authoritative for private/restricted content, previews, branding, and metadata.
- Management APIs are non-indexable/private.

## Known limitations during RC3 migration

- The product is pre-stable and the native Category/Topic visual integration is still being migrated.
- `/home` remains a temporary registered-homepage implementation/compatibility route; real Home navigation targets `/`.
- Legacy `/s/:slug` frontend code is temporary until native Category-page Community management reaches feature parity.
- Feed topic images depend on Discourse's topic image/thumbnail pipeline and may briefly fall back to text before metadata is populated.
- Activity/recommendation caches can briefly report a cold/warming state after restart until their scheduled jobs run.
- The current Official Discourse Plugin CI has no applicable plugin system-test suite; release confidence also requires the staging checks in [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).

## Release process

1. Complete the code/release-prep PR and record its exact head SHA.
2. Require Official Discourse Plugin CI for that exact SHA to succeed.
3. Merge only when the branch is not behind `main` and required gates are green.
4. Deploy that exact candidate revision to staging.
5. Complete every applicable item in [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).
6. Only then select the release version/tag and publish a GitHub prerelease using [`CHANGELOG.md`](CHANGELOG.md).

## RC3 roadmap

1. Complete native Category URL conversion and regression coverage.
2. Validate the Community registered homepage at real `/`.
3. Port Community hero, membership, rules, branding, AutoModerator, and analytics UI into supported native Category-page integration points.
4. Integrate Community context into native `/t/...` Topic pages without replacing Post Stream/composer.
5. Rework Home toward the approved Senin Community design: left navigation/Community list, center social topic cards/order controls, right trends/recommendations/about rail.
6. Run install/upgrade, permission, performance, accessibility, desktop/tablet/mobile, and staging release gates before choosing an RC3 candidate.

## License

MIT
