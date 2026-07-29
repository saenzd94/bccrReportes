.bccr_base_url <- paste0(
  "https://apim.bccr.fi.cr/SDDE/api/",
  "Bccr.Ge.SDDE.Publico.Indicadores.API"
)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

.bccr_token <- function(token = NULL) {
  if (is.null(token)) {
    token <- Sys.getenv("token_bccr", unset = "")
  }
  if (!is.character(token) || length(token) != 1L ||
      is.na(token) || !nzchar(trimws(token))) {
    stop(
      paste0(
        "No se encontr\u00f3 un token del BCCR. Configure la variable de entorno ",
        "'token_bccr' o use configurar_token_bccr()."
      ),
      call. = FALSE
    )
  }
  trimws(token)
}

.bccr_codigo <- function(codigo) {
  if (length(codigo) != 1L || is.na(codigo)) {
    stop("'codigo' debe contener un \u00fanico c\u00f3digo de indicador.", call. = FALSE)
  }
  codigo <- trimws(as.character(codigo))
  if (!grepl("^[0-9]+$", codigo) || identical(codigo, "0")) {
    stop("'codigo' debe ser un entero positivo.", call. = FALSE)
  }
  codigo
}

.bccr_fecha <- function(x, argumento) {
  if (length(x) != 1L || is.na(x)) {
    stop(sprintf("'%s' debe contener una \u00fanica fecha v\u00e1lida.", argumento),
         call. = FALSE)
  }
  if (inherits(x, "Date")) {
    return(x)
  }
  x <- as.character(x)
  formatos <- c("%Y-%m-%d", "%Y/%m/%d", "%d/%m/%Y")
  for (formato in formatos) {
    salida <- suppressWarnings(as.Date(x, format = formato))
    if (!is.na(salida)) {
      return(salida)
    }
  }
  stop(
    sprintf(
      "'%s' no es una fecha v\u00e1lida. Use AAAA-MM-DD, AAAA/MM/DD o DD/MM/AAAA.",
      argumento
    ),
    call. = FALSE
  )
}

.bccr_idioma <- function(idioma) {
  idioma <- toupper(as.character(idioma)[1L])
  if (!idioma %in% c("ES", "EN")) {
    stop("'idioma' debe ser 'ES' o 'EN'.", call. = FALSE)
  }
  idioma
}

.bccr_parametros_http <- function(timeout, intentos) {
  if (length(timeout) != 1L || !is.numeric(timeout) || is.na(timeout) ||
      timeout <= 0) {
    stop("'timeout' debe ser un n\u00famero positivo de segundos.", call. = FALSE)
  }
  if (length(intentos) != 1L || !is.numeric(intentos) || is.na(intentos) ||
      intentos < 1 || intentos != as.integer(intentos)) {
    stop("'intentos' debe ser un entero positivo.", call. = FALSE)
  }
  list(timeout = as.numeric(timeout), intentos = as.integer(intentos))
}

.bccr_mensaje_http <- function(respuesta) {
  texto <- tryCatch(
    httr::content(respuesta, as = "text", encoding = "UTF-8"),
    error = function(e) ""
  )
  if (!nzchar(texto)) {
    return("")
  }
  objeto <- tryCatch(
    jsonlite::fromJSON(texto, simplifyVector = TRUE),
    error = function(e) NULL
  )
  if (is.list(objeto)) {
    mensaje <- objeto$Mensaje %||% objeto$mensaje %||% objeto$message
    if (!is.null(mensaje) && length(mensaje) >= 1L) {
      return(as.character(mensaje[[1L]]))
    }
  }
  ""
}

.bccr_guia_estado <- function(estado) {
  switch(
    as.character(estado),
    "400" = "Revise el c\u00f3digo, las fechas y el idioma enviados.",
    "401" = "El token est\u00e1 ausente, es inv\u00e1lido o venci\u00f3.",
    "403" = "La suscripci\u00f3n no tiene acceso o no est\u00e1 vigente.",
    "404" = "El endpoint o el c\u00f3digo solicitado no est\u00e1 disponible.",
    "429" = "Se excedi\u00f3 la frecuencia permitida; intente m\u00e1s tarde.",
    "500" = "El servicio del BCCR present\u00f3 un error interno.",
    "Revise la conexi\u00f3n y la disponibilidad del servicio."
  )
}

