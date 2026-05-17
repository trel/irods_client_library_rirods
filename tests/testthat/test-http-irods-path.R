with_http_fixture("expand-path", {
  test_that("expand path works", {
    expect_equal(make_irods_base_path(),
                 paste0("/", find_irods_file("irods_zone"), "/home/", .rirods$user))

    icd("..")
    icd("..")

    expect_equal(get_absolute_lpath(user), def_path)
    expect_equal(
      get_absolute_lpath(paste0(user, "/testthat")),
      irods_test_path
    )
    expect_equal(get_absolute_lpath(def_path), def_path)
    expect_error(get_absolute_lpath(paste0(lpath, "/frank")))
    expect_error(get_absolute_lpath("frank"))

    icd(irods_test_path)

    expect_equal(
      get_absolute_lpath("x/y", write = TRUE),
      paste0(irods_test_path, "/x/y")
    )
    expect_equal(
      get_absolute_lpath(paste0(irods_test_path, "/x"), write = TRUE),
      paste0(irods_test_path, "/x")
    )
  })
},
simplify = FALSE
)

with_http_fixture("object-helpers", {
  test_that("irods object helpers work", {
    test_iput(paste0(irods_test_path, "/dfr.csv"))

    expect_true(lpath_exists(def_path))
    expect_false(lpath_exists(paste0(dirname(def_path), "/frank")))
    expect_true(is_collection(def_path))
    expect_false(is_collection(paste0(irods_test_path, "/dfr.csv")))
    expect_error(is_collection(paste0(dirname(def_path), "/frank")))
    expect_true(is_object(paste0(irods_test_path, "/dfr.csv")))
    expect_false(is_object(def_path))
    expect_error(is_object(paste0(irods_test_path_x, "test.rds")))

    test_irm(paste0(irods_test_path, "/dfr.csv"))
  })
},
simplify = FALSE
)
