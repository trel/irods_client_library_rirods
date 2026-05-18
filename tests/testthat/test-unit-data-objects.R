test_that("iput validates inputs and dispatches offline write helpers", {
  testthat::with_mocked_bindings({
    expect_error(iput("missing-file.csv", "x"), "does not exist")
  },
  get_absolute_lpath = function(lpath, ...) lpath,
  stop_irods_overwrite = function(...) NULL,
  .package = "rirods"
  )

  path <- tempfile(fileext = ".csv")
  writeLines("a,b\n1,2", path)

  req <- httr2::request("https://example.test/write")
  chunked <- NULL

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      suppressWarnings(expect_invisible(iput(path, "single.csv", offset = 1, count = 1)))
    },
    req_perform = function(req, ...) {
      structure(list(request = req), class = "httr2_response")
    },
    .package = "httr2"
    )
  },
  get_absolute_lpath = function(lpath, ...) paste0("/tempZone/home/alice/", lpath),
  stop_irods_overwrite = function(...) NULL,
  find_irods_file = function(what) {
    if (what == "max_size_of_request_body_in_bytes") 1024L else NULL
  },
  local_to_irods = function(...) req,
  .package = "rirods"
  )

  testthat::with_mocked_bindings({
    expect_invisible(iput(path, "chunked.csv"))
  },
  get_absolute_lpath = function(lpath, ...) paste0("/tempZone/home/alice/", lpath),
  stop_irods_overwrite = function(...) NULL,
  find_irods_file = function(what) {
    if (what == "max_size_of_request_body_in_bytes") 1024L else NULL
  },
  local_to_irods = function(...) list(req, req),
  sequential_parallel_perform = function(reqs, logical_path, ticket, verbose, ...) {
    chunked <<- list(reqs = reqs, logical_path = logical_path, ticket = ticket, verbose = verbose)
    "done"
  },
  .package = "rirods"
  )

  expect_identical(chunked$logical_path, "/tempZone/home/alice/chunked.csv")
  expect_length(chunked$reqs, 2)
})

test_that("isaveRDS validates objects and dispatches offline write helpers", {
  testthat::with_mocked_bindings({
    expect_error(isaveRDS(missing_object, "missing.rds"), "does not exist")
  },
  get_absolute_lpath = function(lpath, ...) lpath,
  stop_irods_overwrite = function(...) NULL,
  .package = "rirods"
  )

  obj <- 1L
  chunked <- NULL

  testthat::with_mocked_bindings({
    suppressWarnings(expect_invisible(isaveRDS(obj, "obj.rds", offset = 1, count = 1)))
  },
  get_absolute_lpath = function(lpath, ...) paste0("/tempZone/home/alice/", lpath),
  stop_irods_overwrite = function(...) NULL,
  find_irods_file = function(what) {
    if (what == "max_size_of_request_body_in_bytes") 1024L else NULL
  },
  local_to_irods = function(...) list(httr2::request("https://example.test/write")),
  sequential_parallel_perform = function(reqs, logical_path, ticket, verbose, ...) {
    chunked <<- list(reqs = reqs, logical_path = logical_path, ticket = ticket, verbose = verbose)
    "done"
  },
  .package = "rirods"
  )

  expect_identical(chunked$logical_path, "/tempZone/home/alice/obj.rds")
  expect_length(chunked$reqs, 1)
})

test_that("sequential_parallel_perform only truncates and appends on the first batch", {
  calls <- list()

  testthat::with_mocked_bindings({
    sequential_parallel_perform(
      reqs = list("first", "second"),
      logical_path = "/tempZone/home/alice/x",
      truncate = 1,
      append = 1,
      ticket = NULL,
      verbose = FALSE
    )
  },
  parallel_perform = function(reqs, logical_path, truncate, append, ticket, verbose) {
    calls[[length(calls) + 1]] <<- list(
      reqs = reqs,
      logical_path = logical_path,
      truncate = truncate,
      append = append,
      ticket = ticket,
      verbose = verbose
    )
    reqs
  },
  .package = "rirods"
  )

  expect_length(calls, 2)
  expect_identical(calls[[1]]$truncate, 1)
  expect_identical(calls[[1]]$append, 1)
  expect_identical(calls[[2]]$truncate, 0)
  expect_identical(calls[[2]]$append, 0)
})

