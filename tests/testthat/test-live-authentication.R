test_that("token can be retrieved", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  expect_type(get_token(user, pass, host), "character")
})

test_that("config round trip refreshes server information", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")

  cfg_path <- path_to_irods_conf()
  old_cfg <- tempfile()
  had_cfg <- file.exists(cfg_path)
  fields <- c("token", "user", "user_role", "current_dir")
  had_value <- vapply(
    fields,
    exists,
    logical(1),
    envir = .rirods,
    inherits = FALSE
  )
  old_value <- mget(
    fields,
    envir = .rirods,
    inherits = FALSE,
    ifnotfound = vector("list", length(fields))
  )

  if (had_cfg) {
    file.copy(cfg_path, old_cfg, overwrite = TRUE)
  }

  withr::defer({
    for (i in seq_along(fields)) {
      field <- fields[[i]]
      if (had_value[[i]]) {
        assign(field, old_value[[i]], envir = .rirods)
      } else if (exists(field, envir = .rirods, inherits = FALSE)) {
        rm(list = field, envir = .rirods)
      }
    }

    if (had_cfg) {
      file.copy(old_cfg, cfg_path, overwrite = TRUE)
    } else if (file.exists(cfg_path)) {
      unlink(cfg_path)
    }
  })

  expect_invisible(create_irods(host, client_name = "rirods-live", overwrite = TRUE))
  expect_identical(find_irods_file("host"), host)
  expect_identical(find_irods_file("spOption"), "rirods-live")

  expect_invisible(iauth(user, pass))

  cfg <- find_irods_file()
  expect_identical(cfg$host, host)
  expect_identical(cfg$spOption, "rirods-live")
  expect_true(nzchar(cfg$irods_zone))
  expect_gte(cfg$max_number_of_parallel_write_streams, 1L)
  expect_gt(cfg$max_number_of_rows_per_catalog_query, 0L)
  expect_gt(cfg$max_size_of_request_body_in_bytes, 0L)
  expect_identical(ipwd(), initial_irods_dir())
})
