source("R/utils_downloads.R")
# Préparation : demandes de services citoyennes 311 à Montréal.
# Source officielle : Données Québec / Ville de Montréal,
# paquet CKAN 5866f832-676d-4b07-be6a-e99c21eb17e4.

library(dplyr)
library(jsonlite)
library(lubridate)
library(readr)
library(stringr)
library(tidyr)

find_project_root <- function(path = getwd()) {
  current <- normalizePath(path, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(current, "_quarto.yml"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Impossible de trouver la racine du projet contenant _quarto.yml.", call. = FALSE)
    }
    current <- parent
  }
}

clean_text <- function(x) {
  x <- str_squish(as.character(x))
  na_if(x, "")
}

parse_flag <- function(x) {
  suppressWarnings(as.integer(clean_text(x)))
}

stream_sample_non_information <- function(csv_url, sample_path, stream_summary_path, sample_size = 100000L, seed = 311L) {
  if (identical(Sys.getenv("DB_OFFLINE"), "true")) {
    download_source(csv_url, sample_path)
    download_source(csv_url, stream_summary_path)
    return(invisible(NULL))
  }
  acquisition_started <- source_timestamp()
  python <- Sys.which("python3")
  if (identical(python, "")) {
    stop("python3 est requis pour échantillonner le gros CSV 311 en flux.", call. = FALSE)
  }

  helper <- tempfile(fileext = ".py")
  writeLines(
    c(
      "import csv, io, os, random, sys, time",
      "from urllib.request import Request, urlopen",
      "",
      "csv_url = sys.argv[1]",
      "sample_path = sys.argv[2]",
      "summary_path = sys.argv[3]",
      "sample_size = int(sys.argv[4])",
      "seed = int(sys.argv[5])",
      "",
      "os.makedirs(os.path.dirname(sample_path), exist_ok=True)",
      "rng = random.Random(seed)",
      "reservoir = []",
      "fieldnames = None",
      "total_rows = 0",
      "non_information_rows = 0",
      "counts = {}",
      "min_date = None",
      "max_date = None",
      "start = time.time()",
      "",
      "request = Request(csv_url, headers={'User-Agent': 'Mozilla/5.0'})",
      "with urlopen(request, timeout=240) as response:",
      "    text = io.TextIOWrapper(response, encoding='utf-8', newline='')",
      "    reader = csv.DictReader(text)",
      "    fieldnames = reader.fieldnames",
      "    for row in reader:",
      "        total_rows += 1",
      "        nature = row.get('NATURE') or ''",
      "        counts[nature] = counts.get(nature, 0) + 1",
      "        date = row.get('DDS_DATE_CREATION') or ''",
      "        if date:",
      "            if min_date is None or date < min_date:",
      "                min_date = date",
      "            if max_date is None or date > max_date:",
      "                max_date = date",
      "        if nature != 'Information':",
      "            non_information_rows += 1",
      "            if len(reservoir) < sample_size:",
      "                reservoir.append(row)",
      "            else:",
      "                j = rng.randrange(non_information_rows)",
      "                if j < sample_size:",
      "                    reservoir[j] = row",
      "",
      "with open(sample_path, 'w', encoding='utf-8', newline='') as handle:",
      "    writer = csv.DictWriter(handle, fieldnames=fieldnames)",
      "    writer.writeheader()",
      "    writer.writerows(reservoir)",
      "",
      "with open(summary_path, 'w', encoding='utf-8', newline='') as handle:",
      "    writer = csv.writer(handle)",
      "    writer.writerow(['metric', 'value'])",
      "    writer.writerow(['total_rows_streamed', total_rows])",
      "    writer.writerow(['non_information_rows', non_information_rows])",
      "    writer.writerow(['information_rows', counts.get('Information', 0)])",
      "    writer.writerow(['sample_rows', len(reservoir)])",
      "    writer.writerow(['min_date_creation', min_date])",
      "    writer.writerow(['max_date_creation', max_date])",
      "    writer.writerow(['elapsed_seconds', round(time.time() - start, 1)])",
      "    for key, value in sorted(counts.items()):",
      "        writer.writerow(['nature_count_' + (key or 'missing'), value])"
    ),
    helper,
    useBytes = TRUE
  )

  result <- system2(
    python,
    args = c(helper, csv_url, sample_path, stream_summary_path, as.character(sample_size), as.character(seed))
  )
  if (!identical(result, 0L)) {
    stop("L'échantillonnage en flux du CSV 311 a échoué.", call. = FALSE)
  }
  for (path in c(sample_path, stream_summary_path)) {
    record_source(path, csv_url, kind = "stream_reservoir_sample",
                  started_at = acquisition_started,
                  details = list(seed = seed, sample_size = sample_size,
                    selection = "NATURE différente de Information; échantillonnage réservoir uniforme",
                    hash_scope = "Fichier dérivé conservé; CSV source complet non conservé"))
  }
}

