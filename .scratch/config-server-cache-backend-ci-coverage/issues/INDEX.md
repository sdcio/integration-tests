# Index: CI coverage for the config-server cache backend

Tracks implementation status of the tickets derived from [`../spec.md`](../spec.md). Update the **Status** column and checkbox as work lands. Tickets are numbered in dependency order (blockers first); the frontier is any `[ ]` ticket whose blockers are all `[x]`.

External prerequisite (not a ticket here, tracked upstream): `sdcio/integration-tests` PR [#113](https://github.com/sdcio/integration-tests/pull/113) must merge before any of these can retarget from a stacked branch to `main` — see ticket 03's acceptance criteria.

**Branching (mirrors `sdcio/data-server`'s pattern):** tickets 01/02 land on the `config-server-cache-backend` branch, PR [#115](https://github.com/sdcio/integration-tests/pull/115), targeting `feat/sensitiveData` (PR #108) — not `main` — the same way `sdcio/data-server`'s `config-server-cache-backend` branch (PR [#471](https://github.com/sdcio/data-server/pull/471)) targets `sensitive` (PR #460) instead of `main`. PR #115 bundles PR #113's `config-keyring` Secret fix directly (rather than only pairing with it) since it's a hard, cache-backend-independent prerequisite for any `data-server-controller` deploy. `sdcio/data-server`#471 now pairs with `sdcio/integration-tests`#115 instead of #113.

| # | Ticket | Blocked by | Status | Done |
|---|--------|------------|--------|------|
| 01 | [`single.yml`: `cache_type` + suite-selection inputs](01-single-yml-cache-type-inputs.md) | None | in-progress | [ ] |
| 02 | [`tests/05-cache-backend` suite (CRUD round-trip + restart-recovery)](02-cache-backend-suite.md) | 01 | in-progress | [ ] |
| 03 | [`cicd.yml`: second job for the config-server-backed cache](03-cicd-yml-cache-backend-job.md) | 01, 02 | done | [x] |

## Status legend

- `ready-for-agent` — not yet started, blockers satisfied or none
- `blocked` — blockers not yet done
- `in-progress` — actively being worked
- `done` — merged/landed

## Notes

- No issue tracker is configured for this repo (per spec's Further Notes), so these tickets are local files only. Do not publish them to GitHub Issues or any other tracker.
