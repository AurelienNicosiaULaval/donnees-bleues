# Préparation : Condamnations des établissements alimentaires au Québec
# Source officielle : Données Québec / MAPAQ
# Source pédagogique : UlavalSSD::listecondamnation

library(dplyr)
library(readr)
library(stringr)
library(UlavalSSD)

processed_dir <- "data/processed/condamnations-alimentaires-quebec"
processed_path <- file.path(processed_dir, "condamnations_alimentaires_quebec.csv")

dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

required_columns <- c(
  "Nom_exploitant",
  "Raison_sociale",
  "Description_infraction",
  "Adresse_lieu_infraction",
  "Type_etablissement",
  "Date_infraction",
  "Date_jugement",
  "Date_publication",
  "Amende",
  "SOC_NOM_ARTCL_INFRC"
)

missing_columns <- setdiff(required_columns, names(listecondamnation))
if (length(missing_columns) > 0L) {
  stop(
    "Colonnes absentes de UlavalSSD::listecondamnation : ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}

condamnations <- listecondamnation |>
  mutate(
    across(c(Date_infraction, Date_jugement, Date_publication), as.Date),
    amende_num = parse_number(Amende, locale = locale(grouping_mark = " ")),
    ville_montreal = str_detect(
      Adresse_lieu_infraction,
      regex("MONTREAL|MONTRÉAL", ignore_case = TRUE)
    ),
    delai_infraction_jugement_jours = as.integer(Date_jugement - Date_infraction),
    delai_jugement_publication_jours = as.integer(Date_publication - Date_jugement)
  )

if (any(is.na(condamnations$amende_num))) {
  stop("Certaines amendes n'ont pas pu être converties en valeurs numériques.", call. = FALSE)
}

if (any(condamnations$delai_infraction_jugement_jours < 0, na.rm = TRUE)) {
  stop("Au moins une date de jugement précède la date d'infraction.", call. = FALSE)
}

write_csv(condamnations, processed_path)

message("Version UlavalSSD : ", as.character(packageVersion("UlavalSSD")))
message("Lignes préparées : ", nrow(condamnations))
message("Colonnes préparées : ", ncol(condamnations))
message("Fichier préparé : ", processed_path)
