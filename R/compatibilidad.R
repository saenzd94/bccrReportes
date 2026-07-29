#' Consultar el BCCR con la interfaz histórica del proyecto
#'
#' Función de compatibilidad para reportes que llaman
#' `BCCR_fun(codigo, inicio, fin, idioma)`.
#'
#' @param codigo Código numérico del indicador.
#' @param inicio Fecha inicial.
#' @param fin Fecha final.
#' @param idioma Idioma de la respuesta: `"ES"` o `"EN"`.
#' @param token Token Bearer. Si es `NULL`, se usa `token_bccr`.
#' @param ... Argumentos adicionales enviados a [consultar_bccr()].
#'
#' @return Un `tibble` con las columnas `Fecha` e `Indicator`.
#' @export
#'
#' @examples
#' \dontrun{
#' BCCR_fun(317, "2026-01-01", Sys.Date(), idioma = "ES")
#' }
BCCR_fun <- function(codigo, inicio, fin, idioma = "ES", token = NULL, ...) {
  salida <- consultar_bccr(
    codigo = codigo,
    fecha_inicio = inicio,
    fecha_fin = fin,
    idioma = idioma,
    token = token,
    ...
  )
  tibble::tibble(
    Fecha = salida$fecha,
    Indicator = salida$valor
  )
}

