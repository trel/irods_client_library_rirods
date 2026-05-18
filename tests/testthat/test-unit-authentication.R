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

test_that("online_test_state uses unique test collections without a second token", {
  local_restore_rirods_fields(c("token", "user", "user_role", "current_dir"))

  token_requests <- 0L
  seen <- new.env(parent = emptyenv())
  seen$created <- character()
  seen$removed <- character()
  seen$changed_dir <- NULL
  collection_names <- list(
    test_collection_name = "testthat-run-123",
    project_collection_name = "projectx-run-123"
  )
  expected_paths <- build_test_paths("/tempZone/home/alice", collection_names)
  helper_env <- environment(online_test_state)
  old_unique_names <- get("unique_test_collection_names", envir = helper_env)
  old_test_imkdir <- get("test_imkdir", envir = helper_env)
  old_test_irm <- get("test_irm", envir = helper_env)

  assign("unique_test_collection_names", function() collection_names, envir = helper_env)
  assign("test_imkdir", function(lpath) {
    seen$created <- c(seen$created, lpath)
    invisible(NULL)
  }, envir = helper_env)
  assign("test_irm", function(lpath, endpoint = "data-objects") {
    seen$removed <- c(seen$removed, lpath)
    invisible(NULL)
  }, envir = helper_env)
  on.exit({
    assign("unique_test_collection_names", old_unique_names, envir = helper_env)
    assign("test_imkdir", old_test_imkdir, envir = helper_env)
    assign("test_irm", old_test_irm, envir = helper_env)
  }, add = TRUE)

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      expect_equal(
        online_test_state("alice", "secret", "https://example.test"),
        expected_paths
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
  lpath_exists = function(...) FALSE,
  icd = function(dir) {
    seen$changed_dir <- dir
    invisible(NULL)
  },
  get_token = function(...) {
    token_requests <<- token_requests + 1L
    "extra-token"
  }
  )

  expect_identical(.rirods$token, "session-token")
  expect_identical(token_requests, 0L)
  expect_equal(seen$created, c(expected_paths$irods_test_path, expected_paths$irods_test_path_x))
  expect_identical(seen$changed_dir, collection_names$test_collection_name)
})
