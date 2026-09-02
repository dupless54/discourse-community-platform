# Changelog

All notable changes to Discourse Community Platform are documented here.

The project is still pre-stable. Until the first stable release, breaking changes may occur between release candidates when required to preserve Discourse compatibility, permission boundaries, or data safety.

## [Unreleased]

### Added

- Rich feed cards can show a Guardian-visible Discourse topic image or, when no image is available, a bounded plain-text excerpt from the visible first regular post.
- Rich previews are shared across Community, Home, Following, Explore, and Popular topic cards without creating a second content store or alternate canonical topic URL.
- Feed topic context now carries the Discourse author avatar/username and relative creation time across Home, Following, Popular, and Explore cards; Explore also preserves the same rich preview and Community identity contract as the other feeds.
- Home, Following, Explore, Popular, and `/s/:slug` now share a route-scoped platform shell with a custom header, responsive navigation, center content column, and contextual discovery rail while leaving normal Discourse routes untouched.
- Platform feed cards now expose a real topic discussion link plus existing view/like counters in a shared social action row; no second comment system is introduced.
- Home, Following, Explore, and Popular receive a bounded right-rail Popular summary sourced from the existing background-ranked Popular cache.
- `/s/:slug` Community topic cards now use the same author/time, rich preview, canonical discussion action, and responsive vote-card hierarchy as the global platform feeds.
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
- The platform shell keeps native links, search semantics, current-user profile navigation, active-route state, and separate desktop/mobile navigation while using Discourse-supported `apiInitializer` and `onPageChange` APIs instead of core patches.
- Platform feed cards use a denser feed-first hierarchy with compact route headings, edge-to-edge media crops, interaction-stat pills, stronger keyboard focus treatment, and mobile vote controls that move above the post body instead of squeezing the content column.
- Home and Following avoid duplicating joined Communities in the center column when the desktop right rail is visible; the horizontal list remains available automatically when the rail collapses on tablet and mobile.
- Feed discussion links and right-rail trend titles retain visible keyboard focus treatment and native link semantics.
- Inside the platform shell, Community About, Rules, and manager controls become a responsive details grid below the topic feed instead of consuming a second nested right sidebar; all controls remain present on tablet and mobile.

### Performance

- Right-rail Popular summaries reuse the existing cached Popular topic IDs and hydrate at most a small bounded set instead of running the ranking aggregate during a page request.

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
