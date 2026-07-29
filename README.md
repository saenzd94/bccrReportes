# bccrWebService

`bccrWebService` es un cliente de R para consultar el API de indicadores
económicos del Banco Central de Costa Rica (BCCR). El paquete nació de las
funciones utilizadas en los reportes de este proyecto y conserva compatibilidad
con `BCCR_fun()`.

## Funcionalidades

- Autenticación mediante token Bearer, sin guardar credenciales en el código.
- Consulta y normalización de series históricas.
- Consulta de metadatos.
- Descarga del catálogo oficial en Excel.
- Consulta de varios indicadores y construcción de paneles.
- Reintentos automáticos ante errores transitorios.
- Mensajes claros para respuestas HTTP 400, 401, 403, 404, 429 y 500.
- Interfaz `BCCR_fun()` compatible con los reportes existentes.

## Instalación

Desde GitHub, después de sustituir `SU_USUARIO` por la cuenta propietaria del
repositorio:

```r
install.packages("remotes")
remotes::install_github("SU_USUARIO/bccrWebService")
```

También puede instalar una copia local:

```r
install.packages("ruta/bccrWebService_0.1.0.tar.gz",
                 repos = NULL, type = "source")
```

## Token del BCCR

El API requiere un token Bearer vigente. Puede registrarse desde la
[página de suscripción del BCCR](https://www.bccr.fi.cr/indicadores-economicos/suscripci%C3%B3n-a-indicadores).

Para usar el token únicamente en la sesión actual:

```r
library(bccrWebService)
configurar_token_bccr("SU_TOKEN")
```

Para guardarlo en `.Renviron` y cargarlo al iniciar R:

```r
configurar_token_bccr("SU_TOKEN", persistir = TRUE)
```

Reinicie R después de guardarlo. Verifique la configuración sin revelar el
valor:

```r
bccr_token_configurado()
```

Nunca incluya el token en scripts, pruebas, capturas, incidencias o commits. El
archivo `.Renviron` está excluido mediante `.gitignore`.

## Uso básico

Consultar el tipo de cambio de compra, código 317:

```r
compra <- consultar_bccr(
  codigo = 317,
  fecha_inicio = "2026-01-01",
  fecha_fin = Sys.Date()
)

head(compra)
```

El resultado contiene:

| columna | contenido |
|---|---|
| `codigo` | código oficial del indicador |
| `nombre` | nombre informado por el BCCR |
| `fecha` | fecha como objeto `Date` |
| `valor` | valor numérico normalizado |

## Varios indicadores

Los nombres del vector se conservan en `etiqueta`:

```r
tipos_cambio <- consultar_bccr_varios(
  c(compra = 317, venta = 318),
  fecha_inicio = "2026-01-01",
  fecha_fin = Sys.Date()
)
```

Por defecto, si un código falla los restantes se siguen consultando. Los
mensajes quedan disponibles en:

```r
attr(tipos_cambio, "errores")
```

Use `continuar_error = FALSE` para detener la ejecución ante el primer error.

## Metadatos y catálogo

```r
obtener_metadata_bccr(317)

descargar_catalogo_bccr(
  destino = "IndicadoresDisponibles.xlsx",
  sobrescribir = TRUE
)
```

El paquete incorpora una selección no exhaustiva de los indicadores empleados
en los reportes:

```r
indicadores_bccr_referencia()
```

El catálogo descargado desde el BCCR es la fuente vigente y autoritativa.

## Compatibilidad con reportes existentes

La función histórica mantiene los nombres de columnas esperados:

```r
datos <- BCCR_fun(
  codigo = 317,
  inicio = "2026-01-01",
  fin = Sys.Date(),
  idioma = "ES"
)

names(datos)
#> [1] "Fecha"     "Indicator"
```

Así, un reporte que antes cargaba `funciones/BCCR_fun.R` puede pasar a:

```r
library(bccrWebService)
```

sin cambiar las llamadas existentes a `BCCR_fun()`.

## Desarrollo y validación

```r
install.packages("devtools")
devtools::document()
devtools::test()
devtools::check()
```

Las pruebas unitarias no requieren credenciales ni conexión. La prueba en vivo
es optativa y solo se ejecuta cuando existe un token y se define:

```r
Sys.setenv(BCCR_RUN_LIVE_TESTS = "true")
devtools::test()
```

## Fuentes oficiales

- [Documentación de APIs del BCCR](https://www.bccr.fi.cr/indicadores-economicos/Paginas/APIs.aspx)
- [Estándar electrónico del API SDDE](https://gee.bccr.fi.cr/indicadoreseconomicos/Documentos/DocumentosMetodologiasNotasTecnicas/Estandar_API_SDDE.pdf)
- [Suscripción a indicadores](https://www.bccr.fi.cr/indicadores-economicos/suscripci%C3%B3n-a-indicadores)

## Licencia

MIT © 2026 Diego Sáenz C.