root <- find_project_root()
raw_dir <- file.path(root, "data/raw/requetes-311")
processed_dir <- file.path(root, "data/processed/requetes-311")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- Sys.Date()
source_page <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-requete-311"
source_api <- "https://www.donneesquebec.ca/recherche/api/3/action/package_show?id=vmtl-requete-311"

package_json_path <- file.path(raw_dir, "package_show_requetes_311.json")
sample_raw_path <- file.path(raw_dir, "requetes311_non_information_reservoir_100000.csv")
stream_summary_raw_path <- file.path(raw_dir, "requetes311_stream_summary.csv")

download_source(source_api, package_json_path, mode = "wb", quiet = TRUE)
package <- fromJSON(package_json_path, flatten = TRUE)
if (!isTRUE(package$success)) {
  stop("L'API CKAN n'a pas retourné success = TRUE.", call. = FALSE)
}

resources <- package$result$resources |>
  transmute(
    resource_id = id,
    resource_name = name,
    format = toupper(format),
    url = url,
    last_modified = as.character(last_modified),
    metadata_modified = as.character(metadata_modified),
    size = suppressWarnings(as.numeric(size))
  )

csv_url <- resources |>
  filter(format == "CSV", str_detect(resource_name, "2022")) |>
  pull(url)

if (length(csv_url) != 1L) {
  stop("Impossible d'identifier de façon unique la ressource CSV 2022 à ce jour.", call. = FALSE)
}

stream_sample_non_information(
  csv_url = csv_url,
  sample_path = sample_raw_path,
  stream_summary_path = stream_summary_raw_path,
  sample_size = 100000L,
  seed = 311L
)

