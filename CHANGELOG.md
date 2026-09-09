# Changelog

All notable changes to Discourse Community Platform are documented here.

The project is still pre-stable. Until the first stable release, breaking changes may occur between release candidates when required to preserve Discourse compatibility, permission boundaries, or data safety.

## [Unreleased]

### Added

- Mapped Communities now enrich native Discourse `/c/...` Category pages with Community identity, branding, rules, membership state, and scoped management while preserving the native TopicList and Category behavior.
- Community managers can use the existing management form, branding uploaders, AutoModerator controls, moderation insights, and activity analytics directly on the mapped native Category page without gaining global staff privileges.
- Native `/t/...` Topic pages can show compact mapped Community context through a supported plugin outlet while leaving Discourse Post Stream, composer, bookmarks, notifications, moderation, and canonical Topic URLs intact.
- Home can show a bounded set of cached, Guardian-filtered Community recommendations in the existing discovery rail without introducing request-time ranking work or a second recommendation store.
- Joined Communities are available from the platform navigation rail on desktop and a horizontal navigation strip on narrower layouts, keeping the center column focused on topic content.

### Changed

- Public Community navigation is now pinned to native Discourse Category URLs, while Topic navigation remains on native `/t/...` URLs.
- The registered `community-home` homepage is validated as the product Home at the real site root `/`; primary Home navigation and empty-state return actions now use `/`, while `/home` remains only as an implementation/compatibility path.
- The standalone `/s/:slug` Community renderer has been retired. Historical aliases are handled by native Discourse permalinks and redirect to the mapped Category, with the Ember compatibility route remaining redirect-only for in-app legacy navigation.
- Home, Following, Popular, and Explore retain their existing discovery/trend rails on tablet and mobile by moving the same rail below the feed rather than hiding it or rendering a duplicate copy.

### Fixed

- Disabling `community_platform_enabled` now makes Popular, Explore recommendation, activity analytics, AutoModerator audit-pruning, and already-queued AutoModerator evaluation jobs no-op at execution time; re-enabling the plugin preserves existing Community mappings, Group membership, votes, and topic scores.
- Legacy Community permalink backfill rollback is now explicitly irreversible instead of deleting matching Discourse `Permalink` rows whose migration provenance cannot be proven, preventing a pre-existing alias from being removed during rollback.
- The signed-in empty Following state now links back to canonical Home `/` instead of exposing the `/home` compatibility URL.
- Native Community and manager layouts remain width-bounded on constrained tablet/mobile viewports, including rich Home previews, branding upload controls, management fields, and discovery rails.

### Security and privacy

- Legacy `/s/:slug` redirects use Discourse `Permalink` records and core Category visibility checks, so private Community aliases do not disclose inaccessible destinations.
- Native Category Community lookup and native Topic Community context continue to resolve behind the current Guardian Category boundary; unmapped or invisible Categories fail soft without Community UI.
- Plugin shutdown now prevents stale scheduled or queued plugin-owned moderation/cache work from continuing after the enablement setting is turned off.

### Accessibility and responsive UI

- Native Community manager tools remain keyboard-usable on narrow mobile layouts, including management-form submission and Discourse `UppyImageUploader` logo/cover selection and removal.
- Explore quick join keeps Category navigation and membership actions as separate keyboard targets, announces successful joins with status semantics, and reports failures through an alert.
- Activity Insights, Moderation Insights, and AutoModerator manager regions expose usable accessible names and preserve existing table/status semantics.
- Native Topic Community links remain keyboard reachable while Discourse's normal Reply action continues to open the core composer with the native Post Stream intact.
- Real-browser responsive regressions cover native Category/Topic Community surfaces and Home/Following/Popular/Explore layouts at constrained tablet and mobile widths.

### Performance

- Feed query-scaling regressions enforce bounded first-post preview loading and prevent joined-Community Category hydration from regressing into per-topic or per-community N+1 query growth.
- Home Community recommendations continue to reuse the scheduled Explore recommendation cache and remain bounded instead of rebuilding ranking signals during requests.

### Development and release quality

- Official Discourse Plugin CI now treats the real Chrome plugin system-test suite as a required RC gate alongside backend RSpec, frontend QUnit, annotations, Ember build, lint, formatting, and type checks.
- Real Chrome regressions cover the registered root Community homepage, Home voting persistence, platform feed history, direct native Category → Topic navigation, native Category/Topic back-forward history, and the combined root Home → native Category → native Topic history chain.
- Scheduled Community Platform jobs now have regression coverage for MiniScheduler registration, the default queue, and their exact configured cadences.
- RC3 upgrade coverage verifies that the legacy permalink backfill preserves existing Community mappings and Group membership, votes and TopicScore aggregates, AutoModerator rules, and execution/audit history while adding only the missing compatibility alias.
- Release documentation now reflects native `/c/...` Community pages and `/t/...` Topic pages as the active public product surfaces; `/s/:slug` and `/home` are compatibility/implementation paths rather than primary UI routes.

