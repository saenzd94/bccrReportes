test_that("se extrae y ordena una serie del JSON oficial", {
  objeto <- list(
    estado = TRUE,
    mensaje = "Consulta exitosa",
    datos = list(list(
      codigoIndicador = "317",
      nombreIndicador = "Tipo cambio compra",
      series = list(
        list(fecha = "2026-01-02", valorDatoPorPeriodo = 510.25),
        list(fecha = "2026-01-01", valorDatoPorPeriodo = "509,75"),
        list(fecha = "2026-01-03", valorDatoPorPeriodo = NULL)
      )
    ))
  )

  salida <- bccrReportes:::.bccr_extraer_serie(objeto, "317")
  expect_s3_class(salida, "tbl_df")
  expect_identical(names(salida), c("codigo", "nombre", "fecha", "valor"))
  expect_equal(salida$fecha, as.Date(c(
    "2026-01-01", "2026-01-02", "2026-01-03"
  )))
  expect_equal(salida$valor[1:2], c(509.75, 510.25))
  expect_true(is.na(salida$valor[3]))
})

test_that("la normalización numérica distingue convenciones", {
  numero <- bccrReportes:::.bccr_numero
  expect_equal(numero("1.234,56"), 1234.56)
  expect_equal(numero("1,234.56"), 1234.56)
  expect_equal(numero("510,25"), 510.25)
  expect_true(is.na(numero(NULL)))
})

test_that("una respuesta sin datos genera la plantilla correcta", {
  salida <- bccrReportes:::.bccr_extraer_serie(
    list(estado = TRUE, datos = list()),
    "317"
  )
  expect_s3_class(salida, "tbl_df")
  expect_equal(nrow(salida), 0L)
  expect_s3_class(salida$fecha, "Date")
})
