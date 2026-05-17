test_that("make_irods_base_path handles supported roles and errors", {
  local_restore_rirods_fields(c("user", "user_role"))
  .rirods$user <- "alice"

  testthat::with_mocked_bindings({
    .rirods$user_role <- "groupadmin"
    expect_identical(make_irods_base_path(), "/tempZone/home")

    .rirods$user_role <- "rodsadmin"
    expect_identical(make_irods_base_path(), "/tempZone")

    .rirods$user_role <- "unknown"
    expect_error(make_irods_base_path(), "User role unknown")
  },
  check_irods_conf = function() NULL,
  find_irods_file = function(what) if (what == "irods_zone") "tempZone" else NULL,
  .package = "rirods"
  )

  .rirods$user_role <- "rodsuser"
  testthat::with_mocked_bindings({
    expect_error(make_irods_base_path(), "iRODS zone unknown")
  },
  check_irods_conf = function() NULL,
  find_irods_file = function(what) NULL,
  .package = "rirods"
  )
})

test_that("path helpers stop on overwrite and missing connections", {
  testthat::with_mocked_bindings({
    expect_error(stop_irods_overwrite(FALSE, "/tempZone/home/alice/x"), "already exists")
  },
  lpath_exists = function(...) TRUE,
  .package = "rirods"
  )

  testthat::with_mocked_bindings({
    expect_error(lpath_exists("/tempZone/home/alice/x"), "Not connected to iRODS")
  },
  is_connected_irods = function(...) FALSE,
  .package = "rirods"
  )
})

test_that("icd resolves paths locally before collection checks", {
  local_restore_rirods_fields("current_dir")
  .rirods$current_dir <- "/"

  testthat::with_mocked_bindings({
    expect_error(icd("."), "Not connected to iRODS")
  },
  is_connected_irods = function(...) FALSE,
  .package = "rirods"
  )

  testthat::with_mocked_bindings({
    expect_invisible(icd(".."))
    expect_identical(ipwd(), "/")
  },
  is_connected_irods = function(...) TRUE,
  .package = "rirods"
  )

  .rirods$current_dir <- "/tempZone/home/alice"
  testthat::with_mocked_bindings({
    expect_error(icd("missing"), "not a directory")
  },
  is_connected_irods = function(...) TRUE,
  is_collection = function(...) FALSE,
  .package = "rirods"
  )
})

test_that("irm errors for unknown logical paths", {
  testthat::with_mocked_bindings({
    expect_error(irm("missing"), "does not resolve")
  },
  get_absolute_lpath = function(lpath, ...) lpath,
  is_collection = function(...) FALSE,
  is_object = function(...) FALSE,
  .package = "rirods"
  )
})

test_that("resolve_icd_path and ils helpers cover remaining offline branches", {
  expect_identical(resolve_icd_path("..", "/tempZone/home/alice"), "/tempZone/home")
  expect_identical(resolve_icd_path("./child", "/tempZone/home/alice"), "/tempZone/home/alice/child")
  expect_identical(resolve_icd_path("../child", "/tempZone/home/alice"), "/tempZone/home/child")

  req <- httr2::request("https://example.test/list")
  entries <- c("/tempZone/home/alice/a", "/tempZone/home/alice/b")

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      expect_warning(out <- ils(offset = 1), "deprecated")
    },
    req_perform = function(req, ...) structure(list(), class = "httr2_response"),
    resp_body_json = function(resp, check_type = FALSE, simplifyVector = TRUE) list(entries = entries),
    .package = "httr2"
    )
  },
  irods_http_call = function(...) req,
  new_irods_df = function(x) x,
  .package = "rirods"
  )

  expect_equal(out$logical_path, entries)

  collection_meta <- data.frame(
    COLL_NAME = "/tempZone/home/alice",
    META_COLL_ATTR_NAME = "attr",
    META_COLL_ATTR_VALUE = "value",
    META_COLL_ATTR_UNITS = "units"
  )

  testthat::with_mocked_bindings({
    meta <- make_ils_metadata("/tempZone/home/alice")
    expect_equal(
      meta,
      data.frame(
        logical_path = "/tempZone/home/alice",
        attribute = "attr",
        value = "value",
        units = "units"
      )
    )
  },
  iquery = function(query, ...) {
    if (grepl("META_COLL", query)) collection_meta else list()
  },
  .package = "rirods"
  )
})
