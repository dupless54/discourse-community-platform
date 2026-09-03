# AGENTS.md

## Project goal

Build a first-class Community product experience on top of native Discourse without forking or patching Discourse core. The product may borrow useful community concepts from social platforms, but it must not become a Reddit clone or introduce a parallel forum model.

## Non-negotiable architecture rules

1. Discourse remains the source of truth for users, topics, posts, categories, groups, tags, uploads, notifications, search, bookmarks, moderation primitives, and crawler/SEO behavior.
2. A Community is a plugin-owned domain record mapped 1:1 to a real Discourse Category.
3. Authorization must extend or defer to Discourse Guardian/category/group permissions. Never return private or restricted community data merely because a plugin record exists.
4. Do not patch files in Discourse core. Use plugin APIs, Rails engine routes, serializers, services, event hooks, Guardian extensions, and supported frontend APIs.
5. Native Discourse routes are the public content routes. Community navigation must use the mapped Category URL (`Category#url`), topics must use their normal `/t/...` URL, and the Community homepage must use Discourse's real `/` homepage mechanism. Do not create a second public Community or topic URL tree such as `/s/:slug` for new UX.
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
27. During release-candidate stabilization, prefer compatibility, regression, permission, performance, accessibility, and deployment fixes over expanding the product surface. Architecture work explicitly approved for RC3 may proceed before a new release candidate is selected.
28. Rich feed previews must be derived only after the topic has passed the current Guardian visibility check. Preview extraction is bounded to the visible first regular post and may serialize only a short plain-text excerpt plus a Guardian-visible Discourse topic image URL; never serialize raw post content or introduce unbounded per-request content scans for feed cards. An image and bounded excerpt may be rendered together.
29. Community logo/cover branding must reuse Discourse `Upload` records and supported upload UI. Assignment is manager-only, image-only, and must not allow a manager to attach an arbitrary unrelated user's upload by guessing its ID. Keep explicit `UploadReference` records for attached branding, keep internal upload IDs manager-only, and preserve Guardian/category visibility as the boundary for community metadata.

## Current phase — RC3 native Community architecture

Implemented foundations inherited from RC2:

- Community creation links a real Category plus member/moderator Groups.
- Join/leave membership uses the mapped Discourse Group.
- Owner/community-moderator management remains community-scoped.
- Voting/ranking persists plugin scores without replacing Discourse likes/posts.
- Popular uses a cached public candidate pool and Guardian filtering.
- Home blends joined communities, followed users through Discourse Follow, and public fallback topics.
- Following contains only joined-community and followed-user content and returns no personalized data to guests.
- Explore excludes joined communities, applies a per-community diversity cap, and keeps every candidate behind Guardian visibility checks.
- Explore ranking/recommendation and activity analytics use scheduled cache rebuilds rather than request-time full-table work.
- Feed previews are bounded and Guardian filtered.
- Community branding uses Discourse Upload records and explicit UploadReference retention.
- AutoModerator is community/category scoped, bounded, asynchronous, idempotent, review-first, and audited.
- Manager-only moderation and analytics surfaces remain non-indexable/non-cacheable and do not expose raw user/content data.

RC3 direction:

- The real Discourse homepage `/` is the Community feed. The plugin's registered `community-home` homepage is the implementation surface selected through Discourse's supported homepage mechanism.
- User-facing Community links use the mapped native Discourse Category URL instead of `/s/:slug`.
- Topic cards continue to link to the real Discourse `/t/...` topic URL. Do not create a parallel discussion URL.
- Native Category pages are progressively styled/enriched as Community pages instead of maintaining a separate Community route tree.
- Native Topic pages are progressively integrated into the Community shell while keeping Discourse Post Stream, composer, permissions, notifications, moderation, search, and SEO intact.
- Product language and visuals should be original Community UX, not Reddit-specific prefixes or cloning.
- Feed cards render a bounded excerpt even when a visible topic image exists; the image and text summary complement each other.
- `/home` may remain as the registered homepage implementation/compatibility path during the migration, but primary navigation must point to `/`.
- Legacy `/s/:slug` code is transitional only. Do not add new features that depend on it; remove it after native Category management/community UI reaches parity.

Next slices:

1. Finish native Category URL conversion and exact-head regression coverage.
2. Validate the registered Community homepage at real `/` in staging and document the `default_homepage` selection.
3. Port Community hero, membership, rules, branding, manager tools, AutoModerator, and analytics into supported native Category-page integration points.
4. Integrate Community context into native `/t/...` topic pages without replacing Discourse Post Stream/composer.
5. Evolve the Home visual system toward the approved Senin Community layout: left navigation/community list, center social topic cards and order controls, right trends/recommendations/about rail.
6. Re-run desktop/tablet/mobile, permission, performance, accessibility, install/upgrade, and release checks before selecting an RC3 candidate.

## SEO contract

- Keep Discourse topic/post SEO and crawler behavior as the base.
- Community landing pages use their native Discourse Category URLs; do not create an indexable Community alias tree.
- Private/restricted communities must not expose metadata, counts, titles, previews, images, or topic content to unauthorized users or crawlers.
- Topic content remains single-source on normal Discourse `/t/...` URLs.
- Rich feed cards are navigation/UI summaries only, not alternate topic documents.
- AutoModerator configuration, execution-history, moderation-insights, and community activity analytics endpoints are authenticated management surfaces and must not become indexable public content.
- Manager-only JSON surfaces must send `X-Robots-Tag: noindex, nofollow` and `Cache-Control: private, no-store` even when authentication or authorization fails.

## Release contract

- `CHANGELOG.md` describes published releases and the current unreleased iteration; tagged content must match the code actually published.
- `RELEASE_CHECKLIST.md` is a required release gate, not optional documentation.
- Plugin version metadata must be changed intentionally when the exact next release revision is known; do not bump it early merely to signal progress.
- A green PR is not equivalent to a tested release. Staging smoke tests must run after the candidate revision is determined and before a prerelease is published.
- Keep a database backup and previous known-good plugin revision available before production rollout.

## Code style

Follow the current official Discourse plugin skeleton and Discourse lint/format rules. Prefer namespaced, Zeitwerk-autoloadable Ruby classes over large `plugin.rb` files.
