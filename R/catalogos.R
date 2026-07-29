#' Obtener metadatos de un indicador del BCCR
#'
#' @param codigo Código numérico del indicador.
#' @param idioma Idioma de la respuesta: `"ES"` o `"EN"`.
#' @param token Token Bearer. Si es `NULL`, se usa `token_bccr`.
#' @param timeout Tiempo máximo, en segundos, por intento.
#' @param intentos Número total de intentos ante fallos transitorios.
#'
#' @return Un `tibble` con los metadatos disponibles.
#' @export
#'
#' @examples
#' \dontrun{
#' obtener_metadata_bccr(317)
#' }
obtener_metadata_bccr <- function(codigo, idioma = "ES", token = NULL,
                                  timeout = 60, intentos = 4) {
  codigo <- .bccr_codigo(codigo)
  idioma <- .bccr_idioma(idioma)
  objeto <- .bccr_json(
    ruta = paste0("indicadoresEconomicos/", codigo, "/metadata"),
    query = list(idioma = idioma),
    token = token,
    timeout = timeout,
    intentos = intentos
  )
  datos <- objeto$datos
  if (is.null(datos) || length(datos) == 0L) {
    return(tibble::tibble())
  }
  filas <- lapply(datos, function(fila) {
    valores <- lapply(fila, function(x) {
      if (is.null(x) || length(x) == 0L) NA else x[[1L]]
    })
    as.data.frame(valores, stringsAsFactors = FALSE, check.names = FALSE)
  })
  salida <- tibble::as_tibble(do.call(rbind, filas))
  columnas_fecha <- intersect(
    c("primerDato", "ultimoDatoSerie", "ultimaPublicacion"),
    names(salida)
  )
  for (columna in columnas_fecha) {
    salida[[columna]] <- suppressWarnings(
      as.Date(substr(as.character(salida[[columna]]), 1L, 10L))
    )
  }
  salida
}

#' Descargar el catálogo oficial de indicadores del BCCR
#'
#' Descarga el archivo Excel publicado por el endpoint oficial de indicadores
#' económicos.
#'
#' @param destino Ruta del archivo `.xlsx` que se creará.
#' @param idioma Idioma del catálogo: `"ES"` o `"EN"`.
#' @param token Token Bearer. Si es `NULL`, se usa `token_bccr`.
#' @param timeout Tiempo máximo, en segundos, por intento.
#' @param intentos Número total de intentos ante fallos transitorios.
#' @param sobrescribir Si es `TRUE`, permite reemplazar un archivo existente.
#'
#' @return La ruta normalizada del archivo, de manera invisible.
#' @export
#'
#' @examples
#' \dontrun{
#' descargar_catalogo_bccr("IndicadoresDisponibles.xlsx")
#' }
descargar_catalogo_bccr <- function(
    destino = file.path(getwd(), "IndicadoresDisponibles.xlsx"),
    idioma = "ES",
    token = NULL,
    timeout = 60,
    intentos = 4,
    sobrescribir = FALSE) {
  idioma <- .bccr_idioma(idioma)
  destino <- path.expand(destino)
  if (file.exists(destino) && !isTRUE(sobrescribir)) {
    stop(
      "El archivo de destino ya existe. Use 'sobrescribir = TRUE'.",
      call. = FALSE
    )
  }
  directorio <- dirname(destino)
  if (!dir.exists(directorio)) {
    dir.create(directorio, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(directorio)) {
    stop("No fue posible crear el directorio de destino.", call. = FALSE)
  }

  respuesta <- .bccr_respuesta(
    ruta = "indicadoresEconomicos/descargar",
    query = list(idioma = idioma),
    token = token,
    timeout = timeout,
    intentos = intentos
  )
  contenido <- httr::content(respuesta, as = "raw")
  conexion <- file(destino, open = "wb")
  on.exit(close(conexion), add = TRUE)
  writeBin(contenido, conexion)
  invisible(normalizePath(destino, winslash = "/", mustWork = TRUE))
}

#' Validar una suscripción del BCCR
#'
#' Consulta el endpoint oficial de validación de suscripciones.
#'
#' @param correo Correo asociado con la suscripción.
#' @param token Token Bearer asociado con el correo. Si es `NULL`, se usa
#'   `token_bccr`.
#' @param timeout Tiempo máximo, en segundos, por intento.
#' @param intentos Número total de intentos ante fallos transitorios.
#'
#' @return Un `tibble` de una fila con `valida` y `mensaje`.
#' @export
#'
#' @examples
#' \dontrun{
#' validar_suscripcion_bccr("persona@ejemplo.com")
#' }
validar_suscripcion_bccr <- function(correo, token = NULL, timeout = 60,
                                     intentos = 4) {
  if (!is.character(correo) || length(correo) != 1L ||
      is.na(correo) || !nzchar(trimws(correo)) ||
      !grepl("^[^@[:space:]]+@[^@[:space:]]+$", correo)) {
    stop(
      "'correo' debe ser una direcci\u00f3n de correo v\u00e1lida.",
      call. = FALSE
    )
  }
  token <- .bccr_token(token)
  objeto <- .bccr_json(
    metodo = "POST",
    ruta = "Usuario/ValideSuscripcion",
    query = list(correo = trimws(correo), token = token),
    token = token,
    timeout = timeout,
    intentos = intentos,
    permitir_estado_falso = TRUE
  )
  tibble::tibble(
    valida = isTRUE(objeto$estado),
    mensaje = as.character(objeto$mensaje %||% "")
  )
}

#' Indicadores de referencia utilizados en los reportes
#'
#' Devuelve una selección no exhaustiva de códigos usados en los reportes del
#' proyecto. Para obtener el catálogo completo y vigente use
#' [descargar_catalogo_bccr()].
#'
#' @return Un `tibble` con `codigo`, `variable` y `grupo`.
#' @export
#'
#' @examples
#' indicadores_bccr_referencia()
indicadores_bccr_referencia <- function() {
  ruta <- system.file(
    "extdata", "indicadores_referencia.csv",
    package = "bccrReportes"
  )
  tibble::as_tibble(
    utils::read.csv(
      ruta,
      stringsAsFactors = FALSE,
      fileEncoding = "UTF-8",
      check.names = FALSE
    )
  )
}
