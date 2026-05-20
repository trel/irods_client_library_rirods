#' Run Docker iRODS Demonstration Service
#'
#' Run an iRODS demonstration server with `use_irods_demo()` as a Docker
#' container instance. The function `stop_irods_demo()` stops the containers.
#'
#' These functions are untested on Windows and macOS and require Docker.
#'
#' @param user Character vector for user name (defaults to "rods" admin)
#' @param pass Character vector for password (defaults to "rods" admin password)
#' @param recreate Boolean to indicate whether to recreate (reboot) the iRODS
#'  demo server (defaults to `FALSE`). Recreating will destroy all content on
#'  the current instance.
#' @param verbose Verbosity (defaults to `TRUE`).
#' @references
#'  https://github.com/irods/irods_demo
#'
#' @return Invisible
#' @export
#'
#' @examples
#'
#' if (interactive()) {
#'
#'   # launch docker irods_demo containers (and possibly download images) with
#'   # default credentials
#'   use_irods_demo()
#'
#'   # same but then with "alice" as user and "PASSword" as password
#'   use_irods_demo("alice", "PASSword")
#'
#'   # stop containers
#'   stop_irods_demo()
#' }
#'
use_irods_demo <- function(user = character(), pass = character(),
                           recreate = FALSE, verbose = TRUE) {
  host <- demo_irods_host()

  # is Docker installed
  if (!check_docker()) {
    stop(
      "Docker is required. \n",
      "Install docker to commence. Alternatively, sudo rights \n",
      "are required for Docker: please check: \n",
      "https://docs.docker.com/engine/install/linux-postinstall/",
      call. = FALSE
    )
  }

  # do irods_demo images exist on this machine?
  resp_user <- TRUE
  if (!check_irods_images()) {
    message("\nThe iRODS demo Docker images are not available on this system. \n")
    if (interactive()) {
      resp_user <-
        utils::askYesNo("Would you like it to be pull the iRODS demo Docker images?", default = FALSE)
    }
  }

  # launch irods_demo
  if (isTRUE(resp_user)) {
    start_irods(verbose, recreate)
  } else {
    stop("The iRODS server could not be started!", call. = FALSE)
  }

  if (length(user) != 0 && length(pass) != 0) {
    system2(
      system.file(package = "rirods", "shell_scripts", "iadmin-docker-icommand.sh"),
      Map(shQuote, c(user, pass)),
      stdout = FALSE,
      stderr = FALSE
    )
  } else {
    user <- pass <- "rods"
  }

  # Sometimes it just does not want to start right. This will perform a dry run
  # and restart the process again. This usually does the trick.
  dry_run_irods(
    user,
    pass,
    host,
    paste0("/tempZone/home/", user),
    verbose
  )

  message(
    "\n",
    "Do the following to connect with the iRODS demo server: \n",
    "create_irods(\"", host, "\") \n",
    "iauth(\"", user, "\", \"", pass, "\")"
  )

  invisible(NULL)
}
#' @rdname use_irods_demo
#'
#' @export
stop_irods_demo <- function(verbose = TRUE) {
  system(
    demo_compose_command("down"),
    ignore.stdout = !verbose,
    ignore.stderr = !verbose
  )
  invisible(NULL)
}

#' Predicate for iRODS Demonstration Service State
#'
#' A predicate to check whether you are running iRODS docker demo containers.
#'
#' @param ... Currently not implemented.
#' @return Boolean whether or not connected to iRODS
#' @export
#'
#' @examples
#' is_irods_demo_running()
is_irods_demo_running <- function(...) {
  # first check if Docker exist
  if (!check_docker(FALSE)) {
    return(FALSE)
  }
  # then check if images exist
  if (!check_irods_images()) {
    return(FALSE)
  }
  # check for client-icommand is not required (only needed for demo itself)
  ref <- irods_containers_ref()
  ref <- ref[ref != "irods-demo-irods-client-icommands-1"]
  irods_containers_state <-
    vapply(ref, is_irods_demo_running_, integer(1))

  if (sum(irods_containers_state) == 0) TRUE else FALSE
}

# this seems not work on Windows
is_irods_demo_running_ <- function(x) {
  system2(
    system.file(package = "rirods", "shell_scripts", "docker-containers.sh"),
    shQuote(x),
    stderr = NULL
  )
}

#' Remove Docker images from system
#' @keywords internal
#' @return Invisible
#' @noRd
remove_docker_images <- function() {
  if (is_irods_demo_running()) {
    stop("Docker containers are still running. Stop them with ",
         "`stop_irods_demo()` and proceed", call. = FALSE)
  }
  invisible(Map(
    function(x) {
      system(paste("docker rmi", x), ignore.stderr = TRUE)
    },
    irods_images_ref("id")
  ))
}

start_irods <- function(verbose, recreate = TRUE) {
  args <- c("up", "-d")
  if (isTRUE(recreate)) {
    args <- c(args, "--force-recreate")
  }
  args <- c(args, demo_start_services)

  system(
    demo_compose_command(paste(args, collapse = " ")),
    ignore.stdout = !verbose,
    ignore.stderr = !verbose
  )
}

