fixture_root <- function() {
  root <- testthat::test_path("..", "fixtures", "httptest2")
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  root
}

fixture_path <- function(name) {
  file.path(fixture_root(), name)
}

remove_mock_files <- function() {
  dirs <- list.dirs(fixture_root(), recursive = FALSE, full.names = TRUE)
  unlink(dirs, recursive = TRUE)
  invisible(dirs)
}

with_http_fixture <- function(name, code, simplify) {
  path <- fixture_path(name)
  if (missing(simplify)) {
    httptest2::with_mock_dir(path, code)
  } else {
    httptest2::with_mock_dir(path, code, simplify = simplify)
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
