% Manual package overview until roxygen is regenerated.
\name{rirods}
\alias{rirods}
\alias{rirods-package}
\docType{package}
\title{rirods: R Client for iRODS}
\description{
\pkg{rirods} provides an R interface to the iRODS HTTP API. It is designed
around a session-oriented workflow that will feel familiar to iRODS users and
reasonably direct to R users working with remote files, collections, and metadata.
}
\details{
The typical workflow is:

\enumerate{
\item Save the HTTP API endpoint with \code{\link{create_irods}}.
\item Authenticate with \code{\link{iauth}}.
\item Navigate the iRODS namespace with \code{\link{ipwd}} and \code{\link{icd}}.
\item List collections and data objects with \code{\link{ils}}.
\item Transfer files with \code{\link{iput}} and \code{\link{iget}}.
\item Save and read R objects with \code{\link{isaveRDS}} and \code{\link{ireadRDS}}.
\item Create collections with \code{\link{imkdir}} and remove items with \code{\link{irm}}.
\item Work with metadata using \code{\link{imeta}} and \code{\link{iquery}}.
}
}
\section{Session model}{
\pkg{rirods} keeps iRODS session state in the current R session. In practice,
this means:

\itemize{
\item \code{\link{create_irods}} stores server configuration on disk for later sessions.
\item \code{\link{iauth}} authenticates and stores the current token in the package session.
\item \code{\link{icd}} changes the current iRODS working collection used by functions like
\code{\link{ipwd}} and \code{\link{ils}}.
}

This is separate from the local file system. For example, \code{\link{icd}} does not
change the result of \code{\link{getwd}}.
}

\section{Main function groups}{
\itemize{
\item Connection and authentication: \code{\link{create_irods}}, \code{\link{iauth}},
\code{\link{is_connected_irods}}.
\item Navigation and listing: \code{\link{ipwd}}, \code{\link{icd}}, \code{\link{ils}}.
\item Collections and data objects: \code{\link{imkdir}}, \code{\link{irm}},
\code{\link{iput}}, \code{\link{iget}}.
\item R objects: \code{\link{isaveRDS}}, \code{\link{ireadRDS}}.
\item Metadata and discovery: \code{\link{imeta}}, \code{\link{iquery}}.
\item Local demo environment: \code{\link{use_irods_demo}}, \code{\link{stop_irods_demo}},
\code{\link{is_irods_demo_running}}.
}
}

\section{Where to start}{
Start with \file{README.md} for installation and a short example. For more detail,
see the package vignettes for demo setup, metadata workflows, and the mapping
between \pkg{rirods} functions and iCommands.
}
\keyword{package}