source_sample <- read_csv(
  sample_raw_path,
  col_types = cols(.default = col_character()),
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

stream_summary <- read_csv(
  stream_summary_raw_path,
  col_types = cols(metric = col_character(), value = col_character()),
  show_col_types = FALSE
)

summary_value <- function(metric) {
  stream_summary$value[match(metric, stream_summary$metric)]
}

required_columns <- c(
  "ID_UNIQUE",
  "NATURE",
  "ACTI_NOM",
  "TYPE_LIEU_INTERV",
  "RUE",
  "ARRONDISSEMENT",
  "ARRONDISSEMENT_GEO",
  "DDS_DATE_CREATION",
  "PROVENANCE_ORIGINALE",
  "PROVENANCE_TELEPHONE",
  "PROVENANCE_COURRIEL",
  "PROVENANCE_PERSONNE",
  "PROVENANCE_COURRIER",
  "PROVENANCE_MOBILE",
  "PROVENANCE_MEDIASOCIAUX",
  "PROVENANCE_SITEINTERNET",
  "UNITE_RESP_PARENT",
  "LOC_LONG",
  "LOC_LAT",
  "DERNIER_STATUT",
  "DATE_DERNIER_STATUT"
)

missing_columns <- setdiff(required_columns, names(source_sample))
if (length(missing_columns) > 0L) {
  stop("Champs source absents : ", paste(missing_columns, collapse = ", "), call. = FALSE)
}

requetes <- source_sample |>
  transmute(
    id_unique = clean_text(ID_UNIQUE),
    nature = clean_text(NATURE),
    activite = clean_text(ACTI_NOM),
    type_lieu_intervention = clean_text(TYPE_LIEU_INTERV),
    rue = clean_text(RUE),
    arrondissement = clean_text(ARRONDISSEMENT),
    arrondissement_geo = clean_text(ARRONDISSEMENT_GEO),
    date_creation = ymd_hms(DDS_DATE_CREATION, quiet = TRUE),
    annee_creation = year(date_creation),
    mois_creation = floor_date(date_creation, "month"),
    provenance_originale = clean_text(PROVENANCE_ORIGINALE),
    provenance_telephone = parse_flag(PROVENANCE_TELEPHONE),
    provenance_courriel = parse_flag(PROVENANCE_COURRIEL),
    provenance_personne = parse_flag(PROVENANCE_PERSONNE),
    provenance_courrier = parse_flag(PROVENANCE_COURRIER),
    provenance_mobile = parse_flag(PROVENANCE_MOBILE),
    provenance_mediasociaux = parse_flag(PROVENANCE_MEDIASOCIAUX),
    provenance_siteinternet = parse_flag(PROVENANCE_SITEINTERNET),
    unite_responsable_parent = clean_text(UNITE_RESP_PARENT),
    longitude = parse_number(LOC_LONG, locale = locale(decimal_mark = ".")),
    latitude = parse_number(LOC_LAT, locale = locale(decimal_mark = ".")),
    coordonnees_disponibles = !is.na(longitude) & !is.na(latitude),
    dernier_statut = clean_text(DERNIER_STATUT),
    date_dernier_statut = ymd_hms(DATE_DERNIER_STATUT, quiet = TRUE),
    delai_statut_jours = as.numeric(difftime(date_dernier_statut, date_creation, units = "days")),
    source_csv_url = csv_url,
    sample_method = "Échantillon réservoir déterministe de 100 000 lignes non-Information, seed 311",
    access_date = access_date
  ) |>
  arrange(date_creation, id_unique)

summary_by_nature <- requetes |>
  count(nature, name = "n_demandes") |>
  mutate(pct_demandes = round(100 * n_demandes / sum(n_demandes), 1)) |>
  arrange(desc(n_demandes), nature)

summary_by_activity <- requetes |>
  count(activite, name = "n_demandes") |>
  mutate(pct_demandes = round(100 * n_demandes / sum(n_demandes), 1)) |>
  arrange(desc(n_demandes), activite)

summary_by_arrondissement <- requetes |>
  count(arrondissement, name = "n_demandes") |>
  mutate(pct_demandes = round(100 * n_demandes / sum(n_demandes), 1)) |>
  arrange(desc(n_demandes), arrondissement)

summary_by_status <- requetes |>
  count(dernier_statut, name = "n_demandes") |>
  mutate(pct_demandes = round(100 * n_demandes / sum(n_demandes), 1)) |>
  arrange(desc(n_demandes), dernier_statut)

summary_by_provenance <- requetes |>
  count(provenance_originale, name = "n_demandes") |>
  mutate(pct_demandes = round(100 * n_demandes / sum(n_demandes), 1)) |>
  arrange(desc(n_demandes), provenance_originale)

summary_by_year <- requetes |>
  count(annee_creation, name = "n_demandes") |>
  mutate(pct_demandes = round(100 * n_demandes / sum(n_demandes), 1)) |>
  arrange(annee_creation)

summary_by_month <- requetes |>
  count(mois_creation, name = "n_demandes") |>
  mutate(pct_demandes = round(100 * n_demandes / sum(n_demandes), 2)) |>
  arrange(mois_creation)

missing_summary <- requetes |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "n_missing"
  ) |>
  mutate(
    n_rows = nrow(requetes),
    pct_missing = round(100 * n_missing / n_rows, 2)
  ) |>
  arrange(desc(n_missing), variable)

