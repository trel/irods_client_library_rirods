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

test_that("lpath_exists does not depend on a user home collection", {
  testthat::with_mocked_bindings({
    expect_true(lpath_exists("/tempZone/projects/shared"))
  },
  is_connected_irods = function(...) TRUE,
  make_irods_base_path = function(...) stop("home collection missing", call. = FALSE),
  get_stat_collections = function(lpath, ...) {
    if (identical(lpath, "/tempZone/projects/shared")) {
      data.frame(status_code = 0L, type = "collection")
    } else {
      data.frame(status_code = -170000L)
    }
  },
  get_stat_data_objects = function(...) data.frame(status_code = -171000L),
  .package = "rirods"
  )
})

test_that("lpath_exists falls back to direct object stat when listing fails", {
  local_restore_rirods_fields("current_dir")
  .rirods$current_dir <- "/tempZone/projects/shared"

  testthat::with_mocked_bindings({
    expect_true(lpath_exists("/tempZone/projects/shared/data.csv"))
  },
  is_connected_irods = function(...) TRUE,
  make_irods_base_path = function(...) "/tempZone/home/alice",
  get_stat_collections = function(...) data.frame(status_code = -170000L),
  get_stat_data_objects = function(lpath, ...) {
    if (identical(lpath, "/tempZone/projects/shared/data.csv")) {
      data.frame(status_code = 0L, type = "data_object")
    } else {
      data.frame(status_code = -171000L)
    }
  },
  ils = function(...) stop("listing unavailable", call. = FALSE),
  .package = "rirods"
  )
})

test_that("lpath_exists returns false when listing and stat fallbacks miss", {
  local_restore_rirods_fields("current_dir")
  .rirods$current_dir <- "/tempZone/projects/shared"

  testthat::with_mocked_bindings({
    expect_false(lpath_exists("/tempZone/projects/shared/missing.csv"))
  },
  is_connected_irods = function(...) TRUE,
  make_irods_base_path = function(...) "/tempZone/home/alice",
  get_stat_collections = function(...) data.frame(status_code = -170000L),
  get_stat_data_objects = function(...) data.frame(status_code = -171000L),
  ils = function(...) stop("listing unavailable", call. = FALSE),
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

test_that("ils returns all entries by default and only limits when requested", {
  req <- httr2::request("https://example.test/list")
  entries <- paste0("/tempZone/home/alice/item_", seq_len(17))

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      out_default <- ils()
      out_limited <- ils(limit = 15L)
    },
    req_perform = function(req, ...) structure(list(), class = "httr2_response"),
    resp_body_json = function(resp, check_type = FALSE, simplifyVector = TRUE) list(entries = entries),
    .package = "httr2"
    )
  },
  irods_http_call = function(...) req,
  find_irods_file = function(what) {
    switch(
      what,
      max_number_of_rows_per_catalog_query = 15L,
      NULL
    )
  },
  new_irods_df = function(x) x,
  .package = "rirods"
  )

  expect_equal(out_default$logical_path, entries)
  expect_equal(out_limited$logical_path, entries[seq_len(15)])
})

test_that("make_ils_metadata aligns mixed collection and object metadata rows", {
  collection_meta <- data.frame(
    COLL_NAME = "/tempZone/home/alice/project",
    META_COLL_ATTR_NAME = "project_attr",
    META_COLL_ATTR_VALUE = "project_value",
    META_COLL_ATTR_UNITS = "project_units"
  )

  object_meta <- data.frame(
    COLL_NAME = c("/tempZone/home/alice/project", "/tempZone/home/alice/project"),
    DATA_NAME = c("a.csv", "b.csv"),
    META_DATA_ATTR_NAME = c("object_attr_1", "object_attr_2"),
    META_DATA_ATTR_VALUE = c("object_value_1", "object_value_2"),
    META_DATA_ATTR_UNITS = c("object_units_1", "object_units_2")
  )

  testthat::with_mocked_bindings({
    expect_equal(
      make_ils_metadata("/tempZone/home/alice/project"),
      data.frame(
        logical_path = c(
          "/tempZone/home/alice/project",
          "/tempZone/home/alice/project/a.csv",
          "/tempZone/home/alice/project/b.csv"
        ),
        attribute = c("project_attr", "object_attr_1", "object_attr_2"),
        value = c("project_value", "object_value_1", "object_value_2"),
        units = c("project_units", "object_units_1", "object_units_2")
      )
    )
  },
  iquery = function(query, ...) {
    if (grepl("META_COLL", query)) collection_meta else object_meta
  },
  .package = "rirods"
  )
})
