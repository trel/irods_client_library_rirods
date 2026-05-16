# Rirods Test Harness Refactor Plan

## Goal

Refactor the test harness into a clearer, more reliable structure for an R package with three explicit test modes:

1. `unit`
2. `recorded-http`
3. `live-http`

The current suite has reasonable breadth, but the harness is too stateful and implicit. The main issues are:

- large global setup in `tests/testthat/setup.R`
- shared mutable state across files and tests
- order-dependent integration flows
- test helpers shipped in package code via `R/dev-helpers.R`
- recorded fixtures mixed into `tests/testthat/`
- CI mixing package checks, fixture recording, and live integration behavior

The target design is a thinner global bootstrap, self-contained tests, test-only helpers under `tests/testthat/`, isolated live integration tests, and CI separated by test type.

## Design Principles

- Each `test_that()` should own its own setup and cleanup.
- Unit tests must not require network or package-global session state.
- Recorded HTTP tests must be deterministic and self-contained.
- Live tests must run only when explicitly enabled.
- Test-only helpers must not live in shipped package code.
- Fixture refresh must be intentional and reviewable.

## Target Layout

```text
tests/
  testthat.R
  testthat/
    helper-env.R
    helper-fixtures.R
    helper-live.R
    helper-http.R

    test-unit-config.R
    test-unit-paths.R
    test-unit-utils.R
    test-unit-s3.R

    test-http-authentication.R
    test-http-collections.R
    test-http-data-objects.R
    test-http-metadata.R
    test-http-navigation.R

    test-live-authentication.R
    test-live-collections.R
    test-live-data-objects.R
    test-live-metadata.R
    test-live-demo.R

  fixtures/
    httptest2/
      authentication/
      collections/
      data-objects/
      metadata/
      navigation/
```

## Work Breakdown

Each section below is designed as a well-scoped piece of work that an individual agent can handle.

### Piece 1: Audit And Classify Existing Tests

**Objective**

Create a source-of-truth mapping from current tests to target test modes.

**Scope**

- review every `tests/testthat/test-*.R` file
- classify each test block as `unit`, `recorded-http`, or `live-http`
- identify tests that are currently order-dependent
- identify tests that rely on shared globals from `setup.R`
- identify tests that cannot be reliably recorded and should stay live

**Relevant Files**

- `tests/testthat/test-*.R`
- `tests/testthat/setup.R`

**Deliverables**

- a mapping table of current file/test names to target file names
- a list of tests that must be rewritten to become self-contained
- a list of live-only behaviors, especially streaming and Docker-dependent paths

**Completion Criteria**

- every existing test file is classified
- there is no ambiguous ownership of any existing test block

**Dependencies**

- none

### Piece 2: Extract Test-Only Helpers Out Of Package Code

**Objective**

Move test helper functions from shipped package code into test-only helper files.

**Scope**

- move helpers from `R/dev-helpers.R` into `tests/testthat/helper-*.R`
- update tests to use the new helper locations
- remove or retire `R/dev-helpers.R` if nothing production-facing remains
- update `DESCRIPTION` so `testthat` is not in `Imports` solely for test helpers

**Relevant Files**

- `R/dev-helpers.R`
- `DESCRIPTION`
- `tests/testthat/test-*.R`

**Deliverables**

- new helper files under `tests/testthat/`
- package code no longer exports or ships test helper behavior
- dependency placement reviewed for `testthat`

**Completion Criteria**

- no production file in `R/` exists only to support tests
- tests still have equivalent helper coverage from `tests/testthat/helper-*.R`

**Dependencies**

- Piece 1 recommended first

### Piece 3: Replace Global Setup With Small Local Helpers

**Objective**

Break `tests/testthat/setup.R` into narrow helper functions with explicit responsibilities.

**Scope**

- replace the current monolithic setup logic with focused helpers such as:
  - `local_test_config()`
  - `local_test_session()`
  - `local_test_file()`
  - `skip_if_no_live_irods()`
  - `local_live_auth()`
  - `new_test_collection()`
  - `with_http_fixture()`
- minimize or eliminate implicit globals such as `irods_test_path`, `irods_test_path_x`, `def_path`, and `dfr`
- stop using fake connected state via `.rirods$token <- "secret"` as general test bootstrap

