# AGENTS.md

## Project goal

Build a Reddit-inspired community layer on top of Discourse without forking or patching Discourse core.

## Non-negotiable architecture rules

1. Discourse remains the source of truth for users, topics, posts, categories, groups, tags, uploads, notifications, search, bookmarks, moderation primitives, and crawler/SEO behavior.
2. A Community is a plugin-owned domain record mapped 1:1 to a real Discourse Category.
3. Authorization must extend or defer to Discourse Guardian/category/group permissions. Never return private or restricted community data merely because a plugin record exists.
4. Do not patch files in Discourse core. Use plugin APIs, Rails engine routes, serializers, services, event hooks, Guardian extensions, and supported frontend APIs.
5. Do not create duplicate indexable topic copies. `/s/:slug` is a community UX route; canonical topic SEO must remain single-source unless a later SEO design explicitly and safely changes it.
6. Public feed/ranking/search endpoints must filter through visibility rules before serialization.
7. Background ranking/recommendation work must use jobs/cache; do not build expensive per-request full-table scoring queries.
8. Community owners and moderators must never receive global Discourse admin/moderator privileges merely to manage a community.
9. Migrations must be additive and reversible where practical. Preserve existing Discourse data.
10. New features require automated tests for permission boundaries and core invariants.
11. Do not create a competing user-follow graph. When Discourse Follow is installed and enabled, integrate with its `UserFollower` API for followed-user personalization.

## Current phase — Feeds & Discovery

Implemented foundations:

- Community creation links a real Category plus member/moderator Groups.
- Join/leave membership uses the mapped Discourse Group.
- Owner/community-moderator management remains community-scoped.
- Rules and appearance metadata are available on the Community layer.
- `/s/:slug` is a responsive community UX route while topic canonicals remain Discourse `/t/...` URLs.
- Voting/ranking persists plugin scores without replacing Discourse likes/posts.
- Popular uses a cached public candidate pool and Guardian filtering.
- Home blends joined communities, followed users through Discourse Follow, and public fallback topics.
- Following contains only joined-community and followed-user content and returns no personalized data to guests.
- Shared Home/Following/Explore/Popular navigation uses Discourse UI-kit route primitives.
- Explore prioritizes active public topics from communities the signed-in user has not joined and applies a per-community diversity cap.

Next slices:

1. Improve Explore signals through cached/background recommendation inputs rather than expensive request-time scans.
2. Add profile/social discovery surfaces by extending Discourse and Discourse Follow rather than duplicating their models.
3. Add AutoModerator rules and community-scoped automation.
4. Add community analytics/moderation insights.
5. Perform responsive, accessibility, SEO/crawler, and release hardening.

## SEO contract

- Keep Discourse topic/post SEO and crawler behavior as the base.
- Public community landing pages may become indexable after dedicated server-side/crawler rendering is implemented.
- Private/restricted communities must not expose metadata, counts, titles, or topic content to unauthorized users or crawlers.
- Never make both an alias URL and a Discourse topic URL independently canonical for the same content.

## Code style

Follow the current official Discourse plugin skeleton and Discourse lint/format rules. Prefer namespaced, Zeitwerk-autoloadable Ruby classes over large `plugin.rb` files.
