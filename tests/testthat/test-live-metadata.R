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

test_that("collection and object metadata shapes are handled live", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  collection_path <- paste0(irods_test_path, "/meta-child")
  object_path <- paste0(irods_test_path, "/meta-object.csv")
  collection_ops <- data.frame(
    operation = "add",
    attribute = "scope",
    value = "collection",
    units = "zone"
  )
  object_ops <- list(list(operation = "add", attribute = "scope", value = "object"))

  withr::defer(if (lpath_exists(collection_path)) test_irm(collection_path, "collections"))
  withr::defer(if (lpath_exists(object_path)) test_irm(object_path))

  expect_invisible(imkdir("meta-child", create_parent_collections = TRUE))
  test_iput(object_path)

  expect_invisible(imeta("meta-child", operations = collection_ops))
  collection_only <- ils(metadata = TRUE)
  expect_s3_class(collection_only, "irods_df")
  expect_true(any(collection_only$logical_path == collection_path))
  expect_true(any(collection_only$attribute == "scope" & collection_only$value == "collection"))
  expect_false(any(
    collection_only$logical_path == object_path & collection_only$value == "object",
    na.rm = TRUE
  ))

  expect_invisible(imeta(
    "meta-child",
    operations = list(list(operation = "remove", attribute = "scope", value = "collection", units = "zone"))
  ))
  expect_invisible(imeta("meta-object.csv", operations = object_ops))

  object_only <- ils(metadata = TRUE)
  expect_s3_class(object_only, "irods_df")
  expect_true(any(object_only$logical_path == object_path))
  expect_true(any(object_only$attribute == "scope" & object_only$value == "object"))
  expect_false(any(
    object_only$logical_path == collection_path & object_only$value == "collection",
    na.rm = TRUE
  ))

  expect_invisible(imeta("meta-child", operations = collection_ops))
  mixed <- ils(metadata = TRUE)
  expect_s3_class(mixed, "irods_df")
  expect_true(all(c(collection_path, object_path) %in% mixed$logical_path))
  expect_true(any(mixed$value == "collection"))
  expect_true(any(mixed$value == "object"))

  expect_invisible(imeta(
    "meta-child",
    operations = list(list(operation = "remove", attribute = "scope", value = "collection", units = "zone"))
  ))
  expect_invisible(imeta(
    "meta-object.csv",
    operations = list(list(operation = "remove", attribute = "scope", value = "object"))
  ))

  expect_message(cleared <- ils(metadata = TRUE), "No metadata")
  expect_s3_class(cleared, "irods_df")
  expect_false(any(c("attribute", "value", "units") %in% colnames(as.data.frame(cleared))))
})

test_that("query options cover paging, parser, and case handling live", {
  skip_if_no_live_irods()
  skip_if(!is_irods_demo_running(), "Live iRODS demo is not running.")
  skip_if(.rirods$token == "secret", "IRODS server unavailable")

  object_a <- paste0(irods_test_path, "/query-a.csv")
  object_b <- paste0(irods_test_path, "/query-b.csv")

  withr::defer(if (lpath_exists(object_a)) test_irm(object_a))
  withr::defer(if (lpath_exists(object_b)) test_irm(object_b))

  test_iput(object_a)
  test_iput(object_b)

  expect_invisible(imeta(
    "query-a.csv",
    operations = list(list(operation = "add", attribute = "LiveScope", value = "alpha"))
  ))
  expect_invisible(imeta(
    "query-b.csv",
    operations = list(list(operation = "add", attribute = "livescope", value = "beta"))
  ))

  expect_warning(
    case_insensitive <- iquery(
      paste0(
        "SELECT COLL_NAME, DATA_NAME, META_DATA_ATTR_NAME WHERE COLL_NAME = '",
        irods_test_path,
        "' AND META_DATA_ATTR_NAME = 'livescope'"
      ),
      type = "general",
      case_sensitive = FALSE,
      distinct = FALSE,
      parser = "genquery1"
    ),
    "deprecated"
  )
  expect_s3_class(case_insensitive, "data.frame")
  expect_true(nrow(case_insensitive) >= 1L)
  expect_true("query-b.csv" %in% case_insensitive$DATA_NAME)

  paged <- iquery(
    paste0("SELECT COLL_NAME, DATA_NAME WHERE COLL_NAME = '", irods_test_path, "'"),
    limit = 1,
    offset = 1,
    distinct = FALSE,
    parser = "genquery1"
  )
  expect_s3_class(paged, "data.frame")
  expect_identical(nrow(paged), 1L)
})
