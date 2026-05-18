#' Generate IRODS Configuration File
#'
#' This will create an iRODS configuration file containing information about the
#' iRODS server. Once the file has been created, future sessions
#' connect again with the same iRODS server without further intervention.
#'
#' The configuration file is located in the user-specific configuration
#' directory. This destination is set with R_USER_CONFIG_DIR if set. Otherwise,
#' it follows platform conventions (see also [rappdirs::user_config_dir()]).
#'
#' @param host URL of host.
#' @param zone_path Deprecated
#' @param client_name Optional client name/identifier to send as the HTTP API
#'   `spOption`, useful for attributing operations in audit logs.
#' @param overwrite Overwrite existing iRODS configuration file. Defaults to
#'    `FALSE`.
#'
#' @return Invisibly, the path to the iRODS configuration file.
#' @export
#'
irods_interactive <- function() interactive()

create_irods <- function(
  host,
  zone_path = character(1),
  client_name = NULL,
  overwrite = FALSE
) {

  if (!missing("zone_path"))
    warning("Argument `zone_path` is deprecated")

  path <- path_to_irods_conf()

  # check for existence of iRODS configuration file
  if (irods_interactive() && file.exists(path) && isFALSE(overwrite))
    stop(
      "iRODS configuration file already exists. If you want to overwrite this ",
      "file then set `overwrite` to TRUE.",
      call. = FALSE
    )

  # create file
  file.create(path)
  config <- list(host = host)
  if (!is.null(client_name) && nzchar(client_name)) {
    config$spOption <- client_name
  }

  write(
    jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE),
    file = path
  )

  # path
  invisible(path)
}
