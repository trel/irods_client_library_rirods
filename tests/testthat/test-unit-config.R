test_that("iRODS configuration file generation works", {
  expect_true(has_irods_conf())
})

test_that("is there a connection to iRODS", {
  expect_true(is_connected_irods())
})

test_that("get information about iRODS server", {
  expect_true(has_irods_conf())
  expect_equal(check_irods_conf(), path_to_irods_conf())
  expect_equal(
    path_to_irods_conf(),
    file.path(rappdirs::user_config_dir("rirods"), "conf-irods.json")
  )
  expect_equal(find_irods_file("host"), host)
  expect_equal(find_irods_file("irods_zone"), sub("/", "", dirname(dirname(def_path))))
})

test_that("create iRODS configuration directory works", {
  tmp_dir <- rappdirs::user_config_dir("mock_config_dir")
  if (!dir.exists(tmp_dir)) dir.create(tmp_dir, recursive = TRUE)
  expect_true(dir.exists(tmp_dir))
  unlink(tmp_dir, force = TRUE, recursive = TRUE)
  expect_false(dir.exists(tmp_dir))

  expect_invisible(create_config_dir(tmp_dir))
  expect_true(dir.exists(tmp_dir))
})

test_that("error on finding iRODS server information", {
  tmp <- tempfile()
  file.copy(path_to_irods_conf(), tmp)
  unlink(path_to_irods_conf())
  expect_false(has_irods_conf())
  expect_error(check_irods_conf())
  expect_error(find_irods_file("host"))
  expect_error(find_irods_file("irods_zone"))
  file.copy(tmp, path_to_irods_conf())
})

test_that("create_irods writes configuration and warns on deprecated zone_path", {
  local_restore_irods_conf()
  unlink(path_to_irods_conf())

  expect_warning(
    path <- create_irods("https://example.test", zone_path = "/tempZone", overwrite = TRUE),
    "deprecated"
  )

  expect_identical(path, path_to_irods_conf())
  expect_identical(find_irods_file("host"), "https://example.test")
})

test_that("create_irods stores an optional client identifier", {
  local_restore_irods_conf()
  unlink(path_to_irods_conf())

  path <- create_irods(
    "https://example.test",
    client_name = "rirods-audit",
    overwrite = TRUE
  )

  expect_identical(path, path_to_irods_conf())
  expect_identical(find_irods_file("host"), "https://example.test")
  expect_identical(find_irods_file("spOption"), "rirods-audit")
})

test_that("create_irods protects existing configuration in interactive mode", {
  local_restore_irods_conf()

  write(
    jsonlite::toJSON(list(host = host), auto_unbox = TRUE, pretty = TRUE),
    file = path_to_irods_conf()
  )

  testthat::with_mocked_bindings({
    expect_error(create_irods("https://example.test"), "already exists")
  },
  irods_interactive = function() TRUE,
  .package = "rirods"
  )
})

test_that("default_irods_host honors environment overrides", {
  withr::local_envvar(c(
    RIRODS_HOST = "https://plain.example.test/irods-http-api/0.6.0",
    DEV_KEY_IRODS = "",
    DEV_HOST_IRODS = ""
  ))
  expect_identical(default_irods_host(), "https://plain.example.test/irods-http-api/0.6.0")

  withr::local_envvar(c(
    RIRODS_HOST = "",
    DEV_KEY_IRODS = "key",
    DEV_HOST_IRODS = "ciphertext"
  ))
  testthat::with_mocked_bindings({
    expect_identical(default_irods_host(), "https://decrypted.example.test/irods-http-api/0.6.0")
  },
  secret_decrypt = function(...) "https://decrypted.example.test/irods-http-api/0.6.0",
  .package = "httr2"
  )
})

test_that("local_create_irods uses shared default host when host is missing", {
  chosen_host <- NULL
  deferred <- list()

  testthat::with_mocked_bindings({
    testthat::with_mocked_bindings({
      testthat::with_mocked_bindings({
        expect_identical(
          local_create_irods(host = NULL, dir = "/tmp/rirods-test", env = environment()),
          "/tmp/rirods-test"
        )
      },
      getwd = function() "/src",
      setwd = function(...) NULL,
      unlink = function(...) NULL,
      .package = "base"
      )
    },
    defer = function(expr, envir) deferred[[length(deferred) + 1L]] <<- substitute(expr),
    .package = "withr"
    )
  },
  default_irods_host = function() "https://override.example.test/irods-http-api/0.6.0",
  create_irods = function(host, overwrite = FALSE) {
    chosen_host <<- host
    invisible(path_to_irods_conf())
  },
  path_to_irods_conf = function() "/tmp/rirods-conf.json",
  .package = "rirods"
  )

  expect_identical(chosen_host, "https://override.example.test/irods-http-api/0.6.0")
  expect_gte(length(deferred), 2L)
})

test_that("check_irods_conf errors on corrupted configuration", {
  local_restore_irods_conf()

  write("not-json", file = path_to_irods_conf())

  expect_error(check_irods_conf(), "configuration file is corrupted")
})
