test_that("el API responde en una prueba optativa", {
  skip_if_not(
    identical(tolower(Sys.getenv("BCCR_RUN_LIVE_TESTS")), "true"),
    "Defina BCCR_RUN_LIVE_TESTS=true para ejecutar la prueba en vivo."
  )
  skip_if_not(
    bccr_token_configurado(),
    "La prueba en vivo requiere token_bccr."
  )

  fin <- Sys.Date()
  inicio <- fin - 30
  salida <- consultar_bccr(317, inicio, fin)
  expect_s3_class(salida, "tbl_df")
  expect_true(all(c("codigo", "nombre", "fecha", "valor") %in% names(salida)))
  expect_true(nrow(salida) > 0L)
})

