# Discourse Community Platform

A community-platform plugin for Discourse that adds Reddit-inspired communities, membership, moderation, voting, ranking, discovery, and personalized feeds while preserving Discourse core models, permissions, search, and SEO behavior.

> Status: active development / Phase 3 — Feeds & Discovery

## Architecture principles

- Discourse remains the source of truth for users, topics, posts, categories, groups, tags, uploads, notifications, search, and bookmarks.
- Communities are a plugin-owned layer mapped to real Discourse categories.
- Community permissions extend Discourse Guardian/group/category permissions instead of bypassing them.
- Public content remains compatible with Discourse SEO/crawler behavior; private or restricted content must never leak through plugin endpoints.
- Do not patch Discourse core files.
- New public aliases such as `/s/:slug` must not create duplicate indexable copies of the same topic content.
- User-follow personalization integrates with Discourse Follow when its `UserFollower` API is available instead of creating a competing follow graph.

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

### Feed backend contracts

```text
GET /community-platform/feeds/home.json
GET /community-platform/feeds/following.json
GET /community-platform/feeds/explore.json
GET /community-platform/feeds/popular.json
```

All plugin feeds continue to filter candidate content through Discourse visibility/Guardian rules before serialization.

## Roadmap

1. Harden Explore ranking with more recommendation signals while keeping expensive scoring in jobs/cache.
2. Add social/profile discovery surfaces without duplicating Discourse Follow relationships.
3. Add AutoModerator and community-scoped moderation automation.
4. Add community analytics and moderation insights.
5. Finish responsive polish, accessibility, and release hardening.

## License

MIT
