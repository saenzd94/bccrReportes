#' Comprobar si existe un token del BCCR
#'
#' Verifica si se proporcionó un token o si la variable de entorno
#' `token_bccr` contiene un valor. El token nunca se imprime.
#'
#' @param token Token opcional. Si es `NULL`, se consulta `token_bccr`.
#'
#' @return Un valor lógico de longitud uno.
#' @export
#'
#' @examples
#' bccr_token_configurado()
bccr_token_configurado <- function(token = NULL) {
  if (is.null(token)) {
    token <- Sys.getenv("token_bccr", unset = "")
  }
  is.character(token) && length(token) == 1L &&
    !is.na(token) && nzchar(trimws(token))
}

#' Configurar el token del BCCR
#'
#' Guarda el token en la sesión actual. De forma opcional, actualiza
#' `.Renviron` para que esté disponible en futuras sesiones de R.
#'
#' @param token Token Bearer suministrado por el BCCR.
#' @param persistir Si es `TRUE`, guarda `token_bccr` en `archivo`.
#' @param archivo Archivo `.Renviron` que se modificará cuando
#'   `persistir = TRUE`.
#'
#' @return `TRUE`, de manera invisible.
#' @export
#'
#' @details
#' No incluya `.Renviron` en Git. El archivo se encuentra incluido en el
#' `.gitignore` de este proyecto.
#'
#' @examples
#' \dontrun{
#' configurar_token_bccr("su-token")
#' configurar_token_bccr("su-token", persistir = TRUE)
#' }
configurar_token_bccr <- function(
    token,
    persistir = FALSE,
    archivo = Sys.getenv(
      "R_ENVIRON_USER",
      unset = file.path(path.expand("~"), ".Renviron")
    )) {
  token <- .bccr_token(token)
  argumentos_entorno <- list(token)
  names(argumentos_entorno) <- "token_bccr"
  do.call(Sys.setenv, argumentos_entorno)

  if (isTRUE(persistir)) {
    archivo <- path.expand(archivo)
    directorio <- dirname(archivo)
    if (!dir.exists(directorio)) {
      stop(
        sprintf("No existe el directorio de destino: %s", directorio),
        call. = FALSE
      )
    }
    lineas <- if (file.exists(archivo)) {
      readLines(archivo, warn = FALSE, encoding = "UTF-8")
    } else {
      character()
    }
    lineas <- lineas[
      !grepl("^\\s*token_bccr\\s*=", lineas, perl = TRUE)
    ]
    token_escapado <- gsub("\\\\", "\\\\\\\\", token)
    token_escapado <- gsub("\"", "\\\\\"", token_escapado, fixed = TRUE)
    lineas <- c(lineas, sprintf("token_bccr=\"%s\"", token_escapado))
    writeLines(enc2utf8(lineas), archivo, useBytes = TRUE)
    message(
      "Token guardado en .Renviron. Reinicie R para cargarlo ",
      "autom\u00e1ticamente en nuevas sesiones."
    )
  }
  invisible(TRUE)
}
