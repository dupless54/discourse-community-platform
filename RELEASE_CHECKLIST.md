# Release Candidate Checklist

Use this checklist before publishing a Discourse Community Platform release candidate. Do not tag or publish a release from a commit that has not passed every required automated gate.

## 1. Exact-head automated gates

- [ ] PR head SHA is recorded.
- [ ] Branch is `behind_by=0` against `main` immediately before merge.
- [ ] Official Discourse Plugin CI is associated with that exact head SHA.
- [ ] `check_for_tests` passes.
- [ ] RuboCop passes.
- [ ] Syntax Tree passes.
- [ ] Plugin annotations pass.
- [ ] Zeitwerk eager-load check passes.
- [ ] Zeitwerk reload check passes.
- [ ] `SKIP_DB_AND_REDIS` bootability check passes.
- [ ] Plugin RSpec passes.
- [ ] Ember Build passes.
- [ ] Plugin QUnit passes.
- [ ] System tests are either successful or explicitly skipped because the plugin has no applicable system-test suite.

## 2. Staging install / upgrade smoke test

Run these checks on a non-production Discourse instance using the exact release-candidate commit/tag.

- [ ] Fresh plugin install completes without migration or boot errors.
- [ ] Existing installation upgrades without losing Community records, votes, AutoModerator rules, or audit history.
- [ ] Plugin can be disabled and re-enabled without boot errors.
- [ ] Sidekiq starts and scheduled Community Platform jobs are registered.
- [ ] `/home`, `/following`, `/explore`, and `/popular` load successfully.
- [ ] A public Community loads at `/s/:slug`.
- [ ] Restricted/private Community visibility behaves like its mapped Discourse Category.
- [ ] Join and leave update the mapped member Group correctly.
- [ ] Hot/new/top/rising ordering can be switched without a full-page failure.
- [ ] Upvote/downvote works for an authenticated user and does not replace Discourse likes/posts.

## 3. AutoModerator smoke test

- [ ] Community manager can create, update, disable, and delete a bounded phrase rule.
- [ ] Ordinary member cannot access rule management endpoints.
- [ ] Guest cannot access rule management endpoints.
- [ ] New matching post creates the configured review-first moderation action.
- [ ] Meaningful edit re-evaluates the post.
- [ ] Identical rule/post/content is not actioned twice.
- [ ] `queue_for_review` uses the priority review path.
- [ ] `flag_only` creates a standard Discourse flag without direct destructive moderation.
- [ ] Audit history shows rule-name snapshot, trigger, outcome, and currently visible post metadata.
- [ ] Audit history does not reveal post/user metadata after the audited post becomes invisible to the manager.

## 4. Analytics and performance smoke test

- [ ] Explore recommendation cache job runs successfully.
- [ ] Community activity analytics cache job runs successfully.
- [ ] Cold activity analytics returns `warming` rather than synchronously rebuilding aggregates.
- [ ] 7-day and 30-day activity metrics are plausible for a known test Community.
- [ ] Community analytics do not contain usernames, user IDs, post IDs/URLs, raw content, email, IP, or device data.
- [ ] Moderation insights remain bounded to manager-visible aggregate management data.

## 5. Security / crawler / cache checks

For AutoModerator rules, audit history, moderation insights, and community activity analytics:

- [ ] Authorized manager response includes `X-Robots-Tag: noindex, nofollow`.
- [ ] Authorized manager response includes `Cache-Control: private, no-store`.
- [ ] Authenticated unauthorized 403 response keeps both hardening headers.
- [ ] Guest 403 response keeps both hardening headers.
- [ ] Public feeds do not serialize private/restricted Community content.
- [ ] `/s/:slug` does not create an alternative canonical copy of topic content; topic links remain normal Discourse `/t/...` URLs.

## 6. Accessibility / responsive smoke test

Check desktop, tablet, and mobile widths.

- [ ] Community title and major manager insight sections have usable accessible names.
- [ ] Feed order buttons expose pressed state.
- [ ] Vote buttons expose labels and pressed state.
- [ ] Activity insight table is understandable with a screen reader/navigation inspector.
- [ ] Loading/warming status is exposed without trapping keyboard focus.
- [ ] Forms remain keyboard operable.
- [ ] Management cards do not overflow or hide primary actions on narrow screens.

## 7. Release publication

Only after sections 1–6 are complete:

- [ ] Confirm `CHANGELOG.md` matches the release candidate.
- [ ] Confirm plugin metadata version/required Discourse version are intentional.
- [ ] Create an annotated release tag from the tested merge commit.
- [ ] Create a GitHub prerelease using the changelog summary.
- [ ] Record the exact tag SHA in the release notes.
- [ ] Keep the previous known-good tag available for rollback.

## 8. Rollback readiness

- [ ] Database backup exists before production rollout.
- [ ] Previous known-good plugin tag/commit is recorded.
- [ ] Rollback procedure is understood: restore previous plugin revision and rebuild/restart Discourse as appropriate.
- [ ] No release step assumes destructive migration rollback.
