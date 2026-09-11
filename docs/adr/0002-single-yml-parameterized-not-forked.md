# Extend `single.yml` with inputs instead of forking a second reusable workflow

Context: the config-server cache-backend job (see ADR 0001) needs a different `cache.type`/`cache.address` in the deployed ConfigMap and a reduced suite list (skip `02-crud`/`03-deviations`/`04-sensitive`) compared to the existing job.

Decided: add optional inputs to `single.yml` (`cache_type`, `suites_to_run` or equivalent) rather than duplicating its ~250 lines of cluster bring-up, log collection, and teardown into a second reusable workflow file. `cache.type`/`cache.address` are set by extending the existing `yq`-patch step in "Set the versions to test" (the same mechanism already used for `DEVIATION_INTERVAL` and the trace flag) — not by adding a new kform input variable to `config-server`'s `configmap-input-vars.yaml.tmpl`. A real kform-level cache-type input is a legitimate future ask for actual deployers, but it's a fourth repo-touching change orthogonal to proving the backend works, and shouldn't ride on this CI work.

Rejected: a forked `single-cache-backend.yml` (duplication rots when one copy gets a fix the other doesn't); a `config-server`-side kform input variable (couples an operator-facing feature to CI plumbing, and touches a repo beyond the two already in flight).
