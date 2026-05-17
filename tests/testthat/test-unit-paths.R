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
