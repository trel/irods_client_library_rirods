# GitHub Issue Prioritization Plan

Repository: `irods/irods_client_library_rirods`

Goal: prioritize open issues by balancing impact against effort, with an explicit priority boost for bug fixes.

## Prioritization Criteria

- Impact: how much the issue affects core user workflows, correctness, or adoption.
- Effort: estimated implementation and validation cost.
- Bug boost: confirmed bugs rank ahead of comparable enhancements.
- Leverage: issues that unblock or overlap with multiple other issues rank higher.

## Recommended Work Order

### 1. `#60` `ils()` function doesn't return correct list

- Status: Complete on current branch.
- Priority: Highest
- Type: Bug
- Impact: High
- Effort: Medium
- Why first: `ils()` is a core command. Returning incomplete results breaks navigation, discovery, and trust in the client.
- Notes: Fixed by removing the unintended default client-side truncation in `ils()` and adding a regression test that verifies all entries are returned unless `limit` is explicitly supplied.

### 2. `#51` Existence of user home is assumed

- Status: Complete on current branch.
- Priority: Highest
- Type: Bug
- Impact: High
- Effort: Medium
- Why next: This blocks valid deployments that do not use per-user home collections. It can make the client unusable in production environments.
- Notes: Fixed by honoring an optional `landing_collection` value from the config file for the initial working collection and by teaching `lpath_exists()` to fall back outside the assumed home path without breaking existing fixture-backed behavior.

### 3. `#62` `ils(metadata=TRUE)` results in errors

- Status: Complete on current branch.
- Priority: Very High
- Type: Bug
- Impact: High
- Effort: Low
- Why next: Clear user-facing failure with a likely contained fix. The issue description already points to the probable root cause and mentions that a fix may already exist.
- Notes: Fixed by normalizing collection and data-object metadata rows in `make_ils_metadata()` and adding a regression test for mixed metadata results.

### 4. `#63` `ils(stat=TRUE)` and `ils(permissions=TRUE)` fail with an error when used on large collections

- Status: Complete on current branch.
- Priority: Very High
- Type: Bug
- Impact: High
- Effort: Medium
- Why next: Breaks important `ils()` options for larger collections. Likely shares implementation surface with the other `ils()` bugs, so it is efficient to tackle alongside them.
- Notes: Fixed by making `get_stat()` robust when one stat lookup returns a `try-error` and by routing `permissions = TRUE` through the stat information path with only the permission-related columns.

### 5. `#55` Hardcoded API URL

- Status: Complete on current branch.
- Priority: High
- Type: Bug
- Impact: Medium-High
- Effort: Low-Medium
- Why next: Test portability and correctness are undermined by hardcoded endpoints. This likely contributes to broader test and environment instability.
- Notes: Fixed by centralizing the default API host lookup, honoring `RIRODS_HOST` and encrypted `DEV_HOST_IRODS` overrides before falling back to the demo URL, and reusing that helper from local test/demo setup.

### 6. `#56` Testing expires the current authentication

- Status: Complete on current branch.
- Priority: High
- Type: Likely bug
- Impact: Medium
- Effort: Medium
- Why next: Painful for contributors and likely connected to the current test configuration model. Important for developer workflow, but slightly less urgent than runtime correctness issues affecting end users.
- Notes: Fixed by removing the redundant second token request from test bootstrap and restoring `.rirods` session fields after tests so running the suite does not leave the interactive session mutated.

## Secondary Priority

### 7. `#59` Changing directory takes a lot time

- Status: Complete on current branch.
- Priority: Medium
- Type: Performance issue
- Impact: Medium
- Effort: Medium-High
- Why later: Important, but performance work is usually less efficient than fixing correctness bugs unless the bottleneck is already obvious and local to this package.
- Notes: Fixed by removing the redundant `lpath_exists()` safety check inside `make_stat()`, so `icd()` now reaches the HTTP `stat` endpoint directly instead of recursively listing collections first. Added a regression test that fails if relative-path stat resolution falls back to the slow existence scan.

