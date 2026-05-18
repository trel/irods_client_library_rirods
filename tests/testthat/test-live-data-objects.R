test_that("chunked write request works", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  max_number_of_parallel_write_streams <-
    find_irods_file("max_number_of_parallel_write_streams")
  object <- serialize(dfr, NULL)
  object_size <- length(object)
  count <- 200
  ticket <- NULL
  verbose <- FALSE
  lpath <- paste0(irods_test_path, "/dfr.rds")
  chunks <- calc_chunk_size(object_size, count, max_number_of_parallel_write_streams)
  reqs <- chunked_local_to_irods(
    chunks,
    object,
    lpath,
    truncate = 1,
    append = 0,
    ticket,
    verbose
  )
  expect_type(reqs, "list")
  expect_type(reqs[[1]], "list")
  resp <- parallel_perform(reqs[[1]], lpath, truncate = 1, append = 0, ticket, verbose)
  expect_type(resp, "list")
  expect_s3_class(resp[[1]], "httr2_response")
  expect_equal(dfr, ireadRDS("dfr.rds"))
  test_irm(paste0(irods_test_path, "/dfr.rds"))

  count <- 50
  chunks <- calc_chunk_size(object_size, count, max_number_of_parallel_write_streams)
  reqs <- chunked_local_to_irods(
    chunks,
    object,
    lpath,
    truncate = 1,
    append = 0,
    ticket,
    verbose
  )
  resp <- sequential_parallel_perform(reqs, lpath, truncate = 1, append = 0, ticket, verbose)
  expect_type(resp, "list")
  expect_type(resp[[1]], "list")
  expect_s3_class(resp[[1]][[1]], "httr2_response")
  expect_equal(dfr, ireadRDS("dfr.rds"))
  test_irm(paste0(irods_test_path, "/dfr.rds"))
})

test_that("checksum requests and local overwrite protection work", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  local_csv <- tempfile(fileext = ".csv")
  local_copy <- tempfile(fileext = ".csv")
  writeLines("a,b\n1,2", local_csv)
  writeLines("existing", local_copy)

  iput(local_csv, "checksum.csv", overwrite = TRUE)

  checksum <- ichksum("checksum.csv", force = TRUE)
  expect_type(checksum, "character")
  expect_gt(nchar(checksum), 0L)

  expect_error(iget("checksum.csv", local_copy, overwrite = FALSE), "exists")

  unlink(local_csv)
  unlink(local_copy)
  test_irm(paste0(irods_test_path, "/checksum.csv"))
})
