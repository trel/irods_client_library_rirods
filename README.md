
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rirods <a href="https://dplyr.tidyverse.org"><img src="man/figures/logo.png" align="right" height="138" /></a>

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/irods/irods_client_library_rirods/branch/main/graph/badge.svg)](https://app.codecov.io/gh/irods/irods_client_library_rirods?branch=main)
[![R-CMD-check](https://github.com/irods/irods_client_library_rirods/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/irods/irods_client_library_rirods/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The rirods package is an R client for iRODS over the iRODS HTTP API.

## Installation

You can install the latest CRAN version of rirods like so:

``` r
install.packages("rirods")
```

Or, the development version from GitHub, like so:

``` r
# install.packages("devtools")
devtools::install_github("irods/irods_client_library_rirods")
```

## Prerequisites

This package talks to the iRODS C++ HTTP API:
https://github.com/irods/irods_client_http_api.

You need access to a running iRODS HTTP API endpoint before you can
authenticate or transfer data.

Launch a local demonstration iRODS service (including the HTTP API):

``` r
# load
library(rirods)
# setup a mock iRODS server (https://github.com/irods/irods_demo)
use_irods_demo("alice", "passWORD")
```

This will result in the demonstration HTTP API running at
`http://localhost:9001/irods-http-api/0.6.0`.

`use_irods_demo()` is intended for local exploration and requires
`docker`. It is currently untested on Windows and macOS.

These Docker containers are designed to easily stand up a
**DEMONSTRATION** of the iRODS server. It is intended for education and
exploration. (See also `vignette("demo")`.)

**DO NOT USE IN PRODUCTION**

## Example Usage

To connect to the HTTP API endpoint of your choice, load `rirods`,
connect with `create_irods()`, and authenticate with your iRODS
credentials:

    create_irods("http://localhost:9001/irods-http-api/0.6.0")

`create_irods()` stores the endpoint in your user configuration
directory so future R sessions can reuse it. If you want the HTTP API to
receive a client identifier in audit logs, you can also set
`client_name = "..."`.

After that, `iauth()` authenticates the current R session and `ipwd()` /
`icd()` manage the current iRODS collection. This is separate from your
local working directory returned by `getwd()`.

### Authentication

In this example Alice is a user of iRODS and she can authenticate
herself with `iauth("alice")`. This prompts a dialog where you can enter
your password without hardcoding this information in your scripts.

``` r
# login as alice with password "passWORD"
iauth("alice") # or iauth("alice", "passWORD")
```

### Save R objects

Suppose Alice would like to upload an R object from her current R
session to an iRODS collection. For this, use the `isaveRDS()` command:

``` r
# some data
foo <- data.frame(x = c(1, 8, 9), y = c("x", "y", "z"))

# check where we are in the iRODS namespace
ipwd()

# store data in iRODS
isaveRDS(foo, "foo.rds")
```

### Metadata

To truly appreciate the strength of iRODS, we can add some metadata that
describes the data object “foo”:

``` r
# add some metadata
imeta(
  "foo.rds", 
  operations = 
    data.frame(operation = "add", attribute = "foo", value = "bar", units = "baz")
)

# check if file is stored with associated metadata
ils(metadata = TRUE)
```

For more on using metadata, check out `vignette("metadata")`.

### Read R objects

If Alice wanted to copy the foo R object from an iRODS collection to her
current R session, she would use `ireadRDS()`:

``` r
# retrieve in native R format
ireadRDS("foo.rds")
```

### Other file formats

Possibly Alice does not want a native R object to be stored on iRODS but
a file type that can be accessed by other programs. For this, use the
`iput()` command:

``` r
library(readr)

# creates a csv file of foo
write_csv(foo, "foo.csv")

# send file
iput("foo.csv", "foo.csv")

# check whether it is stored
ils()
```

Later on somebody else might want to download this file again and store
it locally:

``` r
# retrieve it again later
iget("foo.csv", "foo.csv")
read_csv("foo.csv")
```

### Query

By adding metadata you and others can more easily discover data in
future projects. Objects can be searched with General Queries and
`iquery()`:

``` r
# look for objects in the home collection with a wildcard `%`
iquery("SELECT COLL_NAME, DATA_NAME WHERE COLL_NAME LIKE '/tempZone/home/%'")
```

``` r
# or for data objects with a name that starts with "foo"
iquery("SELECT COLL_NAME, DATA_NAME WHERE DATA_NAME LIKE 'foo%'")
```

For more on querying, check out `vignette("metadata")`.

### Cleanup

Finally, we can clean up Alice’s home collection:

``` r
# delete object
irm("foo.rds", force = TRUE)
irm("foo.csv", force = TRUE)

# check if objects are removed
ils()
```

``` r
# close the server
stop_irods_demo()
# optionally remove the Docker images
# irods:::remove_docker_images()
```

## Further Reading

- `vignette("demo")` for the local Docker-based demo environment.
- `vignette("metadata")` for metadata and query workflows.
- `vignette("local-irods")` for moving between local files and iRODS.
- `vignette("icommands")` for a mapping between `{rirods}` functions and
  iCommands.
- `vignette("develop")` for contributor setup and development notes.

## Development

The coverage scripts require `covr`.

Run line coverage for the offline-capable test suite with:

``` sh
Rscript --no-init-file scripts/test-coverage.R
```

This writes coverage artifacts under `coverage/` and is the same command
used by GitHub Actions for ordinary checks.

Run live coverage against a real iRODS HTTP API with:

``` sh
Rscript --no-init-file scripts/test-live-coverage.R
```

This writes coverage artifacts under `coverage-live/` and requires the
encrypted live-test environment variables `DEV_KEY_IRODS`,
`DEV_HOST_IRODS`, `DEV_USER`, and `DEV_PASS`. See `vignette("develop")`
for the full setup.