**Relevant Files**

- `tests/testthat/setup.R`
- `tests/testthat/helper-*.R`
- `R/authentication.R`
- `R/zzz.R`

**Deliverables**

- small helper files under `tests/testthat/`
- reduced or removed logic in `tests/testthat/setup.R`
- explicit helper-based setup inside tests

**Completion Criteria**

- package-wide hidden initialization is minimized
- tests can opt into exactly the state they need
- offline and live behavior are clearly separated

**Dependencies**

- Piece 2

### Piece 4: Rebuild Unit Tests As Pure Local Tests

**Objective**

Isolate pure-R behavior into fast tests that do not touch network or live session state.

**Scope**

- migrate pure logic from current files into `test-unit-*.R`
- prioritize:
  - config helpers
  - path helpers that do not require server state
  - utility functions
  - S3 construction/coercion behavior
- remove unnecessary dependence on `setup.R` globals

**Likely Inputs**

- `tests/testthat/test-create-irods.R`
- `tests/testthat/test-irods-utils.R`
- `tests/testthat/test-irods-s3.R`
- pure parts of `tests/testthat/test-irods-conf.R`
- pure parts of `tests/testthat/test-irods-path.R`

**Deliverables**

- `test-unit-config.R`
- `test-unit-paths.R`
- `test-unit-utils.R`
- `test-unit-s3.R`

**Completion Criteria**

- unit tests pass with no live iRODS server
- unit tests do not depend on recorded HTTP fixtures

**Dependencies**

- Piece 3

### Piece 5: Rebuild Recorded HTTP Tests As Self-Contained Scenarios

**Objective**

Keep HTTP-level coverage, but remove cross-test coupling and make each cassette usable in isolation.

**Scope**

- rewrite recorded HTTP tests to create and clean up their own remote state within the test
- move fixtures into `tests/fixtures/httptest2/`
- update `with_mock_dir()` usage to read from the new fixture location
- keep redaction behavior stable and deterministic
- remove reliance on earlier tests having created collections, objects, or metadata

**Likely Inputs**

- `tests/testthat/test-irods-http.R`
- `tests/testthat/test-authentication.R`
- `tests/testthat/test-collections.R`
- `tests/testthat/test-navigation.R`
- `tests/testthat/test-metadata.R`
- `tests/testthat/test-data-objects.R`
- `inst/httptest2/redact.R`

**Deliverables**

- `test-http-authentication.R`
- `test-http-collections.R`
- `test-http-data-objects.R`
- `test-http-metadata.R`
- `test-http-navigation.R`
- relocated fixtures under `tests/fixtures/httptest2/`

**Completion Criteria**

- recorded HTTP tests no longer depend on file execution order
- fixture directories are not mixed with test source files
- fixture redaction still removes secrets and unstable values

**Dependencies**

- Piece 3

### Piece 6: Isolate Live Integration Tests

**Objective**

Make live server tests explicit, opt-in, and separate from recorded tests.

**Scope**

- move live-only behaviors into `test-live-*.R`
- gate them on an explicit environment variable such as `RIRODS_LIVE=true`
- keep streaming, chunking, Docker state, and demo lifecycle checks here
- ensure each live test gets its own unique collection prefix and cleanup

**Likely Inputs**

- live-only parts of `tests/testthat/test-data-objects.R`
- live-only parts of `tests/testthat/test-irods-http.R`
- live-only parts of `tests/testthat/test-metadata.R`
- `tests/testthat/test-irods-demo.R`

**Deliverables**

- `test-live-authentication.R`
- `test-live-collections.R`
- `test-live-data-objects.R`
- `test-live-metadata.R`
- `test-live-demo.R`

**Completion Criteria**

- no live integration behavior runs accidentally during ordinary package checks
- live tests are independently understandable and runnable

**Dependencies**

- Piece 3
- Piece 5 recommended first for clean separation

### Piece 7: Reduce Reliance On Package-Global Session State

**Objective**

Create cleaner test seams around `.rirods` so tests do not depend on ambient mutable package state.

**Scope**

