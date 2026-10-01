# Maisons du Québec, version 1.0.0 : première municipalité, Québec.
# Exécuter depuis la racine du projet. Source MAMH sous CC BY 4.0.
# Le XML est lu par blocs pour éviter de charger tout le rôle en mémoire.
library(xml2)
library(readr)
library(dplyr)
library(tidyr)
library(digest)
library(jsonlite)
source("R/utils_downloads.R")

id <- "maisons-quebec"
raw_dir <- file.path("data/raw", id)
processed_dir <- file.path("data/processed", id)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
index_url <- "https://donneesouvertes.affmunqc.net/role/indexRole2026.csv"
index_path <- file.path(raw_dir, "indexRole2026.csv")
download_source(index_url, index_path)
index <- read_csv(index_path, col_types = cols(.default = col_character()),
                  show_col_types = FALSE)
territoire <- index |> filter(.data[["code géographique"]] == "23027")
stopifnot(nrow(territoire) == 1L, territoire[["nom du territoire"]] == "Québec")
xml_url <- territoire$lien
stopifnot(identical(xml_url, "https://donneesouvertes.affmunqc.net/role/RL23027_2026.xml"))
xml_path <- file.path(raw_dir, "role_quebec_2026.xml")
download_source(xml_url, xml_path)
# La ressource source peut être remplacée. Une autre empreinte exige une nouvelle version.
expected_sha <- "971896db6bf6bcae5a711bbd4b2b33f945b770d237bd4164d8f4f5cd54feff9a"
actual_sha <- digest(xml_path, file = TRUE, algo = "sha256")
if (!identical(actual_sha, expected_sha)) {
  stop("Le rôle téléchargé a changé. Ne pas l'étiqueter version 1.0.0; réviser la sélection.")
}

header_lines <- readLines(xml_path, n = 100L, warn = FALSE, encoding = "UTF-8")
first_unit <- which(trimws(header_lines) == "<RLUEx>")[1]
stopifnot(!is.na(first_unit))
header <- read_xml(paste(c(header_lines[seq_len(first_unit - 1L)], "</RL>"), collapse = "\n"))
header_field <- function(tag) xml_text(xml_find_first(header, paste0("./", tag)))
stopifnot(header_field("VERSION") == "2.6", header_field("RLM01A") == "23027",
          header_field("RLM02A") == "2025")

# Une ligne par unité, uniquement les champs utiles à l'enseignement.
# Aucune adresse, aucun cadastre, matricule ou renseignement de propriétaire n'est exporté.
field_names <- c(arrondissement_code = "RL0102A", usage_code = "RL0105A",
  voisinage_code = "RL0107A", superficie_terrain_m2 = "RL0302A",
  nombre_etages_max = "RL0306A", annee_construction = "RL0307A",
  annee_construction_statut_code = "RL0307B", aire_etages_m2 = "RL0308A",
  lien_physique_code = "RL0309A", genre_construction_code = "RL0310A",
  nombre_logements = "RL0311A", date_reference_marche = "RL0401A",
  valeur_terrain_cad = "RL0402A", valeur_batiment_cad = "RL0403A",
  valeur_fonciere_cad = "RL0404A")

read_units <- function(path, n_lines = 25000L) {
  connection <- file(path, open = "rt", encoding = "UTF-8")
  on.exit(close(connection))
  carry <- character(); batches <- list(); n_read <- 0L; n_batch <- 0L
  repeat {
    incoming <- readLines(connection, n = n_lines, warn = FALSE)
    if (!length(incoming)) break
    lines <- c(carry, incoming)
    trimmed <- trimws(lines)
    ends <- which(trimmed == "</RLUEx>")
    if (!length(ends)) { carry <- lines; next }
    last_end <- max(ends)
    first_start <- which(trimmed == "<RLUEx>")[1]
    stopifnot(!is.na(first_start), first_start < last_end)
    batch <- read_xml(paste(c("<batch>", lines[first_start:last_end], "</batch>"),
                            collapse = "\n"), options = "NOBLANKS")
    nodes <- xml_find_all(batch, "./RLUEx")
    values <- lapply(field_names, function(tag) {
      value <- xml_text(xml_find_first(nodes, paste0("./", tag)))
      value[is.na(value) | value == ""] <- NA_character_
      value
    })
    n <- length(nodes)
    n_batch <- n_batch + 1L
    batches[[n_batch]] <- as_tibble(values) |>
      mutate(ligne_source = n_read + seq_len(n), .before = 1)
    n_read <- n_read + n
    carry <- if (last_end < length(lines)) lines[(last_end + 1L):length(lines)] else character()
  }
  if (any(grepl("RLUEx", carry, fixed = TRUE))) stop("Unité XML incomplète en fin de source.")
  bind_rows(batches)
}

