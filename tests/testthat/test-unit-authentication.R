test_that("iauth stores session state and enriches config", {
  local_restore_irods_conf()
  local_restore_rirods_fields(c("token", "user", "user_role", "current_dir"))

  write(
    jsonlite::toJSON(list(host = host), auto_unbox = TRUE, pretty = TRUE),
    file = path_to_irods_conf()
  )

  testthat::with_mocked_bindings({
    expect_invisible(iauth("alice", "secret", "rodsadmin"))
  },
  get_token = function(...) "mock-token",
  get_server_info = function(...) {
    list(
      irods_zone = "tempZone",
      max_number_of_rows_per_catalog_query = 15L
    )
  },
  make_irods_base_path = function() "/tempZone",
  .package = "rirods"
  )

  expect_identical(.rirods$user, "alice")
  expect_identical(.rirods$token, "mock-token")
  expect_identical(.rirods$user_role, "rodsadmin")
  expect_identical(.rirods$current_dir, "/tempZone")
  expect_identical(find_irods_file("irods_zone"), "tempZone")
})

test_that("iauth honors configured landing collection and still enriches config", {
  local_restore_irods_conf()
  local_restore_rirods_fields(c("token", "user", "user_role", "current_dir"))

  write(
    jsonlite::toJSON(
      list(
        host = host,
        landing_collection = "/tempZone/projects/shared"
      ),
      auto_unbox = TRUE,
      pretty = TRUE
    ),
    file = path_to_irods_conf()
  )

  testthat::with_mocked_bindings({
    expect_invisible(iauth("alice", "secret", "rodsuser"))
  },
  get_token = function(...) "mock-token",
  get_server_info = function(...) {
    list(
      irods_zone = "tempZone",
      max_number_of_rows_per_catalog_query = 15L
    )
  },
  make_irods_base_path = function() "/tempZone/home/alice",
  .package = "rirods"
  )

  expect_identical(.rirods$current_dir, "/tempZone/projects/shared")
  expect_identical(find_irods_file("irods_zone"), "tempZone")
})

test_that("is_connected_irods is false without a token", {
  local_restore_rirods_fields("token")
  rm(list = "token", envir = .rirods)
  expect_false(is_connected_irods())
})

test_that("online_test_state does not request a second token after iauth", {
  local_restore_rirods_fields(c("token", "user", "user_role", "current_dir"))

  token_requests <- 0L

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      expect_equal(
        online_test_state("alice", "secret", "https://example.test"),
        test_paths("/tempZone/home/alice")
      )
    },
    defer = function(expr, envir) invisible(NULL),
    .package = "withr"
    )
  },
  create_irods = function(...) NULL,
  path_to_irods_conf = function() "/tmp/rirods-conf.json",
  iauth = function(...) {
    .rirods$user <- "alice"
    .rirods$user_role <- "rodsuser"
    .rirods$current_dir <- "/tempZone/home/alice"
    assign("token", "session-token", envir = .rirods)
    invisible(NULL)
  },
  make_irods_base_path = function(...) "/tempZone/home/alice",
  lpath_exists = function(...) TRUE,
  icd = function(...) invisible(NULL),
  get_token = function(...) {
    token_requests <<- token_requests + 1L
    "extra-token"
  }
  )

  expect_identical(.rirods$token, "session-token")
  expect_identical(token_requests, 0L)
})
