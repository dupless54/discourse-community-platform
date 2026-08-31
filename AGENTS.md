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

## Phase 1 — Community Core

Current scope:

- plugin skeleton and isolated engine
- Community model/table
- Category/User/Group references
- public/restricted/private visibility field
- read-only community API
- `/s/:slug` path contract for future frontend routing
- model/request tests
- official Discourse plugin CI

Next slices:

1. Community creation service that creates/links Category + member/moderator Groups atomically.
2. Join/leave membership service.
3. Community owner/moderator authorization policies.
4. Community rules and appearance metadata.
5. Frontend `/s/:slug` page.
6. Voting and ranking engine.

## SEO contract

- Keep Discourse topic/post SEO and crawler behavior as the base.
- Public community landing pages may become indexable after dedicated server-side/crawler rendering is implemented.
- Private/restricted communities must not expose metadata, counts, titles, or topic content to unauthorized users or crawlers.
- Never make both an alias URL and a Discourse topic URL independently canonical for the same content.

## Code style

Follow the current official Discourse plugin skeleton and Discourse lint/format rules. Prefer namespaced, Zeitwerk-autoloadable Ruby classes over large `plugin.rb` files.
