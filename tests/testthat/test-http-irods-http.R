with_mock_dir("collection-http", {
  test_that("all operation for collections 200 OK", {
    endpoint = "collections"
    args <- list(
      op = "create",
      lpath = paste0(irods_test_path, "/new"),
      `create-intermediates` = 0
    )
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$lpath <- paste0(irods_test_path, "/new/new")
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$`create-intermediates` <- NULL
    args$op <- "stat"
    args$lpath <- paste0(irods_test_path, "/new")
    resp <- irods_http_call(endpoint, "GET", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$recurse <- 1
    args$op <- "list"
    args$lpath <- def_path
    resp <- irods_http_call(endpoint, "GET", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$recurse <- NULL
    args$op <- "modify_metadata"
    args$operations <- jsonlite::toJSON(list(
      list(
        operation = "add",
        attribute = "foo",
        value = "bar",
        units = "baz"
      )
    ), auto_unbox = TRUE)
    args$lpath <- paste0(irods_test_path, "/new")
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$operations <- args$lpath <- NULL
    args$op <- "execute_genquery"
    args$query <- collection_metadata(paste0(irods_test_path, "/new"))
    args$offset <- 0
    args$count <- find_irods_file("max_number_of_rows_per_catalog_query")
    args$`case-sensitive` <- 1
    args$distinct <- 1
    args$parser <- "genquery1"
    args$`sql-only` <- 0
    args$zone <- find_irods_file("irods_zone")
    resp <- irods_http_call("query", "GET", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args <- list()
    args$op <- "rename"
    args$`old-lpath` <- paste0(irods_test_path, "/new")
    args$`new-lpath` <- paste0(irods_test_path, "/newer")
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$`old-lpath` <- args$`new-lpath` <- NULL
    args$op <- "remove"
    args$recurse <- 1
    args$lpath <- paste0(irods_test_path, "/newer")
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
  })
},
simplify = FALSE
)

with_mock_dir("info-http", {
  test_that("all information operations 200 OK", {
    endpoint <- "info"
    args <- list()
    resp <- irods_http_call(endpoint, "GET", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
  })
},
simplify = FALSE
)

with_mock_dir("http-erros", {
  test_that("error handling", {
    endpoint = "data-objects"
    args <- list()
    args$op = "remove"
    req <- irods_http_call(endpoint, "POST", args, verbose = FALSE)
    expect_error(httr2::req_perform(req))
    args$lpath <- ipwd()
    args$recurse <- 1
    req <- irods_http_call(endpoint, "POST", args, verbose = FALSE)
    expect_error(httr2::req_perform(req))
  })
},
simplify = FALSE
)

with_mock_dir("admin-http", {
  test_that("admin", {
    endpoint = "users-groups"
    args <- list(
      op = "create_user",
      name = "name",
      zone = find_irods_file("irods_zone"),
      `user-type` = "rodsadmin"
    )
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$op = "set_password"
    args$name = "name"
    args$`new-password` = "pass"
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
    args$op = "remove_user"
    args$name = "name"
    resp <- irods_http_call(endpoint, "POST", args, verbose = FALSE) |>
      httr2::req_perform()
    expect_equal(resp$status_code, 200L)
  })
},
simplify = FALSE
)
