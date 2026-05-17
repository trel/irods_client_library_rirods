local_restore_irods_conf <- function() {
  path <- path_to_irods_conf()
  tmp <- tempfile()
  had_file <- file.exists(path)
  env <- parent.frame()

  if (had_file) {
    file.copy(path, tmp, overwrite = TRUE)
  }

  withr::defer({
    if (had_file) {
      file.copy(tmp, path, overwrite = TRUE)
    } else if (file.exists(path)) {
      unlink(path)
    }
  }, envir = env)

  invisible(path)
}

local_restore_rirods_fields <- function(fields) {
  env <- parent.frame()
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
  }, envir = env)

  invisible(fields)
}