path_to_demo <- function() system.file("irods_demo", package = "rirods")

path_to_demo_compose <- function() {
  system.file("docker-compose.rirods.yml", package = "rirods")
}

demo_compose_command <- function(args) {
  paste("docker compose -f", shQuote(path_to_demo_compose()), args)
}

demo_irods_host <- function() "http://localhost:9001/irods-http-api/0.6.0"

# perform dry run to see if iRODS can be used
dry_run_irods <- function(user, pass, host, lpath, verbose, user_input = FALSE) {

  irods_server_status <- is_irods_server_operational(user, pass, host, lpath)

  while (!irods_server_status) {
    if (isFALSE(user_input)) {
      message(
        "\nThere seems to be a problem with the iRODS demo ",
        "server. \nThe problem might be solved by rebooting the server. ",
        "\nThis action will destroy all content on the server!\n"
      )
      user_input <- utils::askYesNo("Can I reboot the server?", default = FALSE)
    }
    if (isTRUE(user_input)) {
      if (verbose) message("\nRecreating iRODS demo. This may take a while!\n")
      start_irods(verbose, recreate = TRUE)
    } else{
      stop("The iRODS server could not be started!", call. = FALSE)
    }

    irods_server_status <- is_irods_server_operational(user, pass, host, lpath)
  }
}

is_irods_server_operational <- function(user, pass, host, lpath) {
  Sys.sleep(3) # requires some time to stand up
  is_irods_server_running_correct() &&
    is_http_server_running_correct(user, pass, host, lpath)
}

is_http_server_running_correct <- function(user, pass, host, lpath) {
  system2(
    system.file(package = "rirods", "shell_scripts", "dry-run-irods-curl.sh"),
    Map(shQuote, c(user, pass, host, lpath)),
    stdout = FALSE,
    stderr = FALSE
  ) == 0
}

is_irods_server_running_correct <- function() {
  system2(
    system.file(package = "rirods", "shell_scripts", "dry-run-irods-icommands.sh"),
    stdout = FALSE,
    stderr = FALSE
  ) == 0
}

# look up table for irods_demo images
irods_images_ref <- function(filter_images = "name") {
  if (filter_images == "id") {
    dkr_format <- "{{.ID}}"
  } else if (filter_images == "name") {
    dkr_format <- "{{.Repository}}"
  }
  dkr_args <- c("irods-demo*", "irods/*", dkr_format)
  dkr_args <- Map(shQuote, dkr_args)
  cmd <- system.file(package = "rirods", "shell_scripts", "docker-images.sh")
  # this does not work on all Windows OS
  imgs <- try(system2(cmd, args = dkr_args, stdout = TRUE), silent = TRUE)
  if (inherits(imgs, "try-error")) {
    return(NULL)
  } else {
    return(imgs)
  }
}

# are the images available on this system
check_irods_images <- function() {
  if (length(irods_images_ref()) == 0) {
    check_images_result <- FALSE
  } else {
    check_images_result <-
      all(grepl(paste0(irods_images, collapse = "|"), irods_images_ref()))
  }
  check_images_result
}

# does Docker exist
check_docker <- function(verbose = TRUE) {
  # check if Docker is installed and can be accessed without sudo rights
  docker_version <- system("docker --version", ignore.stdout = !verbose,
                           ignore.stderr = !verbose)
  !(Sys.which("docker") == "" || docker_version == "")
}

irods_containers_ref <- function() {
  paste0("irods-demo-", demo_services, "-1")
}

demo_services <- c(
  "irods-catalog",
  "irods-catalog-provider",
  "irods-client-icommands",
  "irods-client-http-api",
  "minio"
)

demo_start_services <- c(
  "irods-client-http-api",
  "irods-client-icommands"
)

irods_images <- c(
  "irods-demo-irods-catalog",
  "irods-demo-irods-catalog-provider",
  "irods-demo-irods-client-icommands",
  "irods/irods_http_api"
)

#' Launch iRODS from Alternative Directory
#'
#' This function is useful during development as it prevents cluttering of the
#' package source files.
#'
#' @param host Hostname of the iRODS server. Defaults to
#'  [default_irods_host()].
#' @param dir The directory to use. Default is a temporary directory.
#' @param env Attach exit handlers to this environment. Defaults to the
#'  parent frame (accessed through [parent.frame()]).
#'
#' @return Invisibly returns the original directory.
#' @keywords internal
#' @noRd
local_create_irods <- function(
  host = NULL,
  dir = tempdir(),
  env = parent.frame()
) {

  # default host
  if (is.null(host)) {
    host <- default_irods_host()
  }

  # to return to
  old_dir <- getwd()

  # change working directory
  setwd(dir)
  withr::defer(setwd(old_dir), envir = env)

  # switch to new iRODS project
  create_irods(host, overwrite = TRUE)
  withr::defer(unlink(path_to_irods_conf()), envir = env)

  invisible(dir)
}
