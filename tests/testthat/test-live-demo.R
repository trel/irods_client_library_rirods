test_that("irods demo works on linux", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_on_os(c("windows", "mac", "solaris"))

  tmp <- tempfile()
  file.copy(path_to_irods_conf(), tmp)

  skip_if(Sys.getenv("DEV_KEY_IRODS") != "", "Only for demo server.")
  previous_state_irods_demo <- is_irods_demo_running()

  expect_invisible(suppressMessages(use_irods_demo(verbose = FALSE)))
  expect_true(is_irods_demo_running())
  expect_true(is_irods_server_running_correct())
  expect_true(is_http_server_running_correct(user, pass, host, irods_test_path))

  if (isTRUE(previous_state_irods_demo)) {
    stop_irods_demo(verbose = FALSE)
    .rirods$token <- "secret"
  }
  expect_false(is_irods_demo_running())
  expect_false(is_irods_server_running_correct())
  expect_false(is_http_server_running_correct(user, pass, host, irods_test_path))

  system(
    paste0(
      "cd ",
      path_to_demo(),
      "; docker compose up -d irods-client-icommands"
    ),
    ignore.stdout = TRUE,
    ignore.stderr = TRUE
  )
  Sys.sleep(3)
  expect_false(is_irods_demo_running())
  expect_true(is_irods_server_running_correct())
  expect_false(is_http_server_running_correct(user, pass, host, def_path))
  expect_invisible(dry_run_irods(user, pass, host, def_path, FALSE, TRUE))

  Sys.sleep(3)
  file.copy(tmp, path_to_irods_conf())
  iauth(user, pass, "rodsuser")
  if (!lpath_exists(irods_test_path)) test_imkdir(irods_test_path)
  if (!lpath_exists(irods_test_path_x)) test_imkdir(irods_test_path_x)
  icd(test_collection_name)
})

test_that("script to test if iRODS containers are running works", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  expect_equal(is_irods_demo_running_("shouldexitwith1"), 1L)
})

test_that("check for Docker images works", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  expect_type(irods_images_ref(), "character")
  expect_true(check_irods_images())
})
