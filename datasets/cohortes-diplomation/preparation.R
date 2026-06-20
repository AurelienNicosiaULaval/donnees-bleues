# Préparer l'indicateur ISQ d'écart de diplomation selon l'IMSE.

library(dplyr)
library(readr)
library(readxl)

dir.create("data/raw/cohortes-diplomation", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/cohortes-diplomation", recursive = TRUE, showWarnings = FALSE)

source_url <- "https://statistique.quebec.ca/api/fr/produit/graphique/ecart-diplomation-selon-milieu-socio-economique/export"
raw_path <- "data/raw/cohortes-diplomation/ecart_diplomation_imse.xlsx"
processed_path <- "data/processed/cohortes-diplomation/ecart_diplomation_imse.csv"

download.file(source_url, raw_path, mode = "wb", quiet = TRUE)

diplomation_raw <- read_excel(raw_path, col_names = FALSE, .name_repair = "minimal")
names(diplomation_raw) <- paste0("col", seq_along(diplomation_raw))

diplomation_rows <- diplomation_raw |>
  filter(grepl("^\\d{4}-\\d{4}$", as.character(col1)))

if (nrow(diplomation_rows) == 0L) {
  stop("Aucune année scolaire de fin de suivi détectée dans l'export ISQ.", call. = FALSE)
}

diplomation <- diplomation_rows |>
  setNames(c(
    "annee_scolaire_fin_suivi",
    "taux_diplomation_decile_imse_1",
    "taux_diplomation_decile_imse_10",
    "ecart_points_pourcentage"
  )) |>
  mutate(
    annee_debut_fin_suivi = as.integer(substr(annee_scolaire_fin_suivi, 1, 4)),
    cohorte_entree_secondaire = paste0(
      annee_debut_fin_suivi - 6,
      "-",
      annee_debut_fin_suivi - 5
    ),
    across(
      c(
        taux_diplomation_decile_imse_1,
        taux_diplomation_decile_imse_10,
        ecart_points_pourcentage
      ),
      ~ readr::parse_number(as.character(.x), locale = readr::locale(decimal_mark = "."))
    )
  ) |>
  select(
    cohorte_entree_secondaire,
    annee_scolaire_fin_suivi,
    taux_diplomation_decile_imse_1,
    taux_diplomation_decile_imse_10,
    ecart_points_pourcentage
  )

ecart_recalcule <- diplomation$taux_diplomation_decile_imse_1 -
  diplomation$taux_diplomation_decile_imse_10

if (any(abs(ecart_recalcule - diplomation$ecart_points_pourcentage) > 0.2, na.rm = TRUE)) {
  stop("L'écart publié ne correspond pas aux deux taux importés.", call. = FALSE)
}

write_csv(diplomation, processed_path)

message("Fichier brut : ", raw_path)
message("Fichier préparé : ", processed_path)
