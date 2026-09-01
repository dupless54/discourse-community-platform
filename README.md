# Discourse Community Platform

A community-platform plugin for Discourse that adds Reddit-inspired communities, membership, moderation, voting, ranking, discovery, personalized feeds, and community-scoped safety automation while preserving Discourse core models, permissions, search, review, and SEO behavior.

> Status: active development / Phase 4 — Community Moderation Automation

## Architecture principles

- Discourse remains the source of truth for users, topics, posts, categories, groups, tags, uploads, notifications, search, bookmarks, and moderation/review primitives.
- Communities are a plugin-owned layer mapped to real Discourse categories.
- Community permissions extend Discourse Guardian/group/category permissions instead of bypassing them.
- Public content remains compatible with Discourse SEO/crawler behavior; private or restricted content must never leak through plugin endpoints.
- Do not patch Discourse core files.
- New public aliases such as `/s/:slug` must not create duplicate indexable copies of the same topic content.
- User-follow personalization integrates with Discourse Follow when its `UserFollower` API is available instead of creating a competing follow graph.
- Community automation must remain scoped to the mapped Category and reuse Discourse moderation primitives rather than granting community managers global moderator powers.

## Implemented foundations

- atomic Community + Category + member/moderator Group creation
- join/leave membership and community-scoped owner/moderator management
- rules and appearance metadata
- responsive `/s/:slug` community experience
- community topic ordering for hot/new/top/rising
- upvote/downvote persistence and ranking scores
- cached public `/popular` feed
- personalized `/home` feed
- focused `/following` feed using joined communities and Discourse Follow
- shared responsive feed navigation
- diversified `/explore` discovery feed that prioritizes communities the signed-in user has not joined
- scheduled Explore community activity scoring stored in cache instead of recalculated during requests
- recommended community cards and cached community-signal promotion inside `/explore`
- people discovery sourced from visible cached public activity while preserving Discourse Follow opt-out rules
- community-scoped AutoModerator phrase rules with `any` / `all` matching
- manager-only AutoModerator CRUD UI and API
- matching new and meaningfully edited community posts are evaluated in background jobs and queued through Discourse `PostActionCreator` review primitives instead of being automatically deleted
- manager-only AutoModerator audit history with rule snapshots, post references, create/edit triggers, outcomes, SHA-256 content deduplication, and 90-day retention

### Feed backend contracts

```text
GET /community-platform/feeds/home.json
GET /community-platform/feeds/following.json
GET /community-platform/feeds/explore.json
GET /community-platform/feeds/popular.json
```

All plugin feeds continue to filter candidate content through Discourse visibility/Guardian rules before serialization. Explore recommendation signals are calculated asynchronously; when that cache is cold, topic discovery safely falls back to the existing cached Popular candidate order instead of running an aggregate recommendation query during the request.

### AutoModerator contracts

```text
GET    /community-platform/communities/:slug/automod-rules.json
POST   /community-platform/communities/:slug/automod-rules.json
PATCH  /community-platform/communities/:slug/automod-rules/:id.json
DELETE /community-platform/communities/:slug/automod-rules/:id.json
GET    /community-platform/communities/:slug/automod-executions.json
```

AutoModerator rule and execution-history management surfaces are limited to users who can manage that Community. Rules are evaluated only for posts inside the Community's mapped Discourse Category. New posts and meaningful content edits are processed asynchronously; per-post evaluation is serialized with Discourse `DistributedMutex`, and repeated evaluation of the same rule/post/content SHA-256 is deduplicated. A successful match creates an `inappropriate` flag through the Discourse system user with `queue_for_review: true`; existing system flags are not duplicated. The manager UI exposes the latest 50 audit entries, while a daily cleanup removes entries older than 90 days. The automation remains review-first: it does not directly delete posts, ban users, or grant global moderation privileges.

## Roadmap

1. Add carefully bounded AutoModerator triggers/actions without arbitrary regex or destructive bypasses.
2. Add community analytics and moderation insights.
3. Finish responsive polish, accessibility, SEO/crawler validation, and release hardening.

## License

MIT
