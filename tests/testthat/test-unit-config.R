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

test_that("create_irods protects existing configuration in interactive mode", {
  local_restore_irods_conf()

  write(
    jsonlite::toJSON(list(host = host), auto_unbox = TRUE, pretty = TRUE),
    file = path_to_irods_conf()
  )

  testthat::with_mocked_bindings({
    expect_error(create_irods("https://example.test"), "already exists")
  },
  interactive = function() TRUE,
  .package = "base"
  )
})
