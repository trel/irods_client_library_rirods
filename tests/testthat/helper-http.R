remove_mock_files <- function() {
  pt <- file.path(getwd(), testthat::test_path())
  fls <- list.files(pt, include.dirs = TRUE)
  mockers <- fls[!grepl(pattern = "((.*)\\..*$)|(^_)", x = fls)]
  unlink(file.path(pt, mockers), recursive = TRUE)
  invisible(file.path(pt, mockers))
}

with_http_fixture <- function(name, code, simplify) {
  if (missing(simplify)) {
    httptest2::with_mock_dir(name, code)
  } else {
    httptest2::with_mock_dir(name, code, simplify = simplify)
  }
}

test_iput <- function(lpath) {
  args <- list(
    op = "write",
    lpath = lpath,
    offset = 0,
    count = 2000,
    truncate = 1,
    bytes = curl::form_data(serialize(1, connection = NULL), type = "application/octet-stream")
  )
  req <- rirods:::irods_http_call("data-objects", "POST", args, verbose = FALSE)
  invisible(httr2::req_perform(req))
}

test_imkdir <- function(lpath) {
  args <- list(
    op = "create",
    lpath = lpath,
    `create-intermediates` = 0
  )
  req <- rirods:::irods_http_call("collections", "POST", args, verbose = FALSE)
  invisible(httr2::req_perform(req))
}

test_imeta <- function(lpath, operations, endpoint = "data-objects") {
  args <- list(
    op = "modify_metadata",
    lpath = lpath
  )
  args$operations <- jsonlite::toJSON(operations, auto_unbox = TRUE)
  req <- rirods:::irods_http_call(endpoint, "POST", args, verbose = FALSE)
  invisible(httr2::req_perform(req))
}

test_irm <- function(lpath, endpoint = "data-objects") {
  args <- list(
    op = "remove",
    recurse = 1,
    lpath = lpath,
    `no-trash` = 1
  )
  if (endpoint == "data-objects") args$`catalog-only` <- 0
  req <- rirods:::irods_http_call(endpoint, "POST", args, verbose = FALSE)
  invisible(httr2::req_perform(req))
}
