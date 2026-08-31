# Discourse Community Platform

A community-platform plugin for Discourse that adds Reddit-inspired communities, membership, moderation, voting, ranking, discovery, and personalized feeds while preserving Discourse core models, permissions, search, and SEO behavior.

> Status: early development / Phase 1 — Community Core

## Architecture principles

- Discourse remains the source of truth for users, topics, posts, categories, groups, tags, uploads, notifications, search, and bookmarks.
- Communities are a plugin-owned layer mapped to real Discourse categories.
- Community permissions extend Discourse Guardian/group/category permissions instead of bypassing them.
- Public content remains compatible with Discourse SEO/crawler behavior; private or restricted content must never leak through plugin endpoints.
- Do not patch Discourse core files.
- New public aliases such as `/r/:slug` must not create duplicate indexable copies of the same topic content.

## Phase 1

The first milestone establishes the Community Core:

- plugin skeleton and isolated Rails engine
- community persistence model
- category/community mapping
- owner/member/moderator group references
- public/restricted/private visibility model
- `/r/:slug` path contract
- authorization and validation foundations
- automated tests

### Current backend contract

A visible community can be read from:

```text
GET /community-platform/communities/:slug.json
```

The response includes the future user-facing community path (`/r/:slug`) while the plugin continues to defer access decisions to Discourse Guardian/category permissions.

## Roadmap

1. Atomic community creation: Category + member Group + moderator Group + Community.
2. Join/leave membership APIs.
3. Owner and community-moderator authorization.
4. Rules, flair, banner/icon configuration.
5. `/r/:slug` frontend experience.
6. Upvote/downvote and ranking engine.
7. Popular, Explore, Following, and personalized feeds.
8. AutoModerator and community analytics.

## License

MIT
