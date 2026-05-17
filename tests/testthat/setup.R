library(httptest2)
library(httr2)

source(testthat::test_path("helper-env.R"), local = TRUE)
source(testthat::test_path("helper-http.R"), local = TRUE)

#-------------------------------------------------------------------------------
# Snapshots are created with github actions using the latest irods_demo
# configuration. Hence we set these environmental variables as default when
# loading the package and no environmental variables are set. This ensures
# that CRAN checks won't fail. In case of testing on your own sever, you have
# to create a package development key with the httr2 package and place it
# in your environmental variables. To use the scrambled server information in
# the tests place them in your project level environmental variable
# (possibly place those in your .Rprofile for convenience)
#-------------------------------------------------------------------------------

list2env(bootstrap_test_state(), environment())
