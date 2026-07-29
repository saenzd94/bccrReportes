test_that("los códigos y fechas inválidos fallan antes de consultar", {
  expect_error(
    consultar_bccr("abc", "2026-01-01", token = "token-de-prueba"),
    "entero positivo"
  )
  expect_error(
    consultar_bccr(317, "fecha-invalida", token = "token-de-prueba"),
    "fecha válida"
  )
  expect_error(
    consultar_bccr(
      317, "2026-02-01", "2026-01-01", token = "token-de-prueba"
    ),
    "posterior"
  )
  expect_error(
    consultar_bccr(
      317, "2026-01-01", idioma = "FR", token = "token-de-prueba"
    ),
    "'ES' o 'EN'"
  )
})

test_that("la ausencia de token produce un mensaje útil", {
  anterior <- Sys.getenv("token_bccr", unset = NA_character_)
  on.exit({
    if (is.na(anterior)) {
      Sys.unsetenv("token_bccr")
    } else {
      Sys.setenv(token_bccr = anterior)
    }
  }, add = TRUE)
  Sys.unsetenv("token_bccr")

  expect_false(bccr_token_configurado())
  expect_error(
    consultar_bccr(317, "2026-01-01"),
    "token"
  )
})

test_that("configurar_token_bccr actualiza sesión y archivo", {
  anterior <- Sys.getenv("token_bccr", unset = NA_character_)
  on.exit({
    if (is.na(anterior)) {
      Sys.unsetenv("token_bccr")
    } else {
      Sys.setenv(token_bccr = anterior)
    }
  }, add = TRUE)

  archivo <- tempfile(fileext = ".Renviron")
  writeLines(c("OTRA_VARIABLE=1", "token_bccr=\"anterior\""), archivo)
  expect_message(
    configurar_token_bccr(
      "token-de-prueba", persistir = TRUE, archivo = archivo
    ),
    "Token guardado"
  )
  expect_true(bccr_token_configurado())
  lineas <- readLines(archivo, warn = FALSE)
  expect_equal(sum(grepl("^token_bccr=", lineas)), 1L)
  expect_true(any(grepl("token-de-prueba", lineas, fixed = TRUE)))
  expect_true(any(grepl("OTRA_VARIABLE=1", lineas, fixed = TRUE)))
})

