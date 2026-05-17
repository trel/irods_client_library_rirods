test_that("data structure input", {
  expect_error(new_irods_df(matrix(1:10)))
  expect_error(new_irods_df(list(wrong_name = 1:10)))
  expect_message(print(new_irods_df(data.frame())))
})

test_that("irods_df rejects unknown column names", {
  expect_error(new_irods_df(data.frame(not_irods = 1)), "unknown iRODS attributes")
})
