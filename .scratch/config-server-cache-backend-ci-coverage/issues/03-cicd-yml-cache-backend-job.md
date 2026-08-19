# 03 — `cicd.yml`: second job for the config-server-backed cache

**What to build:** A second job in `cicd.yml` — parallel in structure to how `matrix-cicd.yml` calls `single.yml` per matrix leg — that calls the (now-extended) `single.yml` with `cache_type: config-server` and the reduced suite list `00-setup`, `01-crs`, `05-cache-backend`. This job performs its own full, independent cluster bring-up (containerlab + kind); it does not share state or a running cluster with the existing `local`-backend job. With this ticket done, every `cicd.yml` pipeline run deploys `data-server` with `Cache.Type: config-server` at least once and fails clearly if the `05-cache-backend` suite fails (e.g. because `ConfigReadService` isn't actually being hit).

Not added to `matrix-cicd.yml` — the matrix's purpose is version-compatibility coverage across `config-server`/`data-server` releases, orthogonal to cache-backend correctness, and pairing every matrix leg with a second job would re-multiply the exact runtime cost this design avoids.

**Blocked by:** 01, 02 (needs both the `single.yml` inputs and the suite content to exist before it can be wired together end-to-end).

**Status:** done

- [x] `cicd.yml` gains a second job calling `single.yml` with `cache_type: config-server` and suites limited to `00-setup`, `01-crs`, `05-cache-backend`
- [x] The new job deploys its own cluster independently of the existing `local`-backend job (no shared cluster, no mid-job restart of `data-server-controller` against the existing job's deployment)
- [x] The existing `local`-backend job in `cicd.yml` is unchanged and continues to run `00`–`04` as today
- [x] `matrix-cicd.yml` is not modified
- [ ] A full `cicd.yml` run (e.g. via `workflow_dispatch`) shows both jobs passing, with the new job's logs/artifacts confirming `cache.type: config-server` was applied and `05-cache-backend` passed
- [ ] PR for this work (and tickets 01/02) is based on and targets/stacks against `sdcio/integration-tests` PR [#113](https://github.com/sdcio/integration-tests/pull/113) per the branching decision in the spec, retargeting to `main` once #113 merges
