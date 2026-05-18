#!/usr/bin/env Rscript

coverage_summary <- function(cov) {
  tally <- covr::tally_coverage(cov)
  files <- split(tally$value, tally$filename)

  data.frame(
    file = names(files),
    coverage = vapply(
      files,
      function(values) round(sum(values > 0) / length(values) * 100, 2),
      numeric(1)
    ),
    row.names = NULL
  )
}

write_summary <- function(cov, coverage_dir) {
  summary <- coverage_summary(cov)
  summary <- summary[order(summary$file), , drop = FALSE]

  utils::write.csv(
    summary,
    file = file.path(coverage_dir, "by-file.csv"),
    row.names = FALSE
  )

  total <- round(covr::percent_coverage(cov), 2)
  writeLines(
    c(
      sprintf("Total line coverage: %.2f%%", total),
      "",
      "Live tests run:",
      paste(sprintf("- %s", live_test_files()), collapse = "\n"),
      "",
      "Excluded live tests:",
      "- tests/testthat/test-live-demo.R",
      "",
      paste(sprintf("%6.2f%% %s", summary$coverage, summary$file), collapse = "\n")
    ),
    con = file.path(coverage_dir, "summary.txt")
  )

  message(sprintf("Total line coverage: %.2f%%", total))
  for (i in seq_len(nrow(summary))) {
    message(sprintf("%6.2f%% %s", summary$coverage[[i]], summary$file[[i]]))
  }
}

live_test_files <- function() {
  sort(setdiff(
    list.files("tests/testthat", pattern = "^test-live-.*\\.[rR]$", full.names = TRUE),
    "tests/testthat/test-live-demo.R"
  ))
}

live_coverage_code <- function(root) {
  test_root <- file.path(root, "tests", "testthat")
  helper_files <- list.files(test_root, pattern = "^helper.*\\.[rR]$", full.names = FALSE)
  selected_files <- c(
    "setup.R",
    helper_files,
    basename(live_test_files())
  )

  paste(
    c(
      "library(testthat)",
      "library(rirods)",
      sprintf("source_root <- '%s'", test_root),
      "tmp_test_dir <- tempfile('rirods-live-tests-')",
      "dir.create(tmp_test_dir, recursive = TRUE, showWarnings = FALSE)",
      sprintf(
        "files <- c(%s)",
        paste(sprintf("'%s'", selected_files), collapse = ", ")
      ),
      "ok <- file.copy(file.path(source_root, files), tmp_test_dir, overwrite = TRUE)",
      "if (!all(ok)) stop('Failed to stage live test files for coverage.', call. = FALSE)",
      "testthat::with_mocked_bindings({",
      "  testthat::test_dir(",
      "    tmp_test_dir,",
      "    reporter = 'summary',",
      "    package = 'rirods',",
      "    load_package = 'installed'",
      "  )",
      "},",
      "is_irods_demo_running = function(...) TRUE,",
      ".package = 'rirods'",
      ")"
    ),
    collapse = "\n"
  )
}

check_live_env <- function() {
  missing <- c("DEV_KEY_IRODS", "DEV_HOST_IRODS", "DEV_USER", "DEV_PASS")
  missing <- missing[Sys.getenv(missing) == ""]

  if (length(missing) != 0) {
    stop(
      "Missing required live-test environment variables: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
}

main <- function() {
  if (!requireNamespace("covr", quietly = TRUE)) {
    stop(
      "Package 'covr' is required. Install it with install.packages('covr').",
      call. = FALSE
    )
  }

  check_live_env()

  Sys.setenv(
    RIRODS_LIVE = "true",
    RIRODS_PRESERVE_FIXTURES = "true"
  )

  root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  coverage_dir <- file.path(root, "coverage-live")
  install_path <- file.path(coverage_dir, "package")

  dir.create(coverage_dir, recursive = TRUE, showWarnings = FALSE)
  unlink(install_path, recursive = TRUE, force = TRUE)

  cov <- covr::package_coverage(
    path = root,
    type = "none",
    quiet = FALSE,
    clean = FALSE,
    install_path = install_path,
    code = live_coverage_code(root)
  )

  write_summary(cov, coverage_dir)

  if (requireNamespace("xml2", quietly = TRUE)) {
    covr::to_cobertura(cov, file.path(coverage_dir, "cobertura.xml"))
  }
}

main()
