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
