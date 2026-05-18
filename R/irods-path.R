make_irods_base_path <- function() {
  check_irods_conf()
  if (!is.null(find_irods_file("irods_zone"))) {
    if (.rirods$user_role == "rodsuser") {
      paste0("/", find_irods_file("irods_zone"), "/home/", .rirods$user)
    } else if (.rirods$user_role == "groupadmin") {
      paste0("/", find_irods_file("irods_zone"), "/home")
    } else if (.rirods$user_role == "rodsadmin") {
      paste0("/", find_irods_file("irods_zone"))
    } else {
      stop("User role unknown.", call. = FALSE)
    }

  } else {
    stop("iRODS zone unknown.", call. = FALSE)
  }
}

initial_irods_dir <- function() {
  landing_collection <- find_irods_file("landing_collection")

  if (!is.null(landing_collection)) {
    return(landing_collection)
  }

  make_irods_base_path()
}

get_absolute_lpath <- function(lpath, write = FALSE, safely = TRUE) {

  if (!grepl("^/" , lpath)) {
    # default zone_path writable by user
    zpath <- ipwd()
    # separate lpath in pieces if need
    x <- strsplit(lpath, "/", fixed = TRUE)[[1]]
    # then expand
    lpath <- Reduce(function(x, y) { paste(x, y, sep = "/") }, c(zpath, x))
  }

  if (isTRUE(safely)) {
    if (isTRUE(write)) {
      is_lpath <- lpath_exists(strsplit(ipwd(), lpath)[[1]])
    } else {
      is_lpath <- lpath_exists(lpath)
    }
    if (!is_lpath) {
      stop("Logical path [", lpath,"] is not accessible.", call. = FALSE)
    }
  }

  lpath
}

# stop overwriting
stop_irods_overwrite <- function(overwrite, lpath) {
  is_lpath <- lpath_exists(lpath)
  if (isFALSE(overwrite) && is_lpath) {
    stop(
      "Object [",
      lpath,
      "] already exists.",
      " Set `overwrite = TRUE` to explicitly overwrite the object.",
      call. = FALSE
    )
  }
}

# check if iRODS collection exists
is_collection <- function(lpath) {
  lpath <- get_absolute_lpath(lpath)
  irods_stats <- try(get_stat_collections(lpath), silent = TRUE)
  if (inherits(irods_stats, "try-error") || irods_stats$status_code == -170000L) {
    FALSE
  } else {
    irods_stats$type == "collection"
  }
}

# check if iRODS data object exists
is_object <- function(lpath) {
  lpath <- get_absolute_lpath(lpath)
  irods_stats <- try(get_stat_data_objects(lpath), silent = TRUE)
  if (inherits(irods_stats, "try-error") || irods_stats$status_code == -171000L) {
    FALSE
  } else {
    irods_stats$type == "data_object"
  }
}

# check if iRODS path exists
lpath_exists <- function(lpath, write = FALSE) {
  # check connection
  if (!is_connected_irods()) stop("Not connected to iRODS.", call. = FALSE)

  if (isFALSE(write)) # in case of TRUE `strsplit` ensures absolute path
    lpath <- get_absolute_lpath(lpath, safely = FALSE)

  base_path <- try(make_irods_base_path(), silent = TRUE)
  current_dir <- ipwd()
  use_base_path <- !inherits(base_path, "try-error") && (
    startsWith(current_dir, base_path) ||
      startsWith(base_path, current_dir) ||
      startsWith(lpath, base_path)
  )

  search_root <- if (use_base_path) {
    base_path
  } else {
    current_dir
  }

  all_lpaths <- try(
    ils(search_root, recurse = 1) |>
      as.data.frame() |>
      rbind(search_root),
    silent = TRUE
  )

  if (!inherits(all_lpaths, "try-error")) {
    return(lpath %in% all_lpaths[[1]])
  }

  stat_collection <- try(get_stat_collections(lpath), silent = TRUE)
  if (!inherits(stat_collection, "try-error") && stat_collection$status_code != -170000L) {
    return(TRUE)
  }

  stat_data_object <- try(get_stat_data_objects(lpath), silent = TRUE)
  if (!inherits(stat_data_object, "try-error") && stat_data_object$status_code != -171000L) {
    return(TRUE)
  }

  FALSE
}


get_stat_collections <- function(lpath, verbose = FALSE) {
  make_stat(lpath, "collections", verbose)
}

get_stat_data_objects <- function(lpath, verbose = FALSE) {
  make_stat(lpath, "data-objects", verbose)
}

make_stat <- function(lpath, endpoint, verbose) {
  lpath <- get_absolute_lpath(lpath)
  args <- list(
    op = "stat",
    lpath = lpath
  )
  irods_http_call(endpoint, "GET", args, verbose) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    as.data.frame()
}
