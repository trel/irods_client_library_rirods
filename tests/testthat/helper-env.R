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
  list(
    def_path = def_path,
    irods_test_path = paste0(def_path, "/testthat"),
    irods_test_path_x = paste0(def_path, "/projectx")
  )
}

online_test_state <- function(user, pass, host) {
  create_irods(host, overwrite = TRUE)
  withr::defer(unlink(path_to_irods_conf()), teardown_env())

  iauth(user, pass, "rodsuser")

  paths <- test_paths(rirods:::make_irods_base_path())
  if (!lpath_exists(paths$irods_test_path)) test_imkdir(paths$irods_test_path)
  if (!lpath_exists(paths$irods_test_path_x)) test_imkdir(paths$irods_test_path_x)

  withr::defer(test_irm(paths$irods_test_path, "collections"), teardown_env())
  withr::defer(test_irm(paths$irods_test_path_x, "collections"), teardown_env())

  icd("testthat")
  rirods:::get_token(user, pass, rirods:::find_irods_file("host"))

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

  paths <- test_paths(make_irods_base_path())
  .rirods$current_dir <- paths$irods_test_path
  assign("token", "secret", envir = .rirods)

  paths
}

bootstrap_test_state <- function() {
  creds <- test_credentials()

  local_test_config()
  dfr <- local_test_file()

  state <- try(
    online_test_state(creds$user, creds$pass, creds$host),
    silent = TRUE
  )

  if (inherits(state, "try-error")) {
    state <- offline_test_state(creds$user, creds$host)
  } else {
    remove_mock_files()
  }

  c(creds, list(dfr = dfr), state)
}
