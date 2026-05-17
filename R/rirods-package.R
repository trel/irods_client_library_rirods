#' rirods: R Client for iRODS
#'
#' `{rirods}` provides an R interface to the iRODS HTTP API. It is designed
#' around a session-oriented workflow that will feel familiar to iRODS users and
#' reasonably direct to R users working with remote files, collections, and
#' metadata.
#'
#' The typical workflow is:
#'
#' 1. Save the HTTP API endpoint with [create_irods()].
#' 2. Authenticate with [iauth()].
#' 3. Navigate the iRODS namespace with [ipwd()] and [icd()].
#' 4. List collections and data objects with [ils()].
#' 5. Transfer files with [iput()] and [iget()].
#' 6. Save and read R objects with [isaveRDS()] and [ireadRDS()].
#' 7. Create collections with [imkdir()] and remove items with [irm()].
#' 8. Work with metadata using [imeta()] and [iquery()].
#'
#' ## Session model
#'
#' `{rirods}` keeps iRODS session state in the current R session. In practice,
#' this means:
#'
#' - [create_irods()] stores server configuration on disk for later sessions.
#' - [iauth()] authenticates and stores the current token in the package session.
#' - [icd()] changes the current iRODS working collection used by functions like
#'   [ipwd()] and [ils()].
#'
#' This is separate from the local file system. For example, [icd()] does not
#' change the result of [getwd()].
#'
#' ## Main function groups
#'
#' - Connection and authentication: [create_irods()], [iauth()],
#'   [is_connected_irods()].
#' - Navigation and listing: [ipwd()], [icd()], [ils()].
#' - Collections and data objects: [imkdir()], [irm()], [iput()], [iget()].
#' - R objects: [isaveRDS()], [ireadRDS()].
#' - Metadata and discovery: [imeta()], [iquery()].
#' - Local demo environment: [use_irods_demo()], [stop_irods_demo()],
#'   [is_irods_demo_running()].
#'
#' ## Where to start
#'
#' Start with `README.md` for installation and a short example. For more detail,
#' see the package vignettes for demo setup, metadata workflows, and the mapping
#' between `{rirods}` functions and iCommands.
#'
#' @name rirods
#' @docType package
#' @keywords package
#' NULL

#' @keywords internal
"_PACKAGE"
