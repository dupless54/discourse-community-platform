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
11. Do not create a competing user-follow graph. When Discourse Follow is installed and enabled, integrate with its `UserFollower` API for followed-user personalization and discovery.
12. Community automation must be scoped through the Community's mapped Discourse Category and must reuse Discourse review/moderation primitives. Do not implement direct destructive moderation when a review-first primitive can satisfy the feature safely.
13. User-configured AutoModerator text matching must remain bounded. Do not introduce arbitrary user regex execution without a dedicated ReDoS/security design.
14. AutoModerator create/edit evaluation must remain asynchronous and idempotent. Serialize per-post work when concurrent jobs could duplicate moderation actions, and retain manager-visible audit evidence for actions taken or already queued.
15. AutoModerator audit history is management data. Preserve rule-name snapshots when rules are later deleted, do not expose the history endpoint to ordinary community members or crawlers, and keep retention bounded rather than allowing unbounded audit-table growth.
16. AutoModerator trigger/target options must come from explicit allowlists. Current post targets are `all_posts`, `topic_starters`, and `replies`; do not add arbitrary executable conditions through user input.
17. AutoModerator actions must remain review-first. Current actions are `queue_for_review` and `flag_only`, both implemented through Discourse `PostActionCreator`; do not silently turn a community rule into delete, ban, silence, or global moderation authority.
18. AutoModerator author/account conditions must remain optional, explicit, and bounded. Current conditions are `max_account_age_days` (1–365) and `max_trust_level` (a current Discourse `TrustLevel.levels` value). Do not extend this surface to email, IP address, device data, sensitive profile fields, or arbitrary executable predicates.
19. Author conditions only narrow phrase-rule eligibility. They must never create an action by themselves, and when multiple author conditions are present all configured conditions must match.
20. Community moderation insights are manager-only aggregate management data. Keep them scoped to plugin-owned bounded audit records and do not serialize post content, post URLs/IDs, usernames, email/IP/device data, or other user-identifying metadata through the aggregate endpoint.
21. Request-time moderation insight queries must remain bounded by community and a short time window over indexed data. If later analytics require broader or expensive scans, move them to scheduled/background cache computation instead of expanding synchronous full-table aggregation.
22. Community activity analytics are manager-only cached aggregates. Rebuild them in scheduled jobs from Discourse topic/post data, never by synchronous request-time full-table scans, and never serialize contributor identities, post IDs/URLs, raw content, email/IP/device data, or other user-identifying metadata.
23. Community activity analytics must remain community/category scoped and cache-cold behavior must fail soft with a bounded warming/empty response rather than performing an emergency synchronous aggregate rebuild.
24. Manager-only JSON surfaces must inherit the shared management-controller hardening and return `X-Robots-Tag: noindex, nofollow` plus `Cache-Control: private, no-store`. Those headers must be applied before authentication so unauthenticated and unauthorized responses are hardened too.
25. Dynamic community and management UI must preserve accessible names, state, and structure. Keep feed loading regions labelled, use live/status semantics for asynchronous state where appropriate, and expose data grids/tables with meaningful row/header roles rather than visual-only layout semantics.
26. Release tags and GitHub prereleases must be created only from an exact candidate revision that has passed Official Discourse Plugin CI and the staging smoke-test checklist. Do not publish an RC merely because a preparation PR is green.
27. During release-candidate stabilization, prefer compatibility, regression, permission, performance, accessibility, and deployment fixes over expanding the product surface. New automation/analytics features wait until the candidate is stable unless they address a release blocker.

