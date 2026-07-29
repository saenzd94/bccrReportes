#' Consultar una serie de indicadores económicos del BCCR
#'
#' Consulta el API moderno del BCCR y devuelve una tabla normalizada.
#'
#' @param codigo Código numérico del indicador.
#' @param fecha_inicio Fecha inicial. Acepta `Date`, `AAAA-MM-DD`,
#'   `AAAA/MM/DD` o `DD/MM/AAAA`.
#' @param fecha_fin Fecha final; por defecto, la fecha actual.
#' @param idioma Idioma de la respuesta: `"ES"` o `"EN"`.
#' @param token Token Bearer. Si es `NULL`, se usa `token_bccr`.
#' @param timeout Tiempo máximo, en segundos, por intento.
#' @param intentos Número total de intentos ante fallos transitorios.
#' @param omitir_na Si es `TRUE`, elimina observaciones sin valor.
#'
#' @return Un `tibble` con las columnas `codigo`, `nombre`, `fecha` y `valor`.
#' @export
#'
#' @examples
#' \dontrun{
#' tipo_cambio <- consultar_bccr(
#'   codigo = 317,
#'   fecha_inicio = "2026-01-01",
#'   fecha_fin = Sys.Date()
#' )
#' }
consultar_bccr <- function(codigo, fecha_inicio, fecha_fin = Sys.Date(),
                           idioma = "ES", token = NULL, timeout = 60,
                           intentos = 4, omitir_na = TRUE) {
  codigo <- .bccr_codigo(codigo)
  fecha_inicio <- .bccr_fecha(fecha_inicio, "fecha_inicio")
  fecha_fin <- .bccr_fecha(fecha_fin, "fecha_fin")
  idioma <- .bccr_idioma(idioma)
  if (fecha_inicio > fecha_fin) {
    stop("'fecha_inicio' no puede ser posterior a 'fecha_fin'.",
         call. = FALSE)
  }

  objeto <- .bccr_json(
    ruta = paste0("indicadoresEconomicos/", codigo, "/series"),
    query = list(
      fechaInicio = format(fecha_inicio, "%Y/%m/%d"),
      fechaFin = format(fecha_fin, "%Y/%m/%d"),
      idioma = idioma
    ),
    token = token,
    timeout = timeout,
    intentos = intentos
  )
  salida <- .bccr_extraer_serie(objeto, codigo)
  if (isTRUE(omitir_na)) {
    salida <- salida[!is.na(salida$valor) & is.finite(salida$valor), ,
                     drop = FALSE]
  }
  tibble::as_tibble(salida)
}

#' Consultar varios indicadores del BCCR
#'
#' Ejecuta [consultar_bccr()] para cada código y combina los resultados.
#'
#' @param codigos Vector de códigos. Puede ser un vector con nombres; esos
#'   nombres se conservarán en la columna `etiqueta`.
#' @inheritParams consultar_bccr
#' @param continuar_error Si es `TRUE`, continúa con los demás códigos cuando
#'   uno falla y guarda los mensajes en el atributo `errores`.
#'
#' @return Un `tibble` con `codigo`, `nombre`, `etiqueta`, `fecha` y `valor`.
#'   Los errores recuperables quedan en `attr(resultado, "errores")`.
#' @export
#'
#' @examples
#' \dontrun{
#' panel <- consultar_bccr_varios(
#'   c(compra = 317, venta = 318),
#'   fecha_inicio = "2026-01-01"
#' )
#' }
consultar_bccr_varios <- function(
    codigos,
    fecha_inicio,
    fecha_fin = Sys.Date(),
    idioma = "ES",
    token = NULL,
    timeout = 60,
    intentos = 4,
    omitir_na = TRUE,
    continuar_error = TRUE) {
  if (length(codigos) == 0L) {
    return(tibble::tibble(
      codigo = character(), nombre = character(), etiqueta = character(),
      fecha = as.Date(character()), valor = numeric()
    ))
  }
  etiquetas <- names(codigos)
  if (is.null(etiquetas)) {
    etiquetas <- rep("", length(codigos))
  }
  resultados <- vector("list", length(codigos))
  errores <- character()

  for (i in seq_along(codigos)) {
    codigo_i <- as.character(codigos[[i]])
    consulta <- tryCatch(
      consultar_bccr(
        codigo = codigo_i,
        fecha_inicio = fecha_inicio,
        fecha_fin = fecha_fin,
        idioma = idioma,
        token = token,
        timeout = timeout,
        intentos = intentos,
        omitir_na = omitir_na
      ),
      error = function(e) {
        if (!isTRUE(continuar_error)) {
          stop(e)
        }
        errores[[codigo_i]] <<- conditionMessage(e)
        .bccr_serie_vacia()
      }
    )
    etiqueta <- etiquetas[[i]]
    if (!nzchar(etiqueta) && nrow(consulta) > 0L) {
      etiqueta <- consulta$nombre[[1L]]
    }
    consulta$etiqueta <- rep(etiqueta, nrow(consulta))
    resultados[[i]] <- consulta[, c(
      "codigo", "nombre", "etiqueta", "fecha", "valor"
    ), drop = FALSE]
  }

  salida <- tibble::as_tibble(do.call(rbind, resultados))
  attr(salida, "errores") <- errores
  if (length(errores) > 0L) {
    warning(
      sprintf(
        "No fue posible consultar %s c\u00f3digo(s). Revise attr(x, 'errores').",
        length(errores)
      ),
      call. = FALSE
    )
  }
  salida
}
