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

- Priority: Highest
- Type: Bug
- Impact: High
- Effort: Medium
- Why next: This blocks valid deployments that do not use per-user home collections. It can make the client unusable in production environments.
- Notes: Also appears to overlap with PR `#52`.

### 3. `#62` `ils(metadata=TRUE)` results in errors

- Status: Complete on current branch.
- Priority: Very High
- Type: Bug
- Impact: High
- Effort: Low
- Why next: Clear user-facing failure with a likely contained fix. The issue description already points to the probable root cause and mentions that a fix may already exist.
- Notes: Fixed by normalizing collection and data-object metadata rows in `make_ils_metadata()` and adding a regression test for mixed metadata results.

### 4. `#63` `ils(stat=TRUE)` and `ils(permissions=TRUE)` fail with an error when used on large collections

- Priority: Very High
- Type: Bug
- Impact: High
- Effort: Medium
- Why next: Breaks important `ils()` options for larger collections. Likely shares implementation surface with the other `ils()` bugs, so it is efficient to tackle alongside them.

### 5. `#55` Hardcoded API URL

- Priority: High
- Type: Bug
- Impact: Medium-High
- Effort: Low-Medium
- Why next: Test portability and correctness are undermined by hardcoded endpoints. This likely contributes to broader test and environment instability.

### 6. `#56` Testing expires the current authentication

- Priority: High
- Type: Likely bug
- Impact: Medium
- Effort: Medium
- Why next: Painful for contributors and likely connected to the current test configuration model. Important for developer workflow, but slightly less urgent than runtime correctness issues affecting end users.

## Secondary Priority

### 7. `#59` Changing directory takes a lot time

- Priority: Medium
- Type: Performance issue
- Impact: Medium
- Effort: Medium-High
- Why later: Important, but performance work is usually less efficient than fixing correctness bugs unless the bottleneck is already obvious and local to this package.

### 8. `#54` Add support for OIDC

- Priority: Medium
- Type: Enhancement
- Impact: Very High
- Effort: High
- Why later: Strategically important, but larger in scope than the current bug backlog. Better treated as a dedicated feature effort after core stability issues are addressed.

### 9. `#58` Add client name/identifier - spOption

- Priority: Medium
- Type: Enhancement
- Impact: Medium
- Effort: Low-Medium
- Why later: Useful operationally for audit/logging, but not blocking core package workflows.

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

- `#59`
- `#58`
- `#61`
- `#54`

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
4. Determine whether `#51` can be resolved by completing or adapting PR `#52`, and inspect remaining `ils()` failure modes for `#63`.
5. After the remaining `ils()` cluster is stable, move to test/auth issues `#55` and `#56`.

## Summary

If choosing only one place to start next, continue with the remaining `ils()` / navigation bug cluster: `#51` and `#63`.
That is the best combination of high user impact, bug priority, and likely shared implementation effort.