### 8. `#54` Add support for OIDC

- Priority: Medium
- Type: Enhancement
- Impact: Very High
- Effort: High
- Why later: Strategically important, but larger in scope than the current bug backlog. Better treated as a dedicated feature effort after core stability issues are addressed.

### 9. `#58` Add client name/identifier - spOption

- Status: Complete on current branch.
- Priority: Medium
- Type: Enhancement
- Impact: Medium
- Effort: Low-Medium
- Why later: Useful operationally for audit/logging, but not blocking core package workflows.
- Notes: Fixed by allowing `create_irods(client_name = ...)` to persist a client identifier as `spOption` in the local config and by automatically forwarding that value on HTTP API requests. Added regression tests covering both config persistence and request query construction.

### 10. `#61` Can `ils()` distinguish between collections and data objects in its output?

- Priority: Medium-Low
- Type: Enhancement
- Impact: Medium
- Effort: Low
- Why later: Good usability improvement, but lower priority than correctness and environment issues.

## Lowest Priority

### 11. `#57` Different configuration file than regular `~/.irods/irods_environment.json`

- Priority: Low
- Type: Question / docs clarification
- Impact: Low-Medium
- Effort: Low
- Why later: This looks more like documentation or explanation work than a product defect.

### 12. `#49` Link to multiple APIs

- Priority: Lowest
- Type: Long-term design discussion
- Impact: Unclear / potentially high
- Effort: High
- Why later: Large scope, unclear near-term user value, and not a pressing correctness issue.

### 13. `#16` new `ichksum` function

- Status: Complete on current branch.
- Priority: Medium-Low
- Type: Enhancement
- Impact: Medium
- Effort: Medium
- Why later: Useful for integrity workflows and now appears implementable via the existing HTTP API `calculate_checksum` support, but it still needs package-level API design around options such as checksum algorithm and should follow the higher-value enhancement backlog.
- Notes: Fixed by adding `ichksum()` as a wrapper over the HTTP API `calculate_checksum` operation for data objects, returning the checksum string from the server and resolving logical paths consistently with other object helpers. Added a regression test for the exported function and updated package documentation.

## Recommended Execution Strategy

### Phase 1: Stabilize `ils()` and path behavior

Target issues:

- `#60`
- `#51`
- `#62`
- `#63`

Reason:

- These are the most user-visible correctness issues.
- Several likely share code paths.
- A single concentrated pass through `ils()` / navigation behavior may resolve multiple issues efficiently.
- Review PR `#52` first because it may already address `#51` and `#60`, and may contain partial context for `#63`.

### Phase 2: Stabilize test and environment behavior

Target issues:

- `#55`
- `#56`

Reason:

- Fixes contributor pain and improves confidence in subsequent changes.
- May remove hidden coupling between local auth state, test setup, and hardcoded endpoints.

### Phase 3: Usability and strategic enhancements

Target issues:

- `#54`
- `#61`

Reason:

- These matter, but are less urgent than correctness failures.
- `#54` should likely be handled as a dedicated feature project with design discussion.

### Phase 4: Documentation and long-range ideas

Target issues:

- `#57`
- `#49`

Reason:

- These are not immediate product blockers.

## Suggested Next Agent Actions

1. Review PR `#52` before starting new work.
2. Treat `#62` as complete on the current branch and avoid duplicating that fix.
3. Treat `#60` as complete on the current branch and avoid duplicating that fix.
4. Treat `#51` as complete on the current branch and avoid duplicating that fix.
5. Treat `#55` and `#56` as complete on the current branch and move to the next remaining issue.
6. Treat `#59` as complete on the current branch and move to the enhancement backlog.
7. Treat `#58` as complete on the current branch and keep `#54` as the next recommended issue.
8. Treat `#16` as complete on the current branch and keep `#54` as the next recommended issue.

## Summary

If choosing only one place to start next, move to `#54` "Add support for OIDC".
The highest-priority `ils()` / navigation bug cluster, the test/auth stabilization issues, and the `icd()` performance issue are complete on the current branch.