## Current phase — First Release Candidate Preparation

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
- Explore excludes joined communities, applies a per-community diversity cap, and keeps every candidate behind Guardian visibility checks.
- Explore community activity signals are computed by a scheduled job and stored in cache; requests never rebuild the aggregate ranking synchronously.
- Cached Explore signals promote recommended public communities and influence topic ordering while preserving the existing Popular candidate fallback.
- Explore people discovery derives candidates from the cached public Popular pool, applies Guardian and current Community visibility checks, and respects Discourse Follow profile/follow opt-out behavior.
- AutoModerator rules are plugin-owned community configuration, not global Discourse moderation configuration.
- AutoModerator rule management is limited to users authorized by `CommunityAuthorization.can_manage?` / `ensure_can_manage!`.
- AutoModerator evaluates only posts whose `topic.category_id` maps to the configured Community.
- AutoModerator phrase matching uses normalized bounded term arrays with `any` and `all` modes; arbitrary user regex is intentionally not supported.
- Rules may target all posts, topic starters only, or replies only.
- Rules may optionally require the author account to be no older than 1–365 days and/or the current author trust level to be at or below an allowed Discourse trust level.
- Author conditions use only `User#created_at` and `User#trust_level`; leaving both unset preserves the original all-author behavior.
- New posts and meaningful `post_edited` content changes enqueue background AutoModerator evaluation jobs.
- Per-post AutoModerator evaluation is serialized with `DistributedMutex` and identical rule/post/content SHA-256 combinations are deduplicated.
- A matching post is sent to the normal Discourse review flow via `PostActionCreator`, `Discourse.system_user`, and the `inappropriate` flag type.
- `queue_for_review` keeps the existing priority review behavior; `flag_only` creates a standard Discourse flag with `queue_for_review: false` and therefore does not force the priority hiding path.
- Manager-only execution history records rule-name snapshots, post references, create/edit triggers, and `queued_for_review` / `flagged_for_review` / `already_queued` outcomes.
- Audit UI returns the latest 50 executions and a daily scheduled job removes records older than 90 days.
- Manager-only moderation insights aggregate the bounded audit table into 7/30-day counts, distinct audited posts, outcome/trigger distributions, and the top five rule-name snapshots without returning raw content or user metadata.
- Manager-only community activity analytics expose only cached 7/30-day counts for new topics, posts, replies, active topics, and unique contributors. A 15-minute scheduled job rebuilds the cache; requests never rebuild it synchronously.
- AutoModerator rules, audit history, moderation insights, and community activity analytics share management response hardening so successful, unauthenticated, and unauthorized JSON responses remain non-indexable and non-cacheable by shared/public caches.
- Dynamic community feed and manager insight surfaces expose explicit accessible region/table/status semantics while retaining keyboard-accessible native controls.
- The current AutoModerator slice does not auto-delete content, ban/silence users, run arbitrary regex, inspect email/IP/device data, or elevate community managers to global staff.
- Release preparation includes a changelog, exact-head CI gates, staging smoke-test checklist, rollback readiness, compatibility notes, and documented known limitations.

Next slices:

1. Finish the release-candidate preparation PR and require exact-head Official Discourse Plugin CI success.
2. Run the staging install/upgrade, permission, AutoModerator, analytics, crawler/cache, responsive, and accessibility checklist on the exact candidate revision.
3. Publish `0.1.0-rc.1` only if staging passes; otherwise fix blockers and repeat the exact-head/staging gates.
4. Resume broader AutoModerator or analytics expansion only after the release candidate is stable.

## SEO contract

- Keep Discourse topic/post SEO and crawler behavior as the base.
- Public community landing pages may become indexable after dedicated server-side/crawler rendering is implemented.
- Private/restricted communities must not expose metadata, counts, titles, or topic content to unauthorized users or crawlers.
- Never make both an alias URL and a Discourse topic URL independently canonical for the same content.
- AutoModerator configuration, execution-history, moderation-insights, and community activity analytics endpoints are authenticated management surfaces and must not become indexable public content.
- Manager-only JSON surfaces must send `X-Robots-Tag: noindex, nofollow` and `Cache-Control: private, no-store` even when authentication or authorization fails.

## Release contract

- `CHANGELOG.md` describes the planned release candidate and must match the code actually tagged.
- `RELEASE_CHECKLIST.md` is a required release gate, not optional documentation.
- Plugin version metadata must be changed intentionally when the exact release revision is known; do not bump it early merely to signal progress.
- A green PR is not equivalent to a tested release. Staging smoke tests must run after the candidate revision is determined and before a prerelease is published.
- Keep a database backup and previous known-good plugin revision available before production rollout.

## Code style

Follow the current official Discourse plugin skeleton and Discourse lint/format rules. Prefer namespaced, Zeitwerk-autoloadable Ruby classes over large `plugin.rb` files.