## [0.1.0-rc.2] - 2026-09-02

### Added

- Rich feed cards can show a Guardian-visible Discourse topic image or, when no image is available, a bounded plain-text excerpt from the visible first regular post.
- Rich previews are shared across Community, Home, Following, Explore, and Popular topic cards without creating a second content store or alternate canonical topic URL.
- Feed topic context now carries the Discourse author avatar/username and relative creation time across Home, Following, Popular, and Explore cards; Explore also preserves the same rich preview and Community identity contract as the other feeds.
- Home, Following, Explore, Popular, and `/s/:slug` now share a route-scoped platform shell with a custom header, responsive navigation, center content column, and contextual discovery rail while leaving normal Discourse routes untouched.
- Platform feed cards now expose a real topic discussion link plus existing view/like counters in a shared social action row; no second comment system is introduced.
- Home, Following, Explore, and Popular receive a bounded right-rail Popular summary sourced from the existing background-ranked Popular cache.
- `/s/:slug` Community topic cards now use the same author/time, rich preview, canonical discussion action, and responsive vote-card hierarchy as the global platform feeds.
- Explore recommendations now live in a single shell-owned discovery rail with compact Community join controls and real Discourse user avatars instead of duplicating recommendation grids in the center feed.
- Community managers can upload a logo and cover image through Discourse's supported image uploader UI; emoji and banner color remain fallbacks.
- Explore community cards can display uploaded community logos.
- Uploaded community logos now appear consistently in Home/Following joined-community chips and Home/Following/Popular/Explore topic context links, with emoji or initial fallbacks when no logo is available.
- Signed-in eligible users can join a recommended public Community directly from Explore; the action still delegates membership changes to the existing Discourse-backed Community join endpoint.
- Community branding uploads are retained with explicit `UploadReference` records so normal Discourse cleanup does not treat active branding as orphaned files.
- English and Turkish management copy for logo and cover-image controls.

### Security and privacy

- Feed preview extraction runs only after the topic passes the current Guardian visibility check, and the preview contract never returns raw post content or cooked HTML.
- Topic image previews are returned only when the current Guardian can see the underlying Discourse upload.
- Community branding assignment is manager-only, image-only, and rejects arbitrary unrelated-user upload IDs; internal branding upload IDs are serialized only to authorized community managers.
- Community logo and cover URLs also pass through the current Discourse Guardian upload-visibility check, preventing a visible Community response from bypassing secure-upload access rules.
- Feed community identity returns a branding image URL only when the current Guardian can see that Discourse upload.
- Explore quick-join capability is only advertised for an eligible authenticated user; the server-side membership service remains authoritative for Guardian visibility, staged/suspended-account checks, private-community protection, and mapped Group membership.
- Right-rail Popular summaries are Guardian-filtered and intentionally omit topic previews, author context, user votes, and raw post content.

### Accessibility and responsive UI

- Rich image/text previews preserve normal topic links and remain responsive on desktop, mobile, and constrained tablet layouts.
- Community logo/cover controls reuse Discourse's keyboard-accessible `UppyImageUploader` component.
- Feed author/time context uses Discourse's native avatar and relative-date UI primitives and keeps community, author, and timestamp as separate accessible links/text.
- Explore recommendation cards keep navigation and membership actions as separate interactive controls, announce successful joins with status semantics, and expose membership failures through an alert.
- Explore people recommendations use Discourse's native `DUserAvatar` profile-link primitive rather than placeholder avatar glyphs or nested profile anchors.
- The platform shell keeps native links, search semantics, current-user profile navigation, active-route state, and separate desktop/mobile navigation while using Discourse-supported `apiInitializer` and `onPageChange` APIs instead of core patches.
- The signed-in shell account control no longer nests `DUserAvatar`'s native profile link inside a second anchor; avatar and username remain separate keyboard-focusable links to the same Discourse profile.
- Feed author context no longer nests `DUserAvatar` inside a second author anchor; avatar and `@username` are sibling keyboard-focusable links to the same canonical Discourse profile across Home, Following, Explore, Popular, and Community cards.
- Community feed ordering now exposes Hot/New/Top/Rising as one named control group while preserving per-button `aria-pressed` state.
- Platform feed cards use a denser feed-first hierarchy with compact route headings, edge-to-edge media crops, interaction-stat pills, stronger keyboard focus treatment, and mobile vote controls that move above the post body instead of squeezing the content column.
- Home and Following avoid duplicating joined Communities in the center column when the desktop right rail is visible; the horizontal list remains available automatically when the rail collapses on tablet and mobile.
- Feed discussion links and right-rail trend titles retain visible keyboard focus treatment and native link semantics.
- Inside the platform shell, Community About, Rules, and manager controls become a responsive details grid below the topic feed instead of consuming a second nested right sidebar; all controls remain present on tablet and mobile.
- Explore keeps one recommendation component across breakpoints: the desktop rail moves below the feed on tablet/mobile instead of rendering a second stale copy of join state.
- Community feed order controls are exposed as a named semantic group while each order button keeps its pressed state.
- A route-level regression gate now rejects nested interactive controls across the signed-in platform shell, including profile links, vote controls, previews, and rail navigation.