.bccr_respuesta <- function(metodo = "GET", ruta, query = list(),
                            token = NULL, timeout = 60, intentos = 4) {
  token <- .bccr_token(token)
  parametros <- .bccr_parametros_http(timeout, intentos)
  url <- paste0(.bccr_base_url, "/", sub("^/+", "", ruta))

  argumentos <- c(
    list(
      verb = metodo,
      url = url,
      query = query,
      times = parametros$intentos,
      pause_base = 1,
      pause_cap = 10,
      terminate_on = c(400L, 401L, 403L, 404L),
      quiet = TRUE
    ),
    list(
      httr::add_headers(
        Authorization = paste("Bearer", token),
        `Content-Type` = "application/json",
        `User-Agent` = "bccr_reportes/0.1.0"
      ),
      httr::timeout(parametros$timeout)
    )
  )

  respuesta <- tryCatch(
    do.call(httr::RETRY, argumentos),
    error = function(e) {
      stop(
        sprintf("No fue posible conectar con el BCCR: %s", conditionMessage(e)),
        call. = FALSE
      )
    }
  )
  estado <- httr::status_code(respuesta)
  if (estado < 200L || estado >= 300L) {
    detalle <- .bccr_mensaje_http(respuesta)
    if (nzchar(detalle)) {
      detalle <- paste0(" Detalle del servicio: ", detalle)
    }
    stop(
      sprintf(
        "La consulta al BCCR respondi\u00f3 HTTP %s. %s%s",
        estado, .bccr_guia_estado(estado), detalle
      ),
      call. = FALSE
    )
  }
  respuesta
}

.bccr_json <- function(metodo = "GET", ruta, query = list(),
                       token = NULL, timeout = 60, intentos = 4,
                       permitir_estado_falso = FALSE) {
  respuesta <- .bccr_respuesta(
    metodo = metodo,
    ruta = ruta,
    query = query,
    token = token,
    timeout = timeout,
    intentos = intentos
  )
  texto <- httr::content(respuesta, as = "text", encoding = "UTF-8")
  objeto <- tryCatch(
    jsonlite::fromJSON(texto, simplifyVector = FALSE),
    error = function(e) {
      stop(
        sprintf("El BCCR devolvi\u00f3 una respuesta JSON inv\u00e1lida: %s",
                conditionMessage(e)),
        call. = FALSE
      )
    }
  )
  if (!is.null(objeto$estado) && !isTRUE(objeto$estado) &&
      !isTRUE(permitir_estado_falso)) {
    stop(
      paste0(
        "El BCCR no complet\u00f3 la consulta: ",
        as.character(objeto$mensaje %||% "sin detalle")
      ),
      call. = FALSE
    )
  }
  objeto
}

.bccr_numero <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NA_real_)
  }
  if (is.numeric(x)) {
    salida <- as.numeric(x[[1L]])
    if (!is.finite(salida)) return(NA_real_)
    return(salida)
  }
  x <- trimws(as.character(x[[1L]]))
  if (!nzchar(x) || x %in% c("NA", "NaN", "NULL", "null")) {
    return(NA_real_)
  }
  tiene_coma <- grepl(",", x, fixed = TRUE)
  tiene_punto <- grepl(".", x, fixed = TRUE)
  if (tiene_coma && tiene_punto) {
    ultima_coma <- max(gregexpr(",", x, fixed = TRUE)[[1L]])
    ultimo_punto <- max(gregexpr(".", x, fixed = TRUE)[[1L]])
    if (ultima_coma > ultimo_punto) {
      x <- gsub(".", "", x, fixed = TRUE)
      x <- sub(",", ".", x, fixed = TRUE)
    } else {
      x <- gsub(",", "", x, fixed = TRUE)
    }
  } else if (tiene_coma) {
    x <- sub(",", ".", x, fixed = TRUE)
  }
  salida <- suppressWarnings(as.numeric(x))
  if (!is.finite(salida)) NA_real_ else salida
}

.bccr_serie_vacia <- function() {
  tibble::tibble(
    codigo = character(),
    nombre = character(),
    fecha = as.Date(character()),
    valor = numeric()
  )
}

.bccr_extraer_serie <- function(objeto, codigo_solicitado) {
  datos <- objeto$datos
  if (is.null(datos) || length(datos) == 0L) {
    return(.bccr_serie_vacia())
  }
  indicador <- datos[[1L]]
  series <- indicador$series
  if (is.null(series) || length(series) == 0L) {
    return(.bccr_serie_vacia())
  }

  valor_texto <- function(fila, campo, predeterminado = NA_character_) {
    valor <- fila[[campo]]
    if (is.null(valor) || length(valor) == 0L || is.na(valor[[1L]])) {
      return(predeterminado)
    }
    as.character(valor[[1L]])
  }
  fechas <- vapply(
    series, valor_texto, character(1L), campo = "fecha"
  )
  valores <- vapply(
    series,
    function(fila) .bccr_numero(fila[["valorDatoPorPeriodo"]]),
    numeric(1L)
  )
  codigo <- as.character(
    indicador$codigoIndicador %||% indicador$codIndicador %||%
      codigo_solicitado
  )[1L]
  nombre <- as.character(
    indicador$nombreIndicador %||% indicador$nombre %||% NA_character_
  )[1L]

  salida <- tibble::tibble(
    codigo = rep(codigo, length(fechas)),
    nombre = rep(nombre, length(fechas)),
    fecha = suppressWarnings(as.Date(substr(fechas, 1L, 10L))),
    valor = valores
  )
  salida <- salida[!is.na(salida$fecha), , drop = FALSE]
  salida[order(salida$fecha), , drop = FALSE]
}
