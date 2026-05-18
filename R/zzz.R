# iRODS session environment
.rirods <- new.env(parent = parent.env(environment()))

default_irods_host <- function() {
  host <- Sys.getenv("RIRODS_HOST")
  if (nzchar(host)) {
    return(host)
  }

  if (nzchar(Sys.getenv("DEV_KEY_IRODS")) && nzchar(Sys.getenv("DEV_HOST_IRODS"))) {
    return(httr2::secret_decrypt(Sys.getenv("DEV_HOST_IRODS"), "DEV_KEY_IRODS"))
  }

  "http://localhost:9001/irods-http-api/0.2.0"
}

.onLoad <- function(libname, pkgname) {
  ns <- topenv()
  ns$.irods_host <- default_irods_host()
}
