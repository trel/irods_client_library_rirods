test_that("metadata query columns are ok", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  test_iput(paste0(irods_test_path, "/dfr.csv"))

  expect_invisible(imeta(
    "dfr.csv",
    operations = list(list(operation = "add", attribute = "foo", value = "bar", units = "baz"))
  ))

  iq <- iquery(
    paste0(
      "SELECT COLL_NAME, DATA_NAME, DATA_SIZE, COLL_CREATE_TIME WHERE COLL_NAME = '",
      irods_test_path,
      "'"
    )
  )

  expect_equal(
    colnames(iq),
    c("COLL_NAME", "DATA_NAME", "DATA_SIZE", "COLL_CREATE_TIME")
  )
  expect_type(iq$COLL_NAME, "character")
  expect_type(iq$DATA_NAME, "character")
  expect_type(iq$DATA_SIZE, "double")
  expect_s3_class(iq$COLL_CREATE_TIME, "POSIXct")

  metadata_rows <- iquery(data_object_metadata(irods_test_path), limit = 1)
  expect_s3_class(metadata_rows, "data.frame")

  ils_meta <- ils(metadata = TRUE)
  expect_s3_class(ils_meta, "irods_df")
  expect_true(any(ils_meta$attribute == "foo"))
  expect_true(any(ils_meta$value == "bar"))

  test_irm(paste0(irods_test_path, "/dfr.csv"))
})
