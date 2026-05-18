test_credentials <- function() {
  if (Sys.getenv("DEV_KEY_IRODS") != "") {
    list(
      user = secret_decrypt(Sys.getenv("DEV_USER"), "DEV_KEY_IRODS"),
      pass = secret_decrypt(Sys.getenv("DEV_PASS"), "DEV_KEY_IRODS"),
      host = secret_decrypt(Sys.getenv("DEV_HOST_IRODS"), "DEV_KEY_IRODS")
    )
  } else {
    list(
      user = "rods",
      pass = "rods",
      host = rirods:::.irods_host
    )
  }
}

local_test_session <- function() {
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

  withr::defer({
    for (i in seq_along(fields)) {
      field <- fields[[i]]
      if (had_value[[i]]) {
        assign(field, old_value[[i]], envir = .rirods)
      } else if (exists(field, envir = .rirods, inherits = FALSE)) {
        rm(list = field, envir = .rirods)
      }
    }
  }, teardown_env())
}

local_test_config <- function() {
  withr::local_envvar(
    R_USER_CONFIG_DIR = tempdir(),
    .local_envir = teardown_env()
  )
}

local_test_file <- function() {
  dfr <- data.frame(a = c("a", "b", "c"), b = 1:3, c = 6:8)
  readr::write_csv(dfr, "dfr.csv")
  withr::defer(unlink("dfr.csv"), teardown_env())
  dfr
}

test_paths <- function(def_path) {
  test_collection_names <- list(
    test_collection_name = "testthat",
    project_collection_name = "projectx"
  )

  build_test_paths(def_path, test_collection_names)
}

build_test_paths <- function(def_path, collection_names) {
  list(
    def_path = def_path,
    test_collection_name = collection_names$test_collection_name,
    project_collection_name = collection_names$project_collection_name,
    irods_test_path = paste0(def_path, "/", collection_names$test_collection_name),
    irods_test_path_x = paste0(def_path, "/", collection_names$project_collection_name)
  )
}

unique_test_collection_names <- function() {
  run_id <- paste(
    format(Sys.time(), "%Y%m%d%H%M%S"),
    Sys.getpid(),
    sample.int(99999L, 1L),
    sep = "-"
  )

  list(
    test_collection_name = paste0("testthat-", run_id),
    project_collection_name = paste0("projectx-", run_id)
  )
}

online_test_state <- function(user, pass, host) {
  create_irods(host, overwrite = TRUE)
  withr::defer(unlink(path_to_irods_conf()), teardown_env())

  iauth(user, pass, "rodsuser")

  paths <- build_test_paths(rirods:::make_irods_base_path(), unique_test_collection_names())
  if (!lpath_exists(paths$irods_test_path)) test_imkdir(paths$irods_test_path)
  if (!lpath_exists(paths$irods_test_path_x)) test_imkdir(paths$irods_test_path_x)

  withr::defer(test_irm(paths$irods_test_path, "collections"), teardown_env())
  withr::defer(test_irm(paths$irods_test_path_x, "collections"), teardown_env())

  icd(paths$test_collection_name)

  paths
}

offline_test_state <- function(user, host) {
  file.create(path_to_irods_conf())
  write(
    jsonlite::toJSON(list(
      host = host,
      irods_zone = "tempZone",
      max_number_of_parallel_write_streams = 3L,
      max_number_of_rows_per_catalog_query = 15L,
      max_size_of_request_body_in_bytes = 8388608L
    ), auto_unbox = TRUE, pretty = TRUE),
    file = path_to_irods_conf()
  )

  .rirods$user <- user
  .rirods$user_role <- "rodsuser"

  paths <- build_test_paths(make_irods_base_path(), list(
    test_collection_name = "testthat",
    project_collection_name = "projectx"
  ))
  .rirods$current_dir <- paths$irods_test_path
  assign("token", "secret", envir = .rirods)

  paths
}

bootstrap_test_state <- function() {
  creds <- test_credentials()

  local_test_session()
  local_test_config()
  dfr <- local_test_file()

  state <- try(
    online_test_state(creds$user, creds$pass, creds$host),
    silent = TRUE
  )

  if (inherits(state, "try-error")) {
    state <- offline_test_state(creds$user, creds$host)
  } else if (!identical(Sys.getenv("RIRODS_PRESERVE_FIXTURES"), "true")) {
    remove_mock_files()
  }

  c(creds, list(dfr = dfr), state)
}
