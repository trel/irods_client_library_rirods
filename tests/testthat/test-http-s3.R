with_mock_dir("coerce-irods_df", {
  test_that("coerce irods_df to data.frame", {
    test_iput(paste0(irods_test_path, "/dfr.csv"))
    test_imeta(
      paste0(irods_test_path, "/dfr.csv"),
      operations =
        list(
          list(operation = "add", attribute = "foo", value = "bar", units = "baz")
        ),
      endpoint = "data-objects"
    )

    irods_zone <- ils(metadata = TRUE)
    expect_s3_class(irods_zone, "irods_df")

    ref <- structure(
      list(
        logical_path = paste0(irods_test_path, "/dfr.csv"),
        attribute = "foo",
        value = "bar",
        units = "baz"
      ),
      row.names = 1L,
      class = "data.frame"
    )
    irods_zone <- as.data.frame(irods_zone)
    expect_equal(irods_zone, ref)

    expect_invisible(irm("dfr.csv", force = TRUE))
  })
},
simplify = FALSE
)
