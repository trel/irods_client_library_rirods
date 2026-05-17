test_that("maxamimum number of rows query can be changed by user", {
  expect_equal(
    maximum_number_of_rows_catalog(16),
    find_irods_file("max_number_of_rows_per_catalog_query")
  )
  expect_equal(maximum_number_of_rows_catalog(2), 2L)
})

test_that("maxamimum number of rows returned irods_df can be changed by user", {
  ref <- structure(
    list(
      logical_path = paste0(irods_test_path, "/", c("dfr.csv", "new", "new2"))
    ),
    row.names = 1:3,
    class = "data.frame"
  )
  expect_equal(
    nrow(as.data.frame(limit_maximum_number_of_rows_catalog(ref, 2L))),
    2L
  )
  ref <- structure(list(), row.names = 0L, class = "data.frame")
  expect_equal(
    nrow(as.data.frame(limit_maximum_number_of_rows_catalog(ref, 1L))),
    1L
  )
  expect_equal(nrow(limit_maximum_number_of_rows_catalog(data.frame(), 1L)), 0L)
  expect_error(limit_maximum_number_of_rows_catalog(matrix(1), 1L))
})

test_that("imeta validates deprecated and unknown-path branches offline", {
  testthat::with_mocked_bindings({
    expect_warning(
      expect_error(
        imeta(
          "missing",
          entity_type = "data_object",
          operations = list(list(operation = "add", attribute = "a", value = "b"))
        ),
        "Unkown operation"
      ),
      "deprecated"
    )
  },
  get_absolute_lpath = function(lpath, ...) lpath,
  is_collection = function(...) FALSE,
  is_object = function(...) FALSE,
  .package = "rirods"
  )
})

test_that("write stops by local file", {
  expect_error(stop_local_overwrite(FALSE, "dfr.csv"))
  expect_null(stop_local_overwrite(TRUE, "dfr.csv"))
})
