# Better Package Notes

This file is a handoff for the next implementer. The goal is to make `{rirods}` feel like a normal, boring R package that works the way R users expect, while keeping its useful iRODS-specific behavior.

## Primary Goal

Make the package easier to discover, easier to trust, and easier to use without requiring users to infer package conventions from the source tree.

## Highest-Priority Changes

1. Add and maintain a real package overview page.

   Status:
   - A first draft now exists in `R/rirods-package.R` and `man/rirods-package.Rd`.

   Why:
   - Mature R packages usually have a useful `?pkgname` help page.
   - Users should be able to type `?rirods` and immediately see the package purpose, the basic workflow, and where to start.

   Next steps:
   - Review wording for tone and accuracy.
   - Keep the function groups in sync with the exported API.

2. Create one obvious getting-started path.

   Current state:
   - Information is split across `README.md` and several vignettes.
   - There is useful content, but not one obvious "start here" article.

   Recommendation:
   - Keep `README.md` short and focused on install plus first use.
   - Add or rename one vignette/article to serve as the canonical getting-started guide.
   - Move more specialized material into separate articles.

3. Unify package URLs and site branding.

   Current inconsistencies found:
   - `README.md` logo links to `https://dplyr.tidyverse.org`.
   - `DESCRIPTION` points to `https://rirods.irods4r.org`.
   - `_pkgdown.yml` points to `https://irods.github.io/irods_client_library_rirods/`.
   - `_pkgdown.yml` news links point to `https://fairelabs.github.io/iRODS4R/...`.

   Recommendation:
   - Pick one canonical public homepage.
   - Update `DESCRIPTION`, `README`, `_pkgdown.yml`, and any badges or logos to match it.
   - Remove stale or legacy site references.

4. Add standard repository-level contributor docs.

   Missing files:
   - `CONTRIBUTING.md`
   - `CODE_OF_CONDUCT.md`

   Why:
   - Established R packages usually keep contributor guidance at repo root.
   - `vignettes/develop.Rmd` is useful, but it is not where contributors expect contribution policy and workflow guidance.

5. Clarify the stateful session model in docs.

   Current behavior:
   - The package keeps session state in the hidden `.rirods` environment.
   - `create_irods()` writes host config.
   - `iauth()` stores a token and session metadata.
   - `icd()` changes an internal iRODS working directory.

   Why this matters:
   - Many modern R client packages use explicit connection objects.
   - `{rirods}` behaves more like a shell session, which is fine, but it must be explained clearly and early.

   Recommendation:
   - Document the session model in `README`, `?rirods`, and the getting-started article.
   - Explicitly state that `ipwd()` and `icd()` affect the package session, not the local file system.

6. Tighten the repo and build surface.

   Current root includes development or generated material such as:
   - `coverage/`
   - `refactor.md`
   - `refactor-progress.md`
   - `dev/`

   Recommendation:
   - Keep useful internal docs if they help maintainers, but make sure they are excluded from built artifacts.
   - Review `.Rbuildignore` for all non-package files that should stay out of the tarball.
   - Consider whether generated coverage artifacts should live outside the package root or remain fully ignored.

7. Improve example strategy for service-dependent functions.

   Current state:
   - Many exported functions rely on `@examplesIf is_irods_demo_running()`.
   - This is reasonable for a service client, but it means many help pages have no immediately runnable examples for most users.

   Recommendation:
   - Keep guarded examples where needed.
   - Add short non-running examples or representative workflows where that improves readability.
   - Make sure one guide shows the full connect/authenticate/list/upload/download/remove flow in one place.

## Strengths To Preserve

These are distinctive and worth keeping.

1. The iCommands-shaped API is understandable for iRODS users.
2. `use_irods_demo()` is unusually helpful for onboarding and testing.
3. `isaveRDS()` and `ireadRDS()` give the package a more R-native workflow than a thin HTTP wrapper.
4. `ils(metadata = TRUE)` is a useful convenience layer.
5. The test setup is stronger than average for a niche package: unit, recorded HTTP, and live coverage all exist.

## Secondary Cleanup

1. Review the README install and startup path for brevity.
2. Make sure the pkgdown site has a clear landing page and article order.
3. Check whether `NEWS.md` should be committed instead of ignored in `.gitignore`.
4. Review internal/developer material in `vignettes/develop.Rmd` versus root-level contributor docs.
5. Consider whether some documentation should talk more in terms of R workflows and less in terms of underlying infrastructure.

## Definition Of Done

The package should feel conventional if an R user does the following:

1. Opens the GitHub repo.
2. Reads `README.md`.
3. Installs the package.
4. Runs `?rirods`.
5. Opens the getting-started vignette.
6. Tries the first end-to-end workflow.

At that point they should understand:

1. What the package is for.
2. How to connect and authenticate.
3. Which functions are the main entry points.
4. What state the package keeps internally.
5. Where to look next for metadata, demo setup, and developer guidance.
