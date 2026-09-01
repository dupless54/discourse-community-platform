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
- bounded AutoModerator targets for all posts, topic starters only, or replies only
- optional bounded author conditions for account age (1–365 days) and maximum Discourse trust level
- review-first AutoModerator actions for priority review queue or a standard Discourse flag
- manager-only AutoModerator CRUD UI and API
- matching new and meaningfully edited community posts are evaluated in background jobs through Discourse `PostActionCreator` review primitives instead of being automatically deleted
- manager-only AutoModerator audit history with rule snapshots, post references, create/edit triggers, review outcomes, SHA-256 content deduplication, and 90-day retention
- manager-only moderation insights derived from bounded 7/30-day AutoModerator audit aggregates without returning post content or user metadata
- manager-only 7/30-day community activity analytics for new topics, posts, replies, active topics, and unique contributors, rebuilt in background cache jobs rather than request-time aggregate scans

### Feed backend contracts

```text
GET /community-platform/feeds/home.json
GET /community-platform/feeds/following.json
GET /community-platform/feeds/explore.json
GET /community-platform/feeds/popular.json
```

All plugin feeds continue to filter candidate content through Discourse visibility/Guardian rules before serialization. Explore recommendation signals are calculated asynchronously; when that cache is cold, topic discovery safely falls back to the existing cached Popular candidate order instead of running an aggregate recommendation query during the request.

### Manager analytics contracts

```text
GET /community-platform/communities/:slug/activity-analytics.json
```

Community activity analytics are available only to users who can manage the Community and can see its mapped Discourse Category. The response contains only cached numerical aggregates for 7- and 30-day windows: new topics, posts, replies, active topics, and unique contributors. It never serializes contributor IDs/usernames, post IDs/URLs, raw content, email/IP/device data, or other user-identifying metadata. The underlying aggregate scan runs every 15 minutes in a scheduled job and the cache expires after 30 minutes. A cold cache returns a zeroed `warming` snapshot instead of rebuilding synchronously in the request.

### AutoModerator contracts

```text
GET    /community-platform/communities/:slug/automod-rules.json
POST   /community-platform/communities/:slug/automod-rules.json
PATCH  /community-platform/communities/:slug/automod-rules/:id.json
DELETE /community-platform/communities/:slug/automod-rules/:id.json
GET    /community-platform/communities/:slug/automod-executions.json
GET    /community-platform/communities/:slug/moderation-insights.json
```

AutoModerator rule, execution-history, and moderation-insight management surfaces are limited to users who can manage that Community. Rules are evaluated only for posts inside the Community's mapped Discourse Category. A rule can target all posts, topic starters only, or replies only. It can also optionally narrow evaluation to authors whose account is no older than 1–365 days and/or whose current trust level is at or below a selected Discourse trust level. With both author conditions configured, both must match. Leaving both unset preserves the original all-author behavior.

Author conditions are deliberately small, explicit allowlisted signals. They use only the Discourse user's `created_at` and current `trust_level`; they do not inspect email addresses, IP addresses, devices, profile fields, or other sensitive/account-identifying metadata. They only decide whether the existing phrase rule is eligible to match and never create a moderation action on their own.

New posts and meaningful content edits are processed asynchronously; per-post evaluation is serialized with Discourse `DistributedMutex`, and repeated evaluation of the same rule/post/content SHA-256 is deduplicated.

A successful match always stays inside Discourse's normal review system. `queue_for_review` creates the existing priority review behavior, while `flag_only` creates a standard `inappropriate` flag without forcing the priority-queue hiding path. Existing system flags are not duplicated. The manager UI exposes the latest 50 audit entries, while a daily cleanup removes entries older than 90 days. The automation remains review-first: it does not directly delete posts, ban/silence users, execute arbitrary user regex, or grant global moderation privileges.

Moderation insights query only the plugin-owned audit table, which is already bounded by 90-day retention and indexed by community/time. The manager-only response summarizes 7- and 30-day execution counts, distinct audited posts, outcome/trigger distributions, and the five most-triggered rule-name snapshots. It does not serialize post IDs, post URLs, usernames, raw post content, email/IP/device data, or private community content.

## Roadmap

1. Expand AutoModerator only through additional explicit, bounded, review-first conditions/actions with dedicated tests and security review.
2. Finish responsive polish, accessibility, SEO/crawler validation, and release hardening.
3. Prepare a first release candidate after the remaining hardening gates are green.

## License

MIT
