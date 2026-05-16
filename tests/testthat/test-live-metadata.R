test_that("metadata query columns are ok", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")

  iq <- iquery(
    paste0("SELECT COLL_NAME, DATA_NAME, DATA_SIZE, COLL_CREATE_TIME WHERE COLL_NAME LIKE '", def_path, "/%'")
  )

  expect_equal(
    colnames(iq),
    c("COLL_NAME", "DATA_NAME", "DATA_SIZE", "COLL_CREATE_TIME")
  )
  expect_type(iq$COLL_NAME, "character")
  expect_type(iq$DATA_NAME, "character")
  expect_type(iq$DATA_SIZE, "double")
  expect_s3_class(iq$COLL_CREATE_TIME, "POSIXct")

  iquery(data_object_metadata(irods_test_path), limit = 1)
})
