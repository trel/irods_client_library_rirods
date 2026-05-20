test_that("all operation for data objects 200 OK", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")

  endpoint <- "data-objects"
  args <- list(
    op = "write",
    lpath = paste0(irods_test_path, "/foo.csv"),
    offset = 0,
    count = 2000,
    truncate = 1,
    bytes = curl::form_data(serialize(1, connection = NULL), type = "application/octet-stream")
  )
  resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)

  args$offset <- args$count <- args$truncate <- args$bytes <- NULL
  args$op <- "stat"
  args$lpath <- paste0(irods_test_path, "/foo.csv")
  resp <- irods_http_call(endpoint, "GET", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)

  args$`old-lpath` <- args$lpath
  args$lpath <- NULL
  args$op <- "rename"
  args$`new-lpath` <- paste0(irods_test_path, "/bar.csv")
  resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)

  args$op <- "read"
  args$`old-lpath` <- args$`new-lpath` <- NULL
  args$lpath <- paste0(irods_test_path, "/bar.csv")
  args$offset <- 0
  args$count <- 2000
  resp <- irods_http_call(endpoint, "GET", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)

  args$offset <- args$count <- NULL
  args$op <- "parallel_write_init"
  args$`stream-count` <- 3
  resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)

  args$op <- "parallel_write_shutdown"
  args$`stream-count` <- NULL
  args$`parallel-write-handle` <- httr2::resp_body_json(resp)$parallel_write_handle
  resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)

  args$`parallel-write-handle` <- NULL
  args$op <- "modify_metadata"
  args$operations <- jsonlite::toJSON(list(
    list(operation = "add", attribute = "foo", value = "bar", units = "baz")
  ), auto_unbox = TRUE)
  args$lpath <- paste0(irods_test_path, "/bar.csv")
  resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)

  args$operations <- args$`stream-count` <- NULL
  args$op <- "remove"
  args$`parallel-write-handle` <- NULL
  args$`catalog-only` <- 0
  resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
    httr2::req_perform()
  expect_equal(resp$status_code, 200L)
})

test_that("http request helpers expose live error details", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  req <- irods_http_call(
    "data-objects",
    "GET",
    list(op = "definitely_invalid", lpath = paste0(irods_test_path, "/missing.csv")),
    verbose = TRUE,
    error = FALSE
  )
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(cnd) cnd$resp
  )

  expect_gte(resp$status_code, 400L)
  expect_type(irods_errors(resp), "character")
  expect_gt(nchar(paste(irods_errors(resp), collapse = " ")), 0L)
})
