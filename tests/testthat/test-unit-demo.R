test_that("demo compose command uses the dedicated minimal compose file", {
  testthat::with_mocked_bindings({
    expect_identical(
      demo_compose_command("down"),
      "docker compose -f '/tmp/docker-compose.rirods.yml' down"
    )
  },
  path_to_demo_compose = function() "/tmp/docker-compose.rirods.yml",
  .package = "rirods"
  )
})

test_that("demo container refs match the minimal compose services", {
  expect_identical(
    irods_containers_ref(),
    c(
      "irods-demo-irods-catalog-1",
      "irods-demo-irods-catalog-provider-1",
      "irods-demo-irods-client-icommands-1",
      "irods-demo-irods-client-http-api-1",
      "irods-demo-minio-1"
    )
  )
})
