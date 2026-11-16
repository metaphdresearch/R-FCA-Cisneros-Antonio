# =========================================================================
# PIPELINE LIGERO DE TAMIZACIÓN UNIVARIADA (DATAEXPLORER)
# =========================================================================

# -------------------------------------------------------------------------
# FASE 0: INFRAESTRUCTURA MÍNIMA DE LIBRERÍAS
# -------------------------------------------------------------------------
options(timeout = 300)
paquetes_requeridos <- c("readxl", "dplyr", "DataExplorer", "rstudioapi")

cat("--- Verificando librerías esenciales ---\n")
for (pkg in paquetes_requeridos) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste("Instalando librería faltante:", pkg, "\n"))
    install.packages(pkg, dependencies = TRUE, repos = "https://r-project.org", type = "binary")
    library(pkg, character.only = TRUE)
  }
}

# -------------------------------------------------------------------------
# FASE 1: DETECCIÓN AUTOMÁTICA EN EL WORKING DIRECTORY Y CONSOLIDACIÓN
# -------------------------------------------------------------------------

# Fijar automáticamente el directorio donde está guardado este script
if (rstudioapi::isAvailable()) {
  ruta_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(ruta_script)) setwd(dirname(ruta_script))
}
cat("Carpeta de trabajo activa (lectura y guardado):", getwd(), "\n")

# Buscar el Excel priorizando "Encuesta_Universidad_Aleatoria" (ignorando temporales ~$)
archivos_excel <- list.files(pattern = "^[^~].*\\.xlsx$", ignore.case = TRUE)

if (length(archivos_excel) == 0) {
  stop("ERROR: No se encontró ningún archivo .xlsx en esta carpeta.")
} else {
  #NOMBRE DEL ARCHIVO DE LA BASE DE EXCEL AQUÍ:
  coincidencia <- grep("Encuesta_Universidad_Aleatoria", archivos_excel, ignore.case = TRUE, value = TRUE)
  ruta_excel <- if (length(coincidencia) > 0) coincidencia else archivos_excel
}

cat(paste("Archivo Excel vinculado:", ruta_excel, "\n"))

# Importación de hojas
cat("\n--- Importando hojas del Excel ---\n")
h1_nominales    <- as.data.frame(read_excel(ruta_excel, sheet = "Hog_1_Nominales_Puros"))
h2_escalas      <- as.data.frame(read_excel(ruta_excel, sheet = "Hog_2_Ordinales_Escalas"))
h3_binarios     <- as.data.frame(read_excel(ruta_excel, sheet = "Hog_3_Binarios_Retos"))
h4_numericos    <- as.data.frame(read_excel(ruta_excel, sheet = "Hog_4_Numericos_Puros"))
h5_desempleo    <- as.data.frame(read_excel(ruta_excel, sheet = "Hog_5_Diagnostico_Desempleo"))
h6_inactivos_fs <- as.data.frame(read_excel(ruta_excel, sheet = "fsQCA_Caso_6B_Inactivos"))
h7_activos_fs   <- as.data.frame(read_excel(ruta_excel, sheet = "fsQCA_Caso_5A_Activos"))

# Consolidación de la matriz maestra
df_maestro_gigante <- h1_nominales %>%
  inner_join(h2_escalas, by = "num") %>%
  inner_join(h3_binarios, by = "num") %>%
  inner_join(h4_numericos, by = "num") %>%
  left_join(h5_desempleo, by = "num") %>%
  left_join(h6_inactivos_fs %>% select(num, OUTCOME_DESEMPLEO_CRITICO), by = "num") %>%
  left_join(h7_activos_fs %>% select(num, OUTCOME_EXITO_ECONOMICO), by = "num")

cat(paste("Matriz Consolidada:", nrow(df_maestro_gigante), "filas y", ncol(df_maestro_gigante), "columnas.\n"))

# -------------------------------------------------------------------------
# FASE 2: GENERACIÓN DEL REPORTE EN EL MISMO DIRECTORIO
# -------------------------------------------------------------------------
cat("\n--- Generando reporte HTML en la carpeta actual ---\n")

configuracion_blindada <- configure_report(
  add_introduce = TRUE, add_plot_intro = TRUE, add_plot_str = FALSE,
  add_plot_missing = TRUE, add_plot_histogram = TRUE, add_plot_density = FALSE,
  add_plot_qq = FALSE, add_plot_bar = TRUE, add_plot_correlation = FALSE,
  add_plot_prcomp = FALSE, add_plot_boxplot = FALSE, add_plot_scatterplot = FALSE
)

create_report(
  data = df_maestro_gigante %>% select(-num),
  output_file = "Reporte_DataExplorer.html",
  output_dir = getwd(), # Guarda directamente en la carpeta raíz
  report_title = "Diagnóstico Univariado Total",
  config = configuracion_blindada
)
