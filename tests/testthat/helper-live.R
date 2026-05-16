skip_if_no_live_irods <- function() {
  testthat::skip_if_not(
    identical(Sys.getenv("RIRODS_LIVE"), "true"),
    "Live iRODS tests are disabled"
  )
}
