test_that("collections, navigation, listing, print, and limits work", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  expect_invisible(imkdir("nav/sub", create_parent_collections = TRUE))
  test_iput(paste0(irods_test_path, "/nav/item.csv"))
  expect_invisible(imkdir("empty"))

  expect_invisible(icd("nav"))
  expect_identical(ipwd(), paste0(irods_test_path, "/nav"))
  expect_invisible(icd("./sub"))
  expect_identical(ipwd(), paste0(irods_test_path, "/nav/sub"))
  expect_invisible(icd(".."))
  expect_identical(ipwd(), paste0(irods_test_path, "/nav"))
  expect_invisible(icd(".."))
  expect_identical(ipwd(), irods_test_path)

  listed <- ils("nav")
  expect_s3_class(listed, "irods_df")
  expect_true(all(c(
    paste0(irods_test_path, "/nav/sub"),
    paste0(irods_test_path, "/nav/item.csv")
  ) %in% as.data.frame(listed)$logical_path))

  listed_stat <- ils("nav", stat = TRUE)
  expect_s3_class(listed_stat, "irods_df")
  expect_true(all(c("logical_path", "type") %in% colnames(as.data.frame(listed_stat))))

  listed_permissions <- ils("nav", permissions = TRUE)
  expect_s3_class(listed_permissions, "irods_df")
  expect_true(any(grepl("permissions\\.", colnames(as.data.frame(listed_permissions)))))

  printed <- capture.output(print(listed))
  expect_true(any(grepl("iRODS Zone", printed, fixed = TRUE)))
  expect_message(print(ils("empty")), "does not contain any objects or collections")

  limited <- ils("nav", limit = 1L)
  expect_identical(nrow(as.data.frame(limited)), 1L)
  expect_identical(maximum_number_of_rows_catalog(1L), 1L)
  expect_identical(
    maximum_number_of_rows_catalog(100L),
    find_irods_file("max_number_of_rows_per_catalog_query")
  )

  expect_invisible(irm("nav", recursive = TRUE, force = TRUE))
  expect_invisible(irm("empty", recursive = TRUE, force = TRUE))
})

test_that("path helpers resolve relative and absolute live paths", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  old_dir <- ipwd()
  paths_collection <- paste0(irods_test_path, "/paths")
  abs_item <- paste0(paths_collection, "/item.csv")
  withr::defer(icd(old_dir))
  withr::defer(if (lpath_exists(paths_collection)) test_irm(paths_collection, "collections"))

  expect_invisible(imkdir("paths/sub", create_parent_collections = TRUE))
  test_iput(abs_item)

  expect_true(is_collection("paths"))
  expect_true(is_collection("paths/sub"))
  expect_false(is_collection("paths/item.csv"))
  expect_true(is_object("paths/item.csv"))
  expect_false(is_object("paths"))

  expect_true(lpath_exists("paths"))
  expect_true(lpath_exists("paths/sub"))
  expect_true(lpath_exists("paths/item.csv"))
  expect_false(lpath_exists("paths/missing.csv"))

  expect_true(lpath_exists(abs_item))

  expect_invisible(icd("paths"))
  expect_identical(get_absolute_lpath("sub"), paste0(irods_test_path, "/paths/sub"))
  expect_identical(get_absolute_lpath(abs_item), abs_item)
  expect_error(get_absolute_lpath("missing.csv"), "not accessible")

  expect_error(stop_irods_overwrite(FALSE, "item.csv"), "already exists")
  expect_null(stop_irods_overwrite(TRUE, "item.csv"))
})
