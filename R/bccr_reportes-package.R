#' bccr_reportes: cliente R para indicadores económicos del BCCR
#'
#' El paquete ofrece una interfaz para consultar el API moderno del Banco
#' Central de Costa Rica, normalizar series, obtener metadatos, descargar el
#' catálogo oficial y conservar compatibilidad con `BCCR_fun()`.
#'
#' @section Autenticación:
#' Configure la variable de entorno `token_bccr` con
#' [configurar_token_bccr()]. El token no debe guardarse en scripts ni
#' repositorios.
#'
#' @section Funciones principales:
#' - [consultar_bccr()] consulta una serie.
#' - [consultar_bccr_varios()] construye un panel de varias series.
#' - [obtener_metadata_bccr()] consulta metadatos.
#' - [descargar_catalogo_bccr()] descarga el catálogo oficial.
#' - [BCCR_fun()] mantiene compatibilidad con reportes existentes.
#'
#' @references
#' Banco Central de Costa Rica. Documentación del API SDDE:
#' \url{https://www.bccr.fi.cr/indicadores-economicos/Paginas/APIs.aspx}
#'
#' @keywords internal
"_PACKAGE"

