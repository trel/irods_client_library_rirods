with_mock_dir("authentication", {
  test_that("authentication errors in absence of configuration", {
    tmp <- tempfile()
    file.copy(path_to_irods_conf(), tmp)
    unlink(path_to_irods_conf())
    expect_error(iauth(user, pass, "rodsuser"))
    file.copy(tmp, path_to_irods_conf())
    expect_type(find_irods_file(), "list")
  })
})
