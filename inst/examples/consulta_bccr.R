# Ejemplo reproducible de uso de bccrReportes.
#
# Antes de ejecutar, obtenga un token del BCCR y configure:
# Sys.setenv(token_bccr = "SU_TOKEN")
# o, una sola vez:
# configurar_token_bccr("SU_TOKEN", persistir = TRUE)

library(bccrReportes)

# Verificar la configuración sin revelar el token.
bccr_token_configurado()

# Serie individual: tipo de cambio de compra.
compra <- consultar_bccr(
  codigo = 317,
  fecha_inicio = "2026-01-01",
  fecha_fin = Sys.Date()
)

# Panel de compra y venta.
tipos_cambio <- consultar_bccr_varios(
  c(compra = 317, venta = 318),
  fecha_inicio = "2026-01-01",
  fecha_fin = Sys.Date()
)

# Metadatos y catálogo.
metadata_compra <- obtener_metadata_bccr(317)
# descargar_catalogo_bccr("IndicadoresDisponibles.xlsx")

# Compatibilidad con los reportes existentes.
compra_compatible <- BCCR_fun(
  317,
  inicio = "2026-01-01",
  fin = Sys.Date(),
  idioma = "ES"
)
