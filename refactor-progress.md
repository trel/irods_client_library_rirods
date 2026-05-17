# Refactor Progress

## Status

- Started: test harness refactor from `refactor.md`
- Core harness refactor complete
- Test modes are now split into:
  - `test-unit-*`
  - `test-http-*`
  - `test-live-*`
- Recorded fixtures now live under:
  - `tests/fixtures/httptest2/`
- CI responsibilities are now split across:
  - ordinary package checks and coverage
  - live integration
  - manual fixture refresh

## Work Log

### 2026-05-16

Completed:

- created `refactor.md` with the target harness design and work breakdown
- started an audit of the current test suite against the target modes:
  - `unit`
  - `recorded-http`
  - `live-http`
- made the first low-risk harness move by copying these test-only helpers into `tests/testthat/setup.R`:
  - `remove_mock_files()`
  - `test_iput()`
  - `test_imkdir()`
  - `test_imeta()`
  - `test_irm()`
- qualified internal package calls inside those copied helpers with `rirods:::irods_http_call()` so they work from test code
- installed local tooling needed to execute R tests in this environment:
  - Alpine packages: `R`, `R-dev`, `bash`, `curl-dev`, `openssl-dev`, `libxml2-dev`, `libuv-dev`, `g++`, `gfortran`, `make`, `musl-dev`, `linux-headers`, `git`
  - CRAN packages needed for the existing test suite: `testthat`, `pkgload`, `readr`, `httptest2`, plus dependencies
- ran the existing package tests with project startup disabled to avoid `.Rprofile` side effects:
  - command shape: `pkgload::load_all('.')` followed by `testthat::test_dir('tests/testthat')`
  - result: offline-capable suite passed, with live/server-dependent tests skipped
- split mixed tests so live-only checks now live in dedicated `test-live-*` files
- moved pure local checks into dedicated `test-unit-*` files
- deleted unneeded shipped test helper code in `R/dev-helpers.R`
- moved `testthat` from `Imports` to `Suggests`
- removed the stale `R/dev-helpers.R` entry from `.covrignore`
- reran the refactored suite successfully in offline mode
- moved the remaining bootstrap helpers out of `tests/testthat/setup.R` into `tests/testthat/helper-http.R`
- renamed the remaining recorded/offline feature files to explicit `test-http-*` names
- reran the suite after the helper move and file rename cleanup; the offline-capable tests still pass
- allowed `testthat` to drop the now-unused snapshot file `tests/testthat/_snaps/data-objects.md`
- split CI responsibilities so live integration and fixture refresh now have separate workflows
- changed `.Rprofile` so `dev && make` runs only when explicitly requested via `RIRODS_PREPARE_DEV_DEMO=true`
- verified that the offline-capable suite now runs with only `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`; disabling the whole user profile is no longer required for these test commands
- corrected the manual fixture-refresh workflow so it removes existing recorded HTTP fixtures before replaying only the `test-http-*` suite
- added a `with_http_fixture()` helper and switched the `test-http-*` suite to use it instead of calling `with_mock_dir()` directly
- extracted the remaining `setup.R` bootstrap logic into `tests/testthat/helper-env.R` and reduced `setup.R` to sourcing helpers plus `list2env(bootstrap_test_state(), environment())`
- moved recorded HTTP fixture directories from `tests/testthat/` to `tests/fixtures/httptest2/` and repointed the helper plus refresh workflow to the new fixture tree

Observed during tooling setup:

- the repository `.Rprofile` runs `system("cd dev && make")` on startup
- to avoid that side effect during automated test execution, test commands were run with:
  - `R_PROFILE_USER=/dev/null`
  - `R_ENVIRON_USER=/dev/null`
  - `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`
- after the `.Rprofile` refactor, only `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` is needed in this environment
- `renv::restore()` against the lockfile was not reliable in this container because the locked `digest` version failed to build on this Alpine/R toolchain
- as a practical test-running workaround, current CRAN versions of the required test packages were installed directly

Deferred intentionally:

- deleting `R/dev-helpers.R`
- moving `testthat` from `Imports` to `Suggests`
- changing CI workflows
- moving fixtures out of `tests/testthat/`

