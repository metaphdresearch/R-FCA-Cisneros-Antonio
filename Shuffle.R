# ==============================================================================
# SCRIPT DE ALEATORIZACIÓN MASIVA PARA HOJAS DE EXCEL (.XLSX)
# Curso de R - FCA DESCRIPTIVO
# ==============================================================================

# 1. Instalar y cargar librerías necesarias si no las tienes
if (!require("readxl")) install.packages("readxl")
if (!require("openxlsx")) install.packages("openxlsx")

library(readxl)
library(openxlsx)

# 2. Configurar la ruta de trabajo local exacta de tu sistema
dir_trabajo <- "D:/Tony 2023 Bai Ze/¬ DOCTORADO + ARTÍCULOS/7 SEMESTRE/2 Servicio Social/FCA DESCRIPTIVO"
setwd(dir_trabajo)

archivo_entrada <- "Encuesta MACROS.xlsx" # Asegúrate de que termine en .xlsx
archivo_salida  <- "Encuesta_Universidad_Aleatoria.xlsx"

# 3. Fijar semilla global para que tu aleatorización sea reproducible por ti
set.seed(2026)

# 4. Obtener los nombres de todas las hojas existentes en el archivo
hojas <- excel_sheets(archivo_entrada)

# 5. Crear un nuevo libro de Excel en blanco en la memoria de R
nuevo_libro <- createWorkbook()

# 6. Función robusta para mezclar una columna manteniendo NAs y vacíos intactos
mezclar_columna <- function(columna) {
  # Detectar celdas con NA lógicos, strings vacíos o con puros espacios
  es_na <- is.na(columna) | columna == "" | trimws(as.character(columna)) == ""
  
  # Si la columna no tiene datos suficientes para mezclar, se devuelve intacta
  if (all(es_na) || sum(!es_na) <= 1) return(columna)
  
  # Extraer solo celdas válidas y barajarlas de forma equiprobable
  valores_validos <- columna[!es_na]
  valores_mezclados <- sample(valores_validos)
  
  # Construir el vector nuevo respetando las posiciones originales de las celdas vacías
  columna_nueva <- columna
  columna_nueva[!es_na] <- valores_mezclados
  
  return(columna_nueva)
}

# Ciclo principal corregido y optimizado para tus nombres de pestañas
for (i in seq_along(hojas)) {
  hoja_actual <- hojas[i]
  message(paste("Procesando y barajando la hoja [", i, "]:", hoja_actual))
  
  # 1. Leer la hoja actual con tipos de datos sugeridos
  datos_hoja <- read_excel(archivo_entrada, sheet = hoja_actual, guess_max = 2000)
  
  # 2. Identificar qué columnas barajar (protegiendo tu columna 'num')
  columnas_a_mezclar <- setdiff(names(datos_hoja), c("num", "id"))
  
  # 3. Barajar cada columna de manera independiente
  for (col in columnas_a_mezclar) {
    datos_hoja[[col]] <- mezclar_columna(datos_hoja[[col]])
  }
  
  # 4. Añadir la hoja al libro usando su nombre real
  addWorksheet(nuevo_libro, sheetName = hoja_actual)
  
  # 5. ESCRIBIR USANDO EL ÍNDICE NUMÉRICO (i) - Esto evita errores en openxlsx
  writeData(nuevo_libro, sheet = i, x = datos_hoja, keepNA = FALSE)
}
# 8. Guardar físicamente el nuevo libro con todas las hojas mezcladas
saveWorkbook(nuevo_libro, archivo_salida, overwrite = TRUE)

cat("\n¡Felicidades! Se ha generado exitosamente el libro completo mezclado hoja por hoja.\n")
