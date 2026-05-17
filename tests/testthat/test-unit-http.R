test_that("irods_http_call validates connection and builds verbose requests", {
  local_restore_rirods_fields("token")
  assign("token", "secret", envir = .rirods)

  testthat::with_mocked_bindings({
    expect_error(irods_http_call("collections", "GET", list(), verbose = FALSE), "Not connected")
  },
  is_connected_irods = function(...) FALSE,
  .package = "rirods"
  )

  testthat::with_mocked_bindings({
    req <- irods_http_call(
      endpoint = "collections",
      verb = "GET",
      args = list(op = "list", lpath = "/tempZone/home/alice"),
      verbose = TRUE,
      error = FALSE
    )
    expect_s3_class(req, "httr2_request")
  },
  is_connected_irods = function(...) TRUE,
  find_irods_file = function(what) "https://example.test",
  .package = "rirods"
  )
})

test_that("irods_errors formats server-side error messages", {
  testthat::with_mocked_bindings({
    msg <- irods_errors(list())
    expect_match(msg, "bad request")
    expect_match(msg, "malconfigured")
  },
  resp_status = function(resp) 500L,
  resp_body_json = function(resp, check_type = TRUE) list(error_message = "bad request "),
  .package = "httr2"
  )
})

test_that("irods query helpers handle deprecated arguments and coercions", {
  req <- httr2::request("https://example.test/query")

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      expect_warning(
        out <- iquery(
          "SELECT DATA_SIZE, CREATE_TIME",
          type = "general",
          limit = 1
        ),
        "deprecated"
      )
    },
    req_perform = function(req, ...) structure(list(), class = "httr2_response"),
    resp_body_json = function(resp, check_type = FALSE, simplifyVector = TRUE) {
      list(rows = data.frame(V1 = "12", V2 = "1700000000"))
    },
    .package = "httr2"
    )
  },
  find_irods_file = function(what) {
    switch(
      what,
      max_number_of_rows_per_catalog_query = 15L,
      irods_zone = "tempZone",
      NULL
    )
  },
  irods_http_call = function(...) req,
  .package = "rirods"
  )

  expect_s3_class(out$CREATE_TIME, "POSIXct")
  expect_type(out$DATA_SIZE, "double")
})

test_that("metadata query helpers build expected strings", {
  expect_match(is_data_object_metadata("/tempZone/home/alice", "x.csv"), "DATA_NAME = 'x.csv'")
  expect_match(is_collection_metadata("/tempZone/home/alice"), "COLL_NAME = '/tempZone/home/alice'")
})
