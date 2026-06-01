# Préparer les statistiques 2024 des bibliothèques publiques du Québec.

library(dplyr)
library(readr)
library(stringr)

dir.create("data/raw/bibliotheques-quebec", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed/bibliotheques-quebec", recursive = TRUE, showWarnings = FALSE)

data_url <- "https://www.donneesquebec.ca/recherche/dataset/231a38a8-f28e-4bef-82ea-dc98a14c1b6f/resource/01183d3e-c79c-4d09-915c-f35ffe4dfda8/download/statistiques_bibliotheques_quebec_2024.csv"
raw_path <- "data/raw/bibliotheques-quebec/statistiques_bibliotheques_quebec_2024.csv"

download.file(data_url, raw_path, mode = "wb", quiet = TRUE)

parse_number_fr <- function(x) {
  parse_number(
    as.character(x),
    locale = locale(decimal_mark = ",", grouping_mark = " ")
  )
}

bibliotheques_raw <- read_delim(
  raw_path,
  delim = ";",
  locale = locale(encoding = "UTF-8", decimal_mark = ","),
  show_col_types = FALSE
)

bibliotheques <- bibliotheques_raw |>
  transmute(
    bibliotheque = `Bibliothèque ou Centre régional`,
    region_administrative = `Région administrative`,
    population_desservie = parse_number_fr(`Population desservie`),
    categorie_bibliotheque = `Catégorie de la bibl.`,
    modalites_abonnement = `Modalités d'abonnement`,
    visites_total = parse_number_fr(`Visites (Total)`),
    prets_total = parse_number_fr(`Prêts / Tous les doc. (Total)`),
    usagers_inscrits_total = parse_number_fr(`Usagers inscrits (Total)`),
    activites_total = parse_number_fr(`Progr. / Toutes les activités (Total)`),
    depenses_fonctionnement_total = parse_number_fr(`Dép. fonct. / Toutes les dépenses ($)`)
  )

write_csv(bibliotheques, "data/processed/bibliotheques-quebec/statistiques_bibliotheques_quebec_2024_selection.csv")

message("Fichier préparé : data/processed/bibliotheques-quebec/statistiques_bibliotheques_quebec_2024_selection.csv")
