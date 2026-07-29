test_that("la consulta múltiple acepta un vector vacío", {
  salida <- consultar_bccr_varios(
    numeric(),
    fecha_inicio = "2026-01-01",
    token = "token-de-prueba"
  )
  expect_s3_class(salida, "tbl_df")
  expect_identical(
    names(salida),
    c("codigo", "nombre", "etiqueta", "fecha", "valor")
  )
  expect_equal(nrow(salida), 0L)
})

test_that("los indicadores de referencia se instalan con el paquete", {
  salida <- indicadores_bccr_referencia()
  expect_s3_class(salida, "tbl_df")
  expect_true(all(c("codigo", "variable", "grupo") %in% names(salida)))
  expect_true(all(c(317, 318) %in% salida$codigo))
})

test_that("BCCR_fun conserva la firma esperada", {
  argumentos <- names(formals(BCCR_fun))
  expect_true(all(c("codigo", "inicio", "fin", "idioma") %in% argumentos))
})

