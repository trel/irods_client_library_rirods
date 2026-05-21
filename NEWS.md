# rirods 0.3.0

## Major changes

* Added `ichksum()` to calculate or retrieve iRODS data object checksums.
* Updated the demo workflow to use a dedicated minimal Docker Compose file and the newer iRODS HTTP API v0.6.0 demo stack.

## Compatibility and behavior fixes

* Added optional `client_name` support in `create_irods()` and forwarded the resulting HTTP API `spOption` on requests.
* Improved connection setup and session handling by making the default API host configurable, preserving authentication state during tests, and handling non-home landing collections.
* Hardened path, listing, and metadata behavior in `ils()`, including more reliable stat/permission handling, full listings, mixed metadata alignment, and faster path existence checks.

## Testing and CI

* Reworked the test suite into offline HTTP fixtures, unit tests, and dedicated live integration coverage.
* Added local and live coverage scripts plus corresponding CI workflows.
* Greatly expanded live coverage for configuration, navigation, metadata, transfer, and HTTP error handling.

## Documentation

* Refreshed the README and package overview to better describe setup, development workflows, and the current demo environment.

# rirods 0.2.0

## Major changes

* Moving to the new [iRODS C++ HTTP API](https://github.com/irods/irods_client_http_api)

## Minor changes

* Printed output `ils()` has changed a little
* Parameters of `create_irods()`, `isaveRDS()`, `iput()`, `iget()`, `ireadRDS()`, `imeta()`, and `iquery()` are soft deprecated and will be removed over time

# rirods 0.1.2

* Adding more documentation as vignettes:
  + Use iRODS demo
  + rirods vs iCommands
  + Accessing data locally and in iRODS
  + Use iRODS metadata

# rirods 0.1.1

* Supply configuration file to correct user-specific configuration directory 
with `rappdirs::user_config_dir()`.

# rirods 0.1.0

* Initial CRAN submission.
