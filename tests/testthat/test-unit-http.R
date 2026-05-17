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
