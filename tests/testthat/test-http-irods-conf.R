with_http_fixture("server-info", {
  test_that("server infor can be obtained", {
    server_info <- get_server_info()
    expect_type(server_info, "list")
  })
})
