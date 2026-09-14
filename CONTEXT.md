# SDC Integration Tests

End-to-end validation of Schema Driven Configuration across Kubernetes control plane, controller reconciliation, and network device state.

## Language

**Sensitive feature tests**:
Integration tests that cover the paired `sensitive` branches on config-server and data-server — secret resolution on the control plane and northbound redaction on the datastore.
_Avoid_: Security tests, secret tests (too vague)

**Sensitive config pipeline**:
The config-server flow where Config `secretRef` vars are resolved, encrypted into SensitiveConfig, applied to the device via TargetConfig, and recorded in TargetSnapshot for recovery.
_Avoid_: Secret handling, encryption flow

**Northbound redaction**:
The data-server behavior that masks sensitive leaf values as `***` in operator-facing reads (GetIntent, BlameConfig, deviation streaming) while leaving southbound device apply unchanged.
_Avoid_: Secret masking, value hiding

**Sensitive test suite (`04-sensitive`)**:
Dedicated Robot suite for sensitive config pipeline scenarios — new CRDs, KeyRing, Resolver, TargetSnapshot, and recovery. Separate from existing CRUD matrices.
_Avoid_: Sensitive suite, secrets suite

**Sensitive test stages**:
Within `04-sensitive`, scenarios are tagged by stage: happy path (K8s + device), `recovery` (pod-restart replay), `negative` (missing secret → ConfigResolverFailed), `keyring` (key rotation re-encryption). All four stages are in the initial implementation.
_Avoid_: Lumping all assertions into one monolithic scenario

**KeyRing Secret**:
A Kubernetes Secret labeled `config.sdcio.dev/keyring: "true"` containing the AES-256 key material the Resolver loads at startup. Installed in `01-crs` so it is present before the controller starts.
_Avoid_: Encryption secret, key secret

**Payload Secret**:
A Kubernetes Secret containing the actual sensitive value (e.g. a credential string) that a Config's `secretRef` var resolves to. Lifecycle owned by the `04-sensitive` Suite Setup/Teardown.
_Avoid_: Sensitive secret, test secret

**Sensitive fixture**:
The minimal Config CR used in `04-sensitive` — single-node Config on `srl1`, `ethernet-1/6`, setting only the interface description to the resolved secret value. No VRF.
_Avoid_: Sensitive intent, test intent

**04-sensitive test cases**:
Seven cases in `10-srl-sensitive.robot`: (1) K8s pipeline happy path, (2) southbound runningconfig unredacted, (3) blame redacts `***`, (4) deviation on sensitive leaf masked, (5) missing secret → ConfigResolverFailed + last-good SC preserved, (6) pod-restart recovery via TargetSnapshot, (7) TODO placeholder for `include_sensitive` admin bypass pending kubectl-sdc flag.

**Cache-backend suite (`05-cache-backend`)**:
Dedicated Robot suite proving the config-server-backed `Cache.Type` implementation works. It never switches `Cache.Type`; a caller must already have deployed a cluster with that backend. Scoped to the seam — a CRUD round-trip through `ConfigReadService` plus a `data-server-controller` restart-recovery check. The cache-backend job also runs `02-crud` and `03-deviations` against that same deploy; `04-sensitive` stays on the local-backed job only.
_Avoid_: Cache backend tests, config-server cache suite, reconfiguring the environment

**Cache-backend job**:
A CI job that deploys with `Cache.Type: config-server` and then runs `00-setup`, `01-crs`, `02-crud`, `03-deviations`, and `05-cache-backend`. Requested by data-server and config-server PR CI, and by this repo’s dispatch `cicd.yml`. Not by Pairs-with, and not by `matrix-cicd.yml`.
_Avoid_: the cache test, the cicd.yml job (too vague — this repo’s `cicd.yml` is only one caller)

**Caller workflow**:
data-server or config-server CI that invokes `single.yml` on integration-tests `main`. Distinct from this repo’s own `cicd.yml`.
_Avoid_: paired workflow, the integration-tests workflow

**Missing-suite skip**:
An explicit suite step that does nothing when that suite’s directory is absent from the checked-out integration-tests revision. Keeps old Pairs-with checkouts green after `single.yml` names `04`/`05` explicitly.
_Avoid_: optional suite (sounds like suites_to_run), glob skip (that is auto-discovery)

**Backend parity**:
The property that `Cache.Type: config-server` and `Cache.Type: local` behave identically behind data-server's `cache.Client` interface, per the feature's own ADR. Justifies testing only the seam (does the alternate backend actually get exercised) rather than duplicating full behavioral coverage per backend.
_Avoid_: Cache equivalence, backend compatibility

**Explicit suite**:
A numbered Robot suite directory wired as its own step in `single.yml` and selected via `suites_to_run`. Suites `00` through `05` are explicit — each has deployment constraints (local-only vs config-server-backed) that auto-discovery cannot enforce.
_Avoid_: Hardcoded suite, manual suite

**Auto-discovered suite**:
A numbered Robot suite directory picked up by `single.yml`'s `06+` glob without its own workflow step. Used for experimental or follow-on coverage where no separate deploy profile is required.
_Avoid_: Dynamic suite, glob suite

**Pairs-with**:
The PR-body pairing instruction that chooses which integration-tests revision supplies the Robot suites. It does not choose which reusable workflow definition GitHub executes.
_Avoid_: paired workflow, running the feature-branch cicd.yml

## Flagged ambiguities

**Suite placement for northbound redaction**: Resolved — all northbound redaction assertions (blame masking + deviation masking) live in `04-sensitive` alongside the pipeline tests. The `03-deviations` suite is not extended for this feature.

**Admin bypass (`include_sensitive`)**: Deferred — `kubectl-sdc` does not expose `--include-sensitive` yet. A placeholder test case tagged `TODO` is added to `04-sensitive` pointing at the missing CLI flag.

**How sensitive_paths reach data-server**: Resolved — fully automatic. The Resolver's `substituteBlobs` walks each Config blob, records the keyless XPath of every leaf whose value came from a `secretRef` substitution, and writes those paths into `SensitiveConfig.Spec.SensitivePaths`. TargetConfig passes them through to `TransactionSet.sensitive_paths`. No explicit field on the Config CR is needed.

## Example dialogue

> **Dev**: Where do the new sensitive tests go?
> **Expert**: Sensitive config pipeline gets its own `04-sensitive` suite. Northbound redaction belongs in `03-deviations` because it shows up when we read deviations and merged intent views.
> **Dev**: Can we just extend intent4-srl in CRUD?
> **Expert**: No — that's a broad lifecycle matrix. Sensitive features need dedicated fixtures so failures are diagnosable.