- evaluate where `.rirods` is read and written in package code
- add a targeted test helper for fully initializing and resetting session state per test if a full refactor is too large
- optionally introduce a lightweight session abstraction internally while keeping existing public APIs stable

**Relevant Files**

- `R/zzz.R`
- `R/authentication.R`
- `R/navigation.R`
- `R/irods-http.R`
- `R/irods-path.R`

**Deliverables**

- documented session-state strategy for tests
- either improved local session helpers or an internal session object plan

**Completion Criteria**

- tests do not need hidden ambient state to determine correctness
- session setup and teardown are explicit and isolated

**Dependencies**

- Piece 1
- can proceed in parallel with Pieces 4 to 6 if scoped carefully

### Piece 8: Restructure CI By Test Mode

**Objective**

Split CI so package checks, live integration, and fixture refresh each have a clear responsibility.

**Scope**

- keep ordinary `R CMD check` running unit plus recorded-http tests
- create a Linux-only live integration workflow for Docker-backed tests
- replace scheduled auto-commit fixture updates with either:
  - manual fixture refresh, or
  - explicitly triggered refresh on demand
- ensure coverage jobs run the intended subset of tests

**Relevant Files**

- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/test-coverage.yaml`
- `.github/workflows/http-snapshots.yaml`

**Deliverables**

- updated CI workflows by test mode
- documented policy for fixture refresh

**Completion Criteria**

- ordinary PR checks do not require Docker or live iRODS
- live integration has a dedicated job
- fixture refresh is intentional and reviewable, not silent background churn

**Dependencies**

- Piece 5
- Piece 6

### Piece 9: Verify Dependency Boundaries And Test Ergonomics

**Objective**

Make sure package dependencies, test ergonomics, and developer workflow match the refactored harness.

**Scope**

- confirm `testthat` belongs in `Suggests`
- confirm `httptest2` remains in `Suggests`
- consider whether `webfakes` is useful for contract-style tests
- verify `.covrignore` still matches intended exclusions
- document how developers run each test mode locally

**Relevant Files**

- `DESCRIPTION`
- `.covrignore`
- `README.md` or contributor-facing docs if desired

**Deliverables**

- cleaned dependency declarations
- short developer instructions for running `unit`, `recorded-http`, and `live-http` tests

**Completion Criteria**

- dependency placement matches actual runtime vs test-only use
- local developer workflow is clear

**Dependencies**

- Pieces 4 to 8

## Suggested Execution Order

Recommended sequence:

1. Piece 1: Audit And Classify Existing Tests
2. Piece 2: Extract Test-Only Helpers Out Of Package Code
3. Piece 3: Replace Global Setup With Small Local Helpers
4. Piece 4: Rebuild Unit Tests As Pure Local Tests
5. Piece 5: Rebuild Recorded HTTP Tests As Self-Contained Scenarios
6. Piece 6: Isolate Live Integration Tests
7. Piece 8: Restructure CI By Test Mode
8. Piece 9: Verify Dependency Boundaries And Test Ergonomics
9. Piece 7: Reduce Reliance On Package-Global Session State

Note: Piece 7 can start earlier if the global session design blocks progress, but it may be cheaper to postpone deeper package-internal refactoring until the harness shape is clearer.

## Parallelization Notes

These pieces can be assigned to separate agents with limited overlap:

- Agent A: Piece 1
- Agent B: Piece 2
- Agent C: Piece 3
- Agent D: Piece 4
- Agent E: Piece 5
- Agent F: Piece 6
- Agent G: Piece 8
- Agent H: Piece 9
- Agent I: Piece 7

Best parallel split after the initial audit:

- one agent handles helper extraction and setup simplification
- one agent handles pure unit test migration
- one agent handles recorded HTTP test migration and fixture relocation
- one agent handles live test isolation
- one agent handles CI changes after test-mode boundaries are settled

## Definition Of Done

The refactor is complete when:

- unit tests run without network or live iRODS
- recorded HTTP tests are deterministic and self-contained
- live integration tests run only when explicitly enabled
- no test helper code remains in shipped package sources unless it has real production value
- test fixtures are separated from test source files
- CI jobs reflect the three test modes clearly
- the suite no longer depends on hidden cross-file state or execution order