units <- read_units(xml_path)
stopifnot(nrow(units) == 175478L, !anyDuplicated(units$ligne_source))
numeric_columns <- c("superficie_terrain_m2", "nombre_etages_max", "annee_construction",
  "aire_etages_m2", "nombre_logements", "valeur_terrain_cad", "valeur_batiment_cad",
  "valeur_fonciere_cad")
units <- units |> mutate(across(all_of(numeric_columns), as.numeric))

# Filtres structurels successifs. Pas de sélection selon le prix, les superficies ou l'âge.
# Le lien physique 5 correspond aux unités intégrées en copropriété; il est exclu.
# Le genre 3 correspond à une maison unimodulaire; il est exclu, les genres inconnus restent.
step1 <- units |> filter(usage_code == "1000", nombre_logements == 1)
step2 <- step1 |> filter(lien_physique_code %in% as.character(1:4))
eligible <- step2 |> filter(is.na(genre_construction_code) | genre_construction_code != "3")
stopifnot(nrow(eligible) >= 600L,
          all(eligible$date_reference_marche == "2023-07-01"),
          !anyDuplicated(eligible$ligne_source))

# Sondage aléatoire simple sans remise, dans l'ordre source de l'instantané épinglé.
# R >= 3.6 et type de générateur explicités pour reproduire la sélection.
RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
set.seed(20261001)
sample_index <- sort(sample.int(nrow(eligible), 600L, replace = FALSE))
selection <- eligible[sample_index, ]
houses <- selection |>
  mutate(maison_id = sprintf("MQ-%04d", row_number()), .before = 1) |>
  mutate(municipalite = "Québec", annee_role = 2025L, annee_extraction = 2026L,
    lien_physique = recode(lien_physique_code, `1` = "Détaché", `2` = "Jumelé",
      `3` = "En rangée, un côté", `4` = "En rangée, plusieurs côtés"),
    annee_construction_statut = recode(annee_construction_statut_code,
      R = "Réelle", E = "Estimée")) |>
  select(maison_id, municipalite, arrondissement_code, voisinage_code,
    superficie_terrain_m2, aire_etages_m2, nombre_etages_max, annee_construction,
    annee_construction_statut, lien_physique_code, lien_physique,
    genre_construction_code, nombre_logements, valeur_terrain_cad,
    valeur_batiment_cad, valeur_fonciere_cad, date_reference_marche,
    annee_role, annee_extraction)
stopifnot(nrow(houses) == 600L, ncol(houses) == 19L,
  !anyDuplicated(houses$maison_id), all(houses$nombre_logements == 1))
sum_known <- houses |> filter(!is.na(valeur_terrain_cad), !is.na(valeur_batiment_cad))
stopifnot(all(sum_known$valeur_fonciere_cad ==
               sum_known$valeur_terrain_cad + sum_known$valeur_batiment_cad))

stages <- tibble(etape = c("Toutes les unités du XML", "Usage 1000 et un logement",
  "Lien physique 1 à 4", "Exclusion du genre unimodulaire 3", "Échantillon sans remise"),
  effectif = c(nrow(units), nrow(step1), nrow(step2), nrow(eligible), nrow(houses)))
quality <- houses |> summarise(across(everything(), ~sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_manquants")
provenance <- tibble(maison_id = houses$maison_id, ligne_source = selection$ligne_source,
  source_sha256 = actual_sha, code_geographique = "23027",
  probabilite_inclusion = 600 / nrow(eligible), graine = 20261001L)
write_csv(houses, file.path(processed_dir, "maisons_quebec.csv"), na = "NA")
write_csv(stages, file.path(processed_dir, "selection.csv"))
write_csv(quality, file.path(processed_dir, "qualite.csv"))
write_csv(provenance, file.path(processed_dir, "provenance_lignes.csv"))
write_json(list(version = "1.0.0", xml_version = "2.6", dictionary_version = "2.5",
  dictionary_note = "Dictionnaire public 2.5 (2022), définitions des champs retenus. Le XML 2.6 n'est pas certifié contre un schéma XSD 2.6.",
  sample_seed = 20261001L, sample_kind = "Rejection", sample_size = 600L,
  eligible_population = nrow(eligible), date_reference = "2023-07-01",
  source_sha256 = actual_sha, stages = stages, missing = quality,
  nonpositive_area = sum(houses$aire_etages_m2 <= 0, na.rm = TRUE),
  nonpositive_land_area = sum(houses$superficie_terrain_m2 <= 0, na.rm = TRUE),
  nonpositive_value = sum(houses$valeur_fonciere_cad <= 0, na.rm = TRUE)),
  file.path(processed_dir, "selection.json"), auto_unbox = TRUE, pretty = TRUE)
record_preparation(id)
print(stages)
print(quality |> filter(n_manquants > 0))
message("600 maisons, 19 colonnes; aucune imputation, aucun ajustement des valeurs sources.")
