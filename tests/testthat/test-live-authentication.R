test_that("token can be retrieved", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  expect_type(get_token(user, pass, host), "character")
})
