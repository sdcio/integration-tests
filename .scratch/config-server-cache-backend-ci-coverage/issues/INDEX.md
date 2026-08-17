# Index: CI coverage for the config-server cache backend

Tracks implementation status of the tickets derived from [`../spec.md`](../spec.md). Update the **Status** column and checkbox as work lands. Tickets are numbered in dependency order (blockers first); the frontier is any `[ ]` ticket whose blockers are all `[x]`.

External prerequisite (not a ticket here, tracked upstream): `sdcio/integration-tests` PR [#113](https://github.com/sdcio/integration-tests/pull/113) must merge before any of these can retarget from a stacked branch to `main` — see ticket 03's acceptance criteria.

| # | Ticket | Blocked by | Status | Done |
|---|--------|------------|--------|------|
| 01 | [`single.yml`: `cache_type` + suite-selection inputs](01-single-yml-cache-type-inputs.md) | None | in-progress | [ ] |
| 02 | [`tests/05-cache-backend` suite (CRUD round-trip + restart-recovery)](02-cache-backend-suite.md) | 01 | ready-for-agent | [ ] |
| 03 | [`cicd.yml`: second job for the config-server-backed cache](03-cicd-yml-cache-backend-job.md) | 01, 02 | ready-for-agent | [ ] |

## Status legend

- `ready-for-agent` — not yet started, blockers satisfied or none
- `blocked` — blockers not yet done
- `in-progress` — actively being worked
- `done` — merged/landed

## Notes

- No issue tracker is configured for this repo (per spec's Further Notes), so these tickets are local files only. Do not publish them to GitHub Issues or any other tracker.