test_that("perform_write_requests chooses the correct execution path", {
  req <- httr2::request("https://example.test/write")
  single <- NULL
  chunked <- NULL

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      single <- perform_write_requests(req, "/tempZone/home/alice/x", NULL, FALSE)
    },
    req_perform = function(req, ...) "single",
    .package = "httr2"
    )
  },
  sequential_parallel_perform = function(...) "chunked",
  .package = "rirods"
  )

  testthat::with_mocked_bindings({
    chunked <- perform_write_requests(list(req), "/tempZone/home/alice/x", NULL, FALSE)
  },
  sequential_parallel_perform = function(...) "chunked",
  .package = "rirods"
  )

  expect_identical(single, "single")
  expect_identical(chunked, "chunked")
})

test_that("parallel_perform adds the parallel write handle to each request", {
  seen_reqs <- NULL
  shutdown_handle <- NULL

  reqs <- list(
    httr2::request("https://example.test/one"),
    httr2::request("https://example.test/two")
  )

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      out <- parallel_perform(
        reqs = reqs,
        logical_path = "/tempZone/home/alice/x",
        truncate = 1,
        append = 0,
        ticket = NULL,
        verbose = FALSE
      )
      expect_identical(out, list("ok"))
    },
    req_body_multipart = function(req, `parallel-write-handle`) {
      req$headers[["parallel-write-handle"]] <- `parallel-write-handle`
      req
    },
    req_perform_parallel = function(reqs, ...) {
      seen_reqs <<- reqs
      list("ok")
    },
    .package = "httr2"
    )
  },
  find_irods_file = function(what) {
    if (what == "max_number_of_parallel_write_streams") 2L else NULL
  },
  parallel_write_init = function(...) "parallel-handle",
  parallel_write_shutdown = function(parallel_write_handle, verbose) {
    shutdown_handle <<- parallel_write_handle
    invisible(NULL)
  },
  .package = "rirods"
  )

  expect_identical(shutdown_handle, "parallel-handle")
  expect_equal(
    vapply(seen_reqs, function(req) req$headers[["parallel-write-handle"]], character(1)),
    c("parallel-handle", "parallel-handle")
  )
})

test_that("iget and ireadRDS work with offline request mocks", {
  local_path <- tempfile(fileext = ".csv")
  writeLines("old", local_path)

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      suppressWarnings(expect_invisible(iget("remote.csv", local_path, overwrite = TRUE, offset = 1, count = 1)))
    },
    req_perform = function(req, path = NULL, ...) {
      writeLines("new", path)
      structure(list(body = path), class = "httr2_response")
    },
    .package = "httr2"
    )
  },
  get_absolute_lpath = function(lpath, ...) paste0("/tempZone/home/alice/", lpath),
  irods_to_local = function(...) httr2::request("https://example.test/read"),
  .package = "rirods"
  )

  expect_identical(readLines(local_path), "new")

  obj <- list(a = 1)
  raw_body <- serialize(obj, NULL)

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      suppressWarnings(result <- ireadRDS("remote.rds", offset = 1, count = 1))
      expect_equal(result, obj)
    },
    req_perform = function(req, ...) {
      structure(list(body = raw_body), class = "httr2_response")
    },
    resp_body_raw = function(resp, ...) resp$body,
    .package = "httr2"
    )
  },
  get_absolute_lpath = function(lpath, ...) paste0("/tempZone/home/alice/", lpath),
  irods_to_local = function(...) httr2::request("https://example.test/read"),
  .package = "rirods"
  )
})

test_that("ichksum resolves the logical path and returns the server checksum", {
  local_restore_rirods_fields("token")
  assign("token", "secret", envir = .rirods)

  testthat::with_mocked_bindings({
    out <- ichksum(
      "remote.csv",
      resource = "demoResc",
      replica_number = 2L,
      force = TRUE,
      verbose = TRUE
    )
    expect_identical(out, "sha2:abcdef")
  },
  req_perform = function(req, ...) structure(list(), class = "httr2_response"),
  resp_body_json = function(resp, ...) list(checksum = "sha2:abcdef"),
  .package = "httr2"
  )
})
