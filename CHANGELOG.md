# Changelog

All notable changes to Discourse Community Platform are documented here.

The project is still pre-stable. Until the first stable release, breaking changes may occur between release candidates when required to preserve Discourse compatibility, permission boundaries, or data safety.

## [0.1.0-rc.1] - Unreleased

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
