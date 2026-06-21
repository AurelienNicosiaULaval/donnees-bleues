# Préparation : Emploi régional au Québec
# Source officielle : Institut de la statistique du Québec, tableau 916.

library(dplyr)
library(purrr)
library(readr)
library(readxl)
library(stringr)
library(tidyr)

raw_dir <- "data/raw/emploi-regional-quebec"
processed_dir <- "data/processed/emploi-regional-quebec"
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

source_page <- "https://statistique.quebec.ca/fr/document/population-active-emploi-et-chomage-regions-administratives-rmr-et-quebec"
source_table <- "https://statistique.quebec.ca/fr/produit/tableau/caracteristiques-du-marche-du-travail-donnees-mensuelles-desaisonnalisees-regions-administratives-et-ensemble-du-quebec"
source_file <- "https://statistique.quebec.ca/docs-ken/multimedia/Fichier_complet_916.xlsx"

raw_path <- file.path(raw_dir, "Fichier_complet_916.xlsx")
processed_path <- file.path(processed_dir, "emploi_regional_quebec.csv")

download.file(source_file, raw_path, mode = "wb", quiet = TRUE)

month_levels <- c(
  "Janvier" = 1,
  "Février" = 2,
  "Mars" = 3,
  "Avril" = 4,
  "Mai" = 5,
  "Juin" = 6,
  "Juillet" = 7,
  "Août" = 8,
  "Septembre" = 9,
  "Octobre" = 10,
  "Novembre" = 11,
  "Décembre" = 12
)

month_pattern <- paste0(
  "^(",
  paste(names(month_levels), collapse = "|"),
  ")\\s+\\d{4}"
)

parse_mixed_number <- function(x) {
  clean <- x |>
    str_squish() |>
    str_remove_all("[FrR*]")

  out <- rep(NA_real_, length(clean))
  uses_comma <- clean != "" & str_detect(clean, ",") & !str_detect(clean, "\\.")
  uses_dot <- clean != "" & !uses_comma

  out[uses_comma] <- parse_number(clean[uses_comma], locale = locale(decimal_mark = ","))
  out[uses_dot] <- parse_number(clean[uses_dot], locale = locale(decimal_mark = "."))

  out
}

parse_indicator_sheet <- function(path, sheet) {
  raw <- read_excel(
    path,
    sheet = sheet,
    col_names = FALSE,
    col_types = "text",
    .name_repair = "minimal"
  )

  territories <- raw[5, -1] |>
    unlist(use.names = FALSE) |>
    as.character() |>
    str_remove("^\\.+") |>
    str_squish()

  units <- raw[6, -1] |>
    unlist(use.names = FALSE) |>
    as.character() |>
    str_squish()

  names(raw) <- c("periode_source", paste0("v", seq_len(ncol(raw) - 1)))

  raw[-(1:6), ] |>
    filter(str_detect(periode_source, month_pattern)) |>
    pivot_longer(
      cols = -periode_source,
      names_to = "colonne",
      values_to = "valeur_brute"
    ) |>
    mutate(col_index = as.integer(str_remove(colonne, "^v"))) |>
    filter(
      col_index <= length(territories),
      !is.na(territories[col_index])
    ) |>
    transmute(
      indicateur = sheet,
      periode_source = str_squish(periode_source),
      mois_nom = str_squish(str_match(periode_source, "^(.*?)\\s*(\\d{4})(.*)$")[, 2]),
      annee = as.integer(str_match(periode_source, "^(.*?)\\s*(\\d{4})(.*)$")[, 3]),
      mois = unname(month_levels[mois_nom]),
      date = as.Date(sprintf("%04d-%02d-01", annee, mois)),
      appel_note_periode = na_if(
        str_squish(str_match(periode_source, "^(.*?)\\s*(\\d{4})(.*)$")[, 4]),
        ""
      ),
      territoire = territories[col_index],
      unite = units[col_index],
      valeur_brute = str_squish(valeur_brute),
      indicateur_qualite = case_when(
        str_detect(valeur_brute, "F") ~ "F",
        str_detect(valeur_brute, "\\*") ~ "*",
        str_detect(valeur_brute, "r") ~ "r",
        TRUE ~ NA_character_
      ),
      valeur = parse_mixed_number(valeur_brute)
    )
}

indicator_sheets <- setdiff(excel_sheets(raw_path), "Notes")

emploi_regional <- map_dfr(
  indicator_sheets,
  \(sheet) parse_indicator_sheet(raw_path, sheet)
) |>
  arrange(indicateur, territoire, date)

stopifnot(
  nrow(emploi_regional) == 25160,
  n_distinct(emploi_regional$indicateur) == 8,
  n_distinct(emploi_regional$territoire) == 17,
  n_distinct(emploi_regional$date) == 185
)

write_csv(emploi_regional, processed_path)

message("Source : ", source_page)
message("Tableau retenu : ", source_table)
message("Fichier brut : ", raw_path)
message("Fichier préparé : ", processed_path)
