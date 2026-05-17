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
      paste(sprintf("%6.2f%% %s", summary$coverage, summary$file), collapse = "\n")
    ),
    con = file.path(coverage_dir, "summary.txt")
  )

  message(sprintf("Total line coverage: %.2f%%", total))
  for (i in seq_len(nrow(summary))) {
    message(sprintf("%6.2f%% %s", summary$coverage[[i]], summary$file[[i]]))
  }
}

main <- function() {
  if (!requireNamespace("covr", quietly = TRUE)) {
    stop(
      "Package 'covr' is required. Install it with install.packages('covr').",
      call. = FALSE
    )
  }

  Sys.setenv(RIRODS_LIVE = Sys.getenv("RIRODS_LIVE", "false"))

  root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  coverage_dir <- file.path(root, "coverage")
  install_path <- file.path(coverage_dir, "package")

  dir.create(coverage_dir, recursive = TRUE, showWarnings = FALSE)
  unlink(install_path, recursive = TRUE, force = TRUE)

  cov <- covr::package_coverage(
    path = root,
    type = "tests",
    quiet = FALSE,
    clean = FALSE,
    install_path = install_path
  )

  write_summary(cov, coverage_dir)

  if (requireNamespace("xml2", quietly = TRUE)) {
    covr::to_cobertura(cov, file.path(coverage_dir, "cobertura.xml"))
  }

  if (identical(Sys.getenv("RIRODS_COVERAGE_UPLOAD"), "true")) {
    covr::codecov(coverage = cov, quiet = FALSE)
  }
}

main()