Reason for the deferred cleanup:

- the first step should be behavior-preserving
- several tests and `setup.R` itself still depend on the helper behavior
- removing the shipped helper file too early would make it harder to isolate regressions

## Test Classification Draft

This is the current mapping from the existing suite to the target harness shape.

### Unit

- `tests/testthat/test-create-irods.R`
  - target: `tests/testthat/test-unit-config.R`
  - note: very small, likely can merge with other config tests
- `tests/testthat/test-irods-utils.R`
  - target: `tests/testthat/test-unit-utils.R`
  - note: mostly pure logic
- `tests/testthat/test-irods-s3.R`
  - target: `tests/testthat/test-unit-s3.R` for constructor checks
  - note: the `with_mock_dir("coerce-irods_df", ...)` block belongs in recorded-http
- `tests/testthat/test-local-path.R`
  - target: `tests/testthat/test-unit-paths.R`
- `tests/testthat/test-irods-conf.R`
  - target split:
    - pure config checks into `tests/testthat/test-unit-config.R`
    - `with_mock_dir("server-info", ...)` into recorded-http
- `tests/testthat/test-irods-path.R`
  - target split:
    - path normalization and argument validation into `tests/testthat/test-unit-paths.R`
    - object existence helpers into recorded-http

### Recorded HTTP

- `tests/testthat/test-authentication.R`
  - target: `tests/testthat/test-http-authentication.R`
  - note: keep the recorded authentication error path here
  - note: token retrieval against a running server belongs in live-http
- `tests/testthat/test-collections.R`
  - target: `tests/testthat/test-http-collections.R`
  - note: currently order-dependent across blocks
- `tests/testthat/test-navigation.R`
  - target: `tests/testthat/test-http-navigation.R`
  - note: strongly stateful; creates and tears down shared objects inside the file
- `tests/testthat/test-metadata.R`
  - target: `tests/testthat/test-http-metadata.R`
  - note: multiple blocks share collections and object state
- `tests/testthat/test-data-objects.R`
  - target split:
    - request-building and ordinary write/read scenarios into `tests/testthat/test-http-data-objects.R`
    - parallel and streaming-only cases into live-http
- `tests/testthat/test-irods-http.R`
  - target split by endpoint into the `test-http-*` files
- `tests/testthat/test-irods-print.R`
  - target: likely recorded-http because printed output depends on recorded listing/query results
- `tests/testthat/test-irods-s3.R`
  - target split:
    - `coerce irods_df to data.frame` into recorded-http

### Live HTTP

- `tests/testthat/test-irods-demo.R`
  - target: `tests/testthat/test-live-demo.R`
  - note: explicitly Docker and demo lifecycle dependent
- `tests/testthat/test-authentication.R`
  - target split:
    - `token can be retrieved` into `tests/testthat/test-live-authentication.R`
- `tests/testthat/test-data-objects.R`
  - target split:
    - `chunked write request works` into `tests/testthat/test-live-data-objects.R`
    - any read/write streaming behavior that the existing tests already mark as not mockable stays live
- `tests/testthat/test-irods-http.R`
  - target split:
    - `all operation for data objects 200 OK` stays live until fixture instability is solved
- `tests/testthat/test-metadata.R`
  - target split:
    - `metadata query columns are ok` stays live because time-sensitive query results already make it unstable for recording

## Current Harness Risks Confirmed

- `tests/testthat/setup.R` performs too much implicit global setup
- several tests rely on shared mutable globals such as:
  - `irods_test_path`
  - `irods_test_path_x`
  - `def_path`
  - `dfr`
- offline mode currently fakes a connected state by assigning `.rirods$token <- "secret"`
- recorded fixtures are mixed with test source under `tests/testthat/`
- the fixture-refresh workflow currently mixes live execution and mutation of the repository state
- the repository `.Rprofile` has an automation side effect unrelated to test execution and can interfere with reproducible local and CI test commands

## Latest Test Run

Executed successfully:

```text
pkgload::load_all('.')
testthat::test_dir('tests/testthat', reporter = 'summary')
```

Outcome:

- passed test files:
  - `test-admin.R`
  - `test-authentication.R` except the live token check
  - `test-collections.R`
  - `test-create-irods.R`
  - `test-data-objects.R` except live/CRAN-skipped cases
  - `test-irods-conf.R`
  - `test-irods-http.R` except live/CRAN-skipped data object HTTP checks
  - `test-irods-path.R`
  - `test-irods-print.R`
  - `test-irods-s3.R`
  - `test-irods-utils.R`
  - `test-local-path.R`
  - `test-metadata.R` except the live/CRAN-skipped metadata query check
  - `test-navigation.R`
- skipped as expected:
  - live authentication token retrieval
  - chunked write live test
  - live `irods_demo` tests
  - live data-object HTTP test
  - live metadata query column test

## Split Performed

Added dedicated unit files:

- `tests/testthat/test-unit-config.R`
- `tests/testthat/test-unit-utils.R`
- `tests/testthat/test-unit-s3.R`

Added dedicated live files:

- `tests/testthat/test-live-authentication.R`
- `tests/testthat/test-live-data-objects.R`
- `tests/testthat/test-live-demo.R`
- `tests/testthat/test-live-http.R`
- `tests/testthat/test-live-metadata.R`

Added helper file:

- `tests/testthat/helper-live.R`
- `tests/testthat/helper-http.R`

Recorded/offline files now use explicit `test-http-*` names:

- `tests/testthat/test-http-authentication.R`
- `tests/testthat/test-http-collections.R`
- `tests/testthat/test-http-data-objects.R`
- `tests/testthat/test-http-irods-conf.R`
- `tests/testthat/test-http-irods-http.R`
- `tests/testthat/test-http-irods-path.R`
- `tests/testthat/test-http-navigation.R`
- `tests/testthat/test-http-print.R`
- `tests/testthat/test-http-s3.R`
- `tests/testthat/test-http-metadata.R`

`tests/testthat/setup.R` now only bootstraps test state and sources helper code from:

- `tests/testthat/helper-http.R`

Removed obsolete or superseded files:

- `tests/testthat/test-irods-demo.R`
- `tests/testthat/test-create-irods.R`
- `tests/testthat/test-irods-utils.R`
- `tests/testthat/test-local-path.R`
- `tests/testthat/test-admin.R`
- `R/dev-helpers.R`

## Current Test Mode Boundaries

Unit coverage now lives in explicit files and contains:

- configuration and config directory behavior
- connection-state checks that only depend on local harness state
- utility and local-path behavior
- pure `irods_df` constructor checks

Live coverage now lives in explicit files and contains:

- token retrieval against a running server
- chunked/parallel write execution
- Docker-backed `irods_demo` lifecycle checks
- live data-object HTTP operation coverage
- time-sensitive live metadata query checks

Recorded/offline coverage remains in the existing feature files and contains:

- collection operations
- navigation and path helpers that use recorded HTTP fixtures
- print and S3 coercion behavior tied to recorded responses
- recorded HTTP endpoint behavior for collections, info, errors, and admin calls
- recorded metadata and standard data-object flows

The recorded suite now goes through a dedicated helper:

- `tests/testthat/helper-http.R::with_http_fixture()`

That now points at a dedicated fixture tree under:

- `tests/fixtures/httptest2/`

## Remaining Cleanup Candidates

1. optional: add a separate live-aware coverage workflow if live-path coverage becomes important
2. optional: further rewrite the recorded HTTP files so each `test_that()` owns all of its setup and cleanup independently

These are follow-on improvements rather than blockers for the harness redesign.

Update:

- the `dev && make` side effect has been removed from ordinary startup
- the remaining override need is the renv autoloader, not project startup shelling out

## Near-Term Next Steps

1. finish the audit by marking the remaining mixed files at the individual `test_that()` block level
2. update CI workflow boundaries now that the file naming split is in place
3. remove or tame the `.Rprofile` side effect so routine test commands do not need environment overrides
4. decide whether to continue into fixture relocation or stop at the naming and helper cleanup stage

## Fixture Helper Refactor Performed

Updated recorded/offline tests to call:

- `with_http_fixture()`

instead of calling `httptest2::with_mock_dir()` directly in each file.

Result:

- the offline-capable suite still passes unchanged
- fixture orchestration now has a single helper seam in `helper-http.R`
- future fixture relocation can be done in one place instead of editing every
  `test-http-*` file again

## Setup Refactor Performed

Added environment/bootstrap helper:

- `tests/testthat/helper-env.R`

This helper now owns:

- development credential selection
- temporary config-dir setup
- temporary local test file creation
- online session bootstrap
- offline session bootstrap
- shared path derivation for the test collections

`tests/testthat/setup.R` now only:

- loads test helper files
- calls `bootstrap_test_state()`
- injects the returned state with `list2env()`

Validation:

- the offline-capable suite still passes unchanged
- `setup.R` is much smaller and the bootstrap responsibilities are now named
  explicitly in one helper file

## Fixture Relocation Performed

Moved recorded HTTP fixtures to:

- `tests/fixtures/httptest2/`

Follow-on changes:

- `with_http_fixture()` now resolves fixture paths through the dedicated tree
- `remove_mock_files()` now clears only the dedicated fixture tree
- the manual refresh workflow now uploads `tests/fixtures/httptest2/` as its
  artifact

Validation:

- the offline-capable suite still passes against the relocated fixtures

## Startup Refactor Performed

Updated project startup:

- `.Rprofile`

This change:

- keeps the encrypted development environment variables in place
- stops running `system("cd dev && make")` on every startup
- makes that preparation step explicit via `RIRODS_PREPARE_DEV_DEMO=true`

Validation:

- `Rscript -e "cat('startup-ok\\n')"` now starts cleanly without triggering the `dev` make step
- the offline-capable suite passes with only:
  - `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`

Follow-on cleanup applied:

- removed `R_PROFILE_USER` and `R_ENVIRON_USER` overrides from:
  - `.github/workflows/live-integration.yaml`
  - `.github/workflows/http-snapshots.yaml`

## CI Split Performed

Added dedicated live integration workflow:

- `.github/workflows/live-integration.yaml`

This workflow:

- runs on `push`, `pull_request`, and `workflow_dispatch`
- provisions `irods_demo`
- sets `RIRODS_LIVE=true`
- runs only `tests/testthat/test-live-*.R`
- leaves ordinary `R-CMD-check` and coverage workflows unchanged

Updated fixture refresh workflow:

- `.github/workflows/http-snapshots.yaml`

This workflow now:

- is manual only via `workflow_dispatch`
- provisions `irods_demo`
- removes recorded HTTP fixtures before replaying only the `test-http-*` suite with live services available
- uploads refreshed `tests/testthat` contents as an artifact
- no longer commits or pushes fixture updates back to the repository automatically

Intentionally unchanged during this step:

- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/test-coverage.yaml`

Reason:

- the live/offline test split is now enforced by file naming and `RIRODS_LIVE`
- ordinary package checks already run the offline-capable suite by default
- keeping those workflows stable limits CI risk while the harness refactor is still underway

## Latest Test Run After Naming Cleanup

Executed successfully:

```text
pkgload::load_all('.')
testthat::test_dir('tests/testthat', reporter = 'summary')
```

Outcome:

- passed offline files:
  - `test-http-authentication.R`
  - `test-http-collections.R`
  - `test-http-data-objects.R` except the CRAN-skipped snapshot case
  - `test-http-irods-conf.R`
  - `test-http-irods-http.R`
  - `test-http-irods-path.R`
  - `test-http-metadata.R`
  - `test-http-navigation.R`
  - `test-http-print.R`
  - `test-http-s3.R`
  - `test-unit-config.R`
  - `test-unit-s3.R`
  - `test-unit-utils.R`
- skipped as expected:
  - all `test-live-*` files because `RIRODS_LIVE` is not enabled

Side effect from the run:

- `testthat` deleted the unused snapshot file `tests/testthat/_snaps/data-objects.md`

## Final CI Policy

Ordinary CI now declares its intent explicitly:

- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/test-coverage.yaml`

Both workflows now set:

- `RIRODS_LIVE=false`
- `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`

This makes the default package check and coverage paths explicitly offline-only,
while the dedicated live workflow remains the only place where live tests are
enabled by default.