### Performance

- Right-rail Popular summaries reuse the existing cached Popular topic IDs and hydrate at most a small bounded set instead of running the ranking aggregate during a page request.

### Development and release quality

- The repository now uses the official Discourse-style pnpm frontend toolchain with a committed lockfile and current Discourse type declarations.
- Official Discourse Plugin CI now executes ESLint, Stylelint, Prettier, and Glint/TypeScript checks instead of silently skipping those frontend gates.
- Existing JavaScript/GJS and SCSS sources were normalized through the official Prettier and Stylelint fixers without changing runtime behavior.
- The release-candidate checklist now requires frontend dependency detection and successful non-skipped ESLint, Stylelint, Prettier, and Types gates; skipped workflow steps must be recorded as skipped rather than counted as passed.

## [0.1.0-rc.1] - 2026-09-02

### Added

- Community records mapped 1:1 to real Discourse categories.
- Community membership through mapped Discourse groups.
- Community-scoped owner/moderator management without global staff escalation.
- Responsive `/s/:slug` community experience with hot/new/top/rising topic ordering.
- Plugin-owned upvote/downvote scores while preserving Discourse posts/likes as source-of-truth data.
- Cached Popular feed plus Home, Following, and Explore feeds with Guardian visibility filtering.
- Explore recommendation signals rebuilt in scheduled cache jobs rather than request-time full scans.
- Community-scoped AutoModerator phrase rules with bounded any/all matching.
- Bounded AutoModerator targets for all posts, topic starters, or replies.
- Optional bounded author conditions for account age and trust level.
- Review-first AutoModerator actions using Discourse `PostActionCreator`.
- Background evaluation for new posts and meaningful edits with per-post mutex serialization and SHA-256 deduplication.
- Manager-only AutoModerator execution history with 90-day retention.
- Manager-only moderation insights over bounded audit data.
- Manager-only 7/30-day community activity analytics rebuilt in scheduled cache jobs.
- English and Turkish client copy for Community Platform management surfaces.

### Fixed

- Direct browser navigation to `/home`, `/following`, `/explore`, and `/popular` now boots the Discourse Ember shell instead of falling through to a Rails routing error.
- AutoModerator edit re-evaluation now recognizes an existing system `inappropriate` review score even when Discourse has retired the original `PostAction`, preventing duplicate system flags on the same post.
- Community hero identity/actions now wrap cleanly on constrained tablet widths where Discourse keeps the desktop sidebar visible, preventing community titles from breaking inside words on iPad-class layouts.

### Security and privacy

- Community/category visibility is checked through Discourse Guardian before plugin data is serialized.
- Private/restricted community data is not exposed through public feed/discovery paths.
- AutoModerator does not support arbitrary user regex, direct delete, ban, silence, or global moderator escalation.
- Management-only JSON endpoints return `X-Robots-Tag: noindex, nofollow` and `Cache-Control: private, no-store`, including unauthenticated and unauthorized responses.
- Analytics responses contain aggregate counts only and do not serialize contributor identity, raw content, email, IP, or device data.

### Performance

- Popular and Explore candidate work uses background cache computation.
- Community activity analytics are rebuilt every 15 minutes with a 30-minute cache TTL.
- Cold analytics caches fail soft with a bounded warming snapshot instead of synchronous aggregate rebuilds.
- AutoModerator audit retention is bounded to 90 days.

### Accessibility

- Manager insight regions have explicit accessible names.
- Community activity metrics expose table/row/header/cell semantics.
- Asynchronous warming states use status semantics.
- Native keyboard-accessible buttons, links, inputs, and selects remain in use.

### Compatibility

- No Discourse core patches.
- Discourse remains the source of truth for users, topics, posts, categories, groups, permissions, review, search, and canonical topic SEO.
- Plugin metadata currently requires Discourse `3.5.0` or newer.

## Release policy

A release candidate is published only after the exact release commit passes the Official Discourse Plugin CI and the staging smoke-test checklist in `RELEASE_CHECKLIST.md` is completed.