dataset_summary <- tibble::tibble(
  metric = c(
    "source_page",
    "source_api",
    "csv_url",
    "access_date",
    "package_id",
    "metadata_modified",
    "csv_resource_last_modified",
    "csv_resource_metadata_modified",
    "csv_resource_size",
    "license_title",
    "n_resources_ckan",
    "n_csv_resources",
    "n_rows_streamed_recent_resource",
    "n_information_rows_recent_resource",
    "n_non_information_rows_recent_resource",
    "n_sample_rows",
    "n_columns_source_sample",
    "n_rows_prepared",
    "n_columns_prepared",
    "min_date_creation_sample",
    "max_date_creation_sample",
    "n_natures_sample",
    "n_activities_sample",
    "n_arrondissements_sample",
    "n_arrondissements_geo_sample",
    "n_status_sample",
    "n_provenances_sample",
    "n_rows_with_coordinates",
    "pct_rows_with_coordinates",
    "sample_seed",
    "sample_method"
  ),
  value = c(
    source_page,
    source_api,
    csv_url,
    as.character(access_date),
    package$result$id,
    as.character(package$result$metadata_modified),
    as.character(resources$last_modified[resources$url == csv_url]),
    as.character(resources$metadata_modified[resources$url == csv_url]),
    as.character(resources$size[resources$url == csv_url]),
    as.character(package$result$license_title),
    as.character(nrow(resources)),
    as.character(sum(resources$format == "CSV")),
    summary_value("total_rows_streamed"),
    summary_value("information_rows"),
    summary_value("non_information_rows"),
    as.character(nrow(source_sample)),
    as.character(ncol(source_sample)),
    as.character(nrow(requetes)),
    as.character(ncol(requetes)),
    as.character(min(requetes$date_creation, na.rm = TRUE)),
    as.character(max(requetes$date_creation, na.rm = TRUE)),
    as.character(n_distinct(requetes$nature, na.rm = TRUE)),
    as.character(n_distinct(requetes$activite, na.rm = TRUE)),
    as.character(n_distinct(requetes$arrondissement, na.rm = TRUE)),
    as.character(n_distinct(requetes$arrondissement_geo, na.rm = TRUE)),
    as.character(n_distinct(requetes$dernier_statut, na.rm = TRUE)),
    as.character(n_distinct(requetes$provenance_originale, na.rm = TRUE)),
    as.character(sum(requetes$coordonnees_disponibles, na.rm = TRUE)),
    as.character(round(100 * mean(requetes$coordonnees_disponibles, na.rm = TRUE), 2)),
    "311",
    "Échantillon réservoir déterministe de 100 000 lignes non-Information"
  )
)

stopifnot(
  nrow(resources) == 6,
  sum(resources$format == "CSV") == 5,
  as.numeric(summary_value("total_rows_streamed")) > 2000000,
  as.numeric(summary_value("non_information_rows")) > 1000000,
  nrow(source_sample) == 100000,
  ncol(source_sample) == 29,
  nrow(requetes) == 100000,
  ncol(requetes) == 28,
  n_distinct(requetes$nature, na.rm = TRUE) == 3,
  n_distinct(requetes$activite, na.rm = TRUE) > 500,
  sum(requetes$coordonnees_disponibles, na.rm = TRUE) > 99000
)

write_csv(resources, file.path(processed_dir, "ressources_ckan_requetes_311.csv"))
write_csv(stream_summary, file.path(processed_dir, "resume_flux_requetes_311.csv"))
write_csv(requetes, file.path(processed_dir, "requetes_311_non_information_echantillon.csv"))
write_csv(summary_by_nature, file.path(processed_dir, "resume_nature_echantillon.csv"))
write_csv(summary_by_activity, file.path(processed_dir, "resume_activites_echantillon.csv"))
write_csv(summary_by_arrondissement, file.path(processed_dir, "resume_arrondissements_echantillon.csv"))
write_csv(summary_by_status, file.path(processed_dir, "resume_statuts_echantillon.csv"))
write_csv(summary_by_provenance, file.path(processed_dir, "resume_provenances_echantillon.csv"))
write_csv(summary_by_year, file.path(processed_dir, "resume_annees_echantillon.csv"))
write_csv(summary_by_month, file.path(processed_dir, "resume_mois_echantillon.csv"))
write_csv(missing_summary, file.path(processed_dir, "valeurs_manquantes_echantillon.csv"))
write_csv(dataset_summary, file.path(processed_dir, "resume_requetes_311_echantillon.csv"))

record_preparation("requetes-311")
