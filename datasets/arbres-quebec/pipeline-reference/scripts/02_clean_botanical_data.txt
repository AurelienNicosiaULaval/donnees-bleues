#!/usr/bin/env Rscript

# Construction de arbres_quebec.csv et arbres_quebec_small.csv.
# Aucune imputation. Les mesures observées et estimées restent distinctes.

required_packages <- c(
  "cli", "DBI", "digest", "dplyr", "fs", "janitor", "lubridate",
  "purrr", "readr", "readxl", "RSQLite", "sf", "stringr", "tibble",
  "tidyr"
)

source(file.path("R", "helpers_io.R"))
source(file.path("R", "helpers_validation.R"))
assert_packages(required_packages)
ensure_project_dirs(".")

suppressPackageStartupMessages({
  library(cli)
  library(DBI)
  library(dplyr)
  library(fs)
  library(janitor)
  library(lubridate)
  library(purrr)
  library(readr)
  library(readxl)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source_inventory <- toupper(Sys.getenv("ARBRES_QC_SOURCE", unset = "PET5"))
if (!source_inventory %in% c("PET5", "PET4", "PEP")) {
  stop("ARBRES_QC_SOURCE doit être PET5, PET4 ou PEP.", call. = FALSE)
}

overwrite_clean <- as_bool_env("OVERWRITE_CLEAN", FALSE)
if (!overwrite_clean && file.exists("data_clean/arbres_quebec_small.csv")) {
  stop("Sorties existantes : utiliser OVERWRITE_CLEAN=true pour reconstruire.", call. = FALSE)
}
small_n_species <- as_int_env("SMALL_N_SPECIES", 4L)
small_n_per_species_requested <- as_int_env("SMALL_N_PER_SPECIES", 50L)
small_seed <- as_int_env("SMALL_SEED", 20260625L)
max_rows <- as_int_env("MAX_ROWS_DEVELOPMENT", 0L)

if (small_n_species < 3L || small_n_species > 5L) {
  stop("SMALL_N_SPECIES doit être compris entre 3 et 5.", call. = FALSE)
}
if (small_n_per_species_requested < 1L) {
  stop("SMALL_N_PER_SPECIES doit être positif.", call. = FALSE)
}

raw_dir <- file.path("data_raw", source_inventory)
intermediate_dir <- file.path("data_intermediate", paste0(source_inventory, "_GPKG"))
dir_create(raw_dir, recurse = TRUE)
dir_create(intermediate_dir, recurse = TRUE)

zip_candidates <- list.files(
  raw_dir,
  pattern = paste0("^", source_inventory, "_GPKG\\.zip$"),
  full.names = TRUE,
  ignore.case = TRUE
)

if (length(zip_candidates) > 1L) {
  stop("Plusieurs archives GeoPackage candidates dans ", raw_dir, call. = FALSE)
}
if (length(zip_candidates) == 1L) {
  extract_zip_once(zip_candidates[[1]], intermediate_dir, overwrite = FALSE)
}

gpkg_candidates <- unique(c(
  list.files(raw_dir, pattern = "\\.gpkg$", recursive = TRUE,
             full.names = TRUE, ignore.case = TRUE),
  list.files(intermediate_dir, pattern = "\\.gpkg$", recursive = TRUE,
             full.names = TRUE, ignore.case = TRUE)
))
if (length(gpkg_candidates) != 1L) {
  stop(
    "Il faut exactement un GeoPackage pour ", source_inventory,
    ". Trouvés : ", length(gpkg_candidates),
    ". Exécuter d'abord scripts/01_collect_botanical_sources.R ou suivre les instructions manuelles.",
    call. = FALSE
  )
}
gpkg_path <- normalizePath(gpkg_candidates[[1]], winslash = "/", mustWork = TRUE)

dictionary_candidates <- list.files(
  raw_dir,
  pattern = "^DICTIONNAIRE_PLACETTE\\.xlsx$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
if (length(dictionary_candidates) != 1L) {
  stop("Dictionnaire XLSX absent ou ambigu dans ", raw_dir, call. = FALSE)
}
dictionary_path <- normalizePath(dictionary_candidates[[1]], winslash = "/",
                                 mustWork = TRUE)

cli_inform(c(
  "i" = paste0("Inventaire : ", source_inventory),
  "i" = paste0("GeoPackage : ", gpkg_path),
  "i" = paste0("Dictionnaire : ", dictionary_path),
  "i" = if (max_rows > 0L) paste0("Mode développement : LIMIT ", max_rows)
        else "Lecture complète demandée"
))

con <- DBI::dbConnect(
  RSQLite::SQLite(),
  dbname = gpkg_path,
  flags = RSQLite::SQLITE_RO
)
on.exit(DBI::dbDisconnect(con), add = TRUE)
all_tables <- DBI::dbListTables(con)

pick_table <- function(target) {
  index <- match(tolower(target), tolower(all_tables))
  if (is.na(index)) {
    stop(
      "Table requise absente : ", target,
      ". Tables disponibles : ", paste(all_tables, collapse = ", "),
      call. = FALSE
    )
  }
  all_tables[[index]]
}

read_selected <- function(target_table, wanted, required = character(), limit = 0L) {
  actual_table <- pick_table(target_table)
  actual_fields <- DBI::dbListFields(con, actual_table)
  field_map <- tibble(
    actual = actual_fields,
    clean = janitor::make_clean_names(actual_fields)
  )
  missing_required <- setdiff(required, field_map$clean)
  if (length(missing_required) > 0L) {
    stop(
      "Champs requis absents de ", actual_table, " : ",
      paste(missing_required, collapse = ", "), call. = FALSE
    )
  }
  selected <- field_map |> filter(clean %in% wanted)
  if (nrow(selected) == 0L) {
    stop("Aucun champ demandé trouvé dans ", actual_table, call. = FALSE)
  }
  sql <- paste0(
    "SELECT ",
    paste(DBI::dbQuoteIdentifier(con, selected$actual), collapse = ", "),
    " FROM ", DBI::dbQuoteIdentifier(con, actual_table),
    if (target_table %in% c("DENDRO_ARBRES", "DENDRO_ARBRES_ETUDES")) {
      paste0(" ORDER BY ", DBI::dbQuoteIdentifier(con,
        field_map$actual[match(if (source_inventory == "PEP") "id_arb_mes" else "id_arbre", field_map$clean)]))
    } else "",
    if (limit > 0L) paste0(" LIMIT ", as.integer(limit)) else ""
  )
  DBI::dbGetQuery(con, sql) |>
    janitor::clean_names()
}

ensure_columns <- function(data, columns) {
  for (column in columns) {
    if (!column %in% names(data)) data[[column]] <- NA
  }
  data
}

assert_unique_key <- function(data, key, label, allow_missing = FALSE) {
  key_values <- data[[key]]
  if (!allow_missing && any(is.na(key_values) | key_values == "")) {
    stop("Clé manquante dans ", label, " : ", key, call. = FALSE)
  }
  duplicated_nonmissing <- duplicated(key_values) & !is.na(key_values) & key_values != ""
  if (any(duplicated_nonmissing)) {
    stop("Clé non unique dans ", label, " : ", key, call. = FALSE)
  }
  invisible(TRUE)
}

read_code_sheet <- function(sheet) {
  raw <- readxl::read_excel(dictionary_path, sheet = sheet, skip = 2) |>
    janitor::clean_names()
  if (!all(c("code", "description") %in% names(raw))) {
    if (all(c("code", "nom") %in% names(raw))) {
      raw <- raw |> rename(description = nom)
    } else {
      stop("Structure inattendue de la feuille ", sheet, call. = FALSE)
    }
  }
  raw |>
    transmute(
      code = str_trim(as.character(code)),
      description = str_squish(as.character(description))
    ) |>
    filter(!is.na(code), code != "", !str_detect(code, regex("^retour", TRUE))) |>
    distinct(code, .keep_all = TRUE)
}

# Lecture des tables principales -------------------------------------------

tree_fields <- c(
  "id_pe", "id_pe_mes", "no_mes", "no_arbre", "id_arbre", "id_arb_mes",
  "etat", "essence", "in_ess_nc", "dhp", "dhp_nc", "cl_dhp", "in_1410",
  "cl_defol", "caus_defol", "defol_min", "defol_max", "cl_qual",
  "ensoleil", "etage_arb", "haut_arbre", "haut_esti", "age", "age_sansop",
  "source_age", "st_tige", "st_ha", "vmb_tige", "vmb_ha"
)
trees <- read_selected(
  "DENDRO_ARBRES", tree_fields,
  required = c("id_pe", "id_arbre", "essence", "dhp"),
  limit = max_rows
) |>
  ensure_columns(tree_fields)

study_fields <- c(
  "id_pe", "id_pe_mes", "no_mes", "no_arbre", "id_arbre", "id_arb_mes",
  "met_selec", "etat", "essence", "dhp", "haut_arbre", "age", "age_sansop",
  "source_age", "ensoleil", "etage_arb", "nivlectage"
)
study <- read_selected(
  "DENDRO_ARBRES_ETUDES", study_fields,
  required = c("id_pe", "id_arbre"),
  limit = if (max_rows > 0L) max_rows else 0L
) |>
  ensure_columns(study_fields)

plot_fields <- c(
  "id_pe", "no_prg", "no_prj", "no_viree", "no_pe", "type_pe", "reseau",
  "dimension", "feuillet", "latitude", "longitude", "date_sond", "statut_fin",
  "dern_sond"
)
plots <- read_selected(
  "PLACETTE", plot_fields,
  required = c("id_pe", "latitude", "longitude"),
  limit = 0L
) |>
  ensure_columns(plot_fields)

class_fields <- c(
  "id_pe", "zone_veg", "szone_veg", "dom_bio", "sdom_bio", "reg_eco",
  "sreg_eco", "upays_reg", "dis_eco"
)
ecology <- read_selected(
  "CLASSI_ECO_PE", class_fields,
  required = c("id_pe"),
  limit = 0L
) |>
  ensure_columns(class_fields)

plot_measure <- NULL
if (source_inventory == "PEP") {
  plot_measure_fields <- c(
    "id_pe", "no_mes", "id_pe_mes", "version", "dimension", "no_prj_mes",
    "date_sond", "statut_mes"
  )
  plot_measure <- read_selected(
    "PLACETTE_MES", plot_measure_fields,
    required = c("id_pe", "id_pe_mes", "date_sond"),
    limit = 0L
  ) |>
    ensure_columns(plot_measure_fields)
}

# Clés sous forme de texte pour éviter toute perte de précision -------------

id_columns <- c("id_pe", "id_pe_mes", "id_arbre", "id_arb_mes")
trees <- trees |> mutate(across(any_of(id_columns), as.character))
study <- study |> mutate(across(any_of(id_columns), as.character))
plots <- plots |> mutate(across(any_of(id_columns), as.character))
ecology <- ecology |> mutate(across(any_of(id_columns), as.character))
if (!is.null(plot_measure)) {
  plot_measure <- plot_measure |> mutate(across(any_of(id_columns), as.character))
}

assert_unique_key(plots, "id_pe", "PLACETTE")
assert_unique_key(ecology, "id_pe", "CLASSI_ECO_PE", allow_missing = TRUE)

join_key <- if (source_inventory == "PEP") "id_arb_mes" else "id_arbre"
if (source_inventory == "PEP" && all(is.na(trees$id_arb_mes))) {
  stop("PEP exige ID_ARB_MES dans DENDRO_ARBRES.", call. = FALSE)
}

study_reduced <- study |>
  transmute(
    study_join_key = .data[[join_key]],
    is_study_tree = TRUE,
    study_selection_method = as.character(met_selec),
    study_height_dm = safe_numeric(haut_arbre),
    study_age_years = safe_numeric(age),
    study_age_without_op = safe_numeric(age_sansop),
    study_age_source_code = as.character(source_age),
    study_age_reading_height_cm = safe_numeric(nivlectage),
    study_sunlight_code = as.character(ensoleil),
    study_canopy_stratum_code = as.character(etage_arb)
  ) |>
  filter(!is.na(study_join_key), study_join_key != "")
assert_unique_key(study_reduced, "study_join_key", "DENDRO_ARBRES_ETUDES")

if (source_inventory == "PEP") {
  assert_unique_key(plot_measure, "id_pe_mes", "PLACETTE_MES")
  plots_for_join <- plot_measure |>
    transmute(
      plot_measurement_id = id_pe_mes,
      plot_id = id_pe,
      survey_number = as.character(no_mes),
      measurement_date = safe_date(date_sond),
      measurement_status_code = as.character(statut_mes),
      measurement_protocol_version = as.character(version),
      plot_dimension_measurement = as.character(dimension)
    ) |>
    left_join(
      plots |>
        transmute(
          plot_id = id_pe,
          project_id = as.character(no_prj),
          transect_id = as.character(no_viree),
          plot_number = as.character(no_pe),
          plot_type = as.character(type_pe),
          source_network = as.character(reseau),
          map_sheet = as.character(feuillet),
          latitude = safe_numeric(latitude),
          longitude = safe_numeric(longitude),
          plot_status = as.character(statut_fin)
        ),
      by = "plot_id"
    )

  combined <- trees |>
    mutate(
      plot_id = id_pe,
      plot_measurement_id = id_pe_mes,
      record_id = id_arb_mes,
      tree_id = id_arbre,
      study_join_key = id_arb_mes
    ) |>
    left_join(study_reduced, by = "study_join_key") |>
    left_join(plots_for_join, by = c("plot_id", "plot_measurement_id"))
} else {
  plots_for_join <- plots |>
    transmute(
      plot_id = id_pe,
      plot_measurement_id = id_pe,
      project_id = as.character(no_prj),
      transect_id = as.character(no_viree),
      plot_number = as.character(no_pe),
      plot_type = as.character(type_pe),
      source_network = NA_character_,
      map_sheet = as.character(feuillet),
      latitude = safe_numeric(latitude),
      longitude = safe_numeric(longitude),
      measurement_date = safe_date(date_sond),
      plot_dimension_measurement = as.character(dimension),
      plot_status = NA_character_
    )

  combined <- trees |>
    mutate(
      plot_id = id_pe,
      plot_measurement_id = id_pe,
      record_id = id_arbre,
      tree_id = id_arbre,
      study_join_key = id_arbre
    ) |>
    left_join(study_reduced, by = "study_join_key") |>
    left_join(plots_for_join, by = c("plot_id", "plot_measurement_id"))
}

combined <- combined |>
  left_join(
    ecology |>
      transmute(
        plot_id = id_pe,
        vegetation_zone_code = as.character(zone_veg),
        vegetation_subzone_code = as.character(szone_veg),
        bioclimatic_domain_code = as.character(dom_bio),
        bioclimatic_subdomain_code = as.character(sdom_bio),
        ecological_region_code = as.character(reg_eco),
        ecological_subregion_code = as.character(sreg_eco),
        regional_landscape_unit_code = as.character(upays_reg),
        ecological_district_code = as.character(dis_eco)
      ),
    by = "plot_id"
  )

# Dictionnaires de codes ----------------------------------------------------

species_lookup <- read_code_sheet("ESSENCES") |>
  transmute(species_code = str_to_upper(code), species_fr = description)
state_lookup <- read_code_sheet("ETAT") |>
  transmute(vitality_code = code, vitality_status = description)
canopy_lookup <- read_code_sheet("ETAGE") |>
  transmute(canopy_stratum_code = code, canopy_stratum = description)
eco_region_lookup <- read_code_sheet("REG_ECO") |>
  transmute(ecological_region_code = code, ecological_region = description)
eco_domain_lookup <- read_code_sheet("DOM_BIO") |>
  transmute(bioclimatic_domain_code = code, bioclimatic_domain = description)

crosswalk_path <- file.path("references", "species_taxonomy_crosswalk.csv")
if (!file.exists(crosswalk_path)) {
  stop("Gabarit taxonomique absent : ", crosswalk_path, call. = FALSE)
}
taxonomy <- read_csv(crosswalk_path, show_col_types = FALSE) |>
  mutate(species_code = str_to_upper(str_trim(as.character(species_code))))
if (nrow(taxonomy) > 0L && anyDuplicated(taxonomy$species_code)) {
  stop("Codes d'espèce dupliqués dans la table taxonomique.", call. = FALSE)
}

exclusion_path <- file.path("references", "species_code_exclusions.csv")
explicit_exclusions <- if (file.exists(exclusion_path)) {
  read_csv(exclusion_path, show_col_types = FALSE) |>
    transmute(species_code = str_to_upper(str_trim(as.character(species_code))),
              explicit_exclusion_reason = reason) |>
    filter(!is.na(species_code), species_code != "") |>
    distinct(species_code, .keep_all = TRUE)
} else {
  tibble(species_code = character(), explicit_exclusion_reason = character())
}

# Harmonisation, unités et provenance --------------------------------------

full <- combined |>
  mutate(
    record_id = as.character(record_id),
    tree_id = as.character(tree_id),
    plot_id = as.character(plot_id),
    plot_measurement_id = as.character(plot_measurement_id),
    species_code = str_to_upper(str_trim(as.character(essence))),
    vitality_code = str_trim(as.character(etat)),
    canopy_stratum_code = dplyr::coalesce(
      str_trim(as.character(etage_arb)), study_canopy_stratum_code
    ),
    diameter_mm = safe_numeric(dhp),
    diameter_cm = diameter_mm / 10,
    height_observed_dm = dplyr::coalesce(study_height_dm, safe_numeric(haut_arbre)),
    height_observed_m = height_observed_dm / 10,
    height_estimated_dm = safe_numeric(haut_esti),
    height_estimated_m = height_estimated_dm / 10,
    height_m = dplyr::coalesce(height_observed_m, height_estimated_m),
    height_source = case_when(
      !is.na(height_observed_m) ~ "observed",
      !is.na(height_estimated_m) ~ "estimated",
      TRUE ~ "missing"
    ),
    age_years = dplyr::coalesce(study_age_years, safe_numeric(age)),
    age_source_code = dplyr::coalesce(study_age_source_code,
                                      str_trim(as.character(source_age))),
    survey_year = lubridate::year(measurement_date),
    is_study_tree = dplyr::coalesce(is_study_tree, FALSE),
    source_inventory = source_inventory,
    measurement_source = paste0("MRNF_", source_inventory),
    source_file = basename(gpkg_path),
    source_file_sha256 = sha256_file(gpkg_path),
    source_table = "DENDRO_ARBRES",
    source_variable_names = paste(
      c("ESSENCE", "DHP", "HAUT_ARBRE", "HAUT_ESTI", "AGE", "ETAT", "ETAGE_ARB"),
      collapse = ";"
    ),
    basal_area_m2 = if_else(
      !is.na(diameter_cm) & diameter_cm > 0,
      pi * (diameter_cm / 200)^2,
      NA_real_
    ),
    basal_area_source_m2 = safe_numeric(st_tige) / 10000,
    basal_area_difference_m2 = basal_area_source_m2 - basal_area_m2,
    diameter_group = fixed_diameter_group(diameter_cm),
    height_group = fixed_height_group(height_m),
    age_class = cut(
      age_years,
      breaks = c(-Inf, 20, 40, 60, 80, 100, Inf),
      right = FALSE,
      labels = c("<20", "20–<40", "40–<60", "60–<80", "80–<100", "≥100")
    )
  ) |>
  left_join(species_lookup, by = "species_code") |>
  left_join(state_lookup, by = "vitality_code") |>
  left_join(canopy_lookup, by = "canopy_stratum_code") |>
  left_join(eco_region_lookup, by = "ecological_region_code") |>
  left_join(eco_domain_lookup, by = "bioclimatic_domain_code") |>
  left_join(explicit_exclusions, by = "species_code")

if (nrow(taxonomy) > 0L) {
  full <- full |> left_join(taxonomy, by = c("species_code", "species_fr" = "species_fr_source"))
} else {
  taxonomy_columns <- c(
    "scientific_name_accepted", "genus", "family", "vascan_taxon_id",
    "quebec_status", "habit", "species_group", "is_conifer", "is_deciduous",
    "taxonomy_match_method", "taxonomy_match_status", "taxonomy_source_version",
    "reviewer", "review_date", "notes"
  )
  full <- ensure_columns(full, taxonomy_columns)
}

aggregate_pattern <- regex(
  paste(
    c("absence", "non[ -]?ident", "ind[ée]termin", "inconnu", "autres?",
      "groupe", "essences?", "feuillus?", "r[ée]sineux", "conif[èe]res?",
      "arbustes?", "\\bsp\\.?$", "\\bspp\\.?$"),
    collapse = "|"
  ),
  ignore_case = TRUE
)

full <- full |>
  mutate(
    species_latin = as.character(scientific_name_accepted),
    species_is_aggregate = !is.na(explicit_exclusion_reason) |
      is.na(species_fr) | str_detect(dplyr::coalesce(species_fr, ""), aggregate_pattern),
    region = NA_character_,
    crown_class = NA_character_,
    notes = case_when(
      is.na(species_latin) ~ "Taxonomie scientifique non appariée ou non revue",
      TRUE ~ NA_character_
    )
  ) |>
  screen_quality_flags()

duplicate_record <- duplicated(full$record_id) | duplicated(full$record_id, fromLast = TRUE)
full$data_quality_flag <- append_flag(
  full$data_quality_flag, duplicate_record, "duplicate_record_key"
)
full$observation_quality <- classify_observation_quality(
  full$species_code,
  full$diameter_cm,
  full$height_observed_m,
  full$height_estimated_m,
  full$taxonomy_match_status,
  full$data_quality_flag
)

if (max_rows > 0L) {
  full$data_quality_flag <- append_flag(
    full$data_quality_flag, TRUE, "development_row_limit_active"
  )
}

final_columns <- c(
  "record_id", "tree_id", "plot_measurement_id", "plot_id", "survey_year",
  "measurement_date", "source_inventory", "source_network", "project_id",
  "transect_id", "plot_number", "plot_type", "species_code", "species_fr",
  "species_latin", "genus", "family", "vascan_taxon_id", "quebec_status",
  "taxonomy_match_method", "taxonomy_match_status", "diameter_mm", "diameter_cm",
  "height_observed_dm", "height_observed_m", "height_estimated_dm",
  "height_estimated_m", "height_m", "height_source", "age_years", "age_class",
  "age_source_code", "crown_class", "canopy_stratum_code", "canopy_stratum",
  "vitality_code", "vitality_status", "cl_defol", "defol_min", "defol_max",
  "cl_qual", "is_study_tree", "study_selection_method", "region",
  "ecological_region_code", "ecological_region", "ecological_subregion_code",
  "bioclimatic_domain_code", "bioclimatic_domain", "ecological_district_code",
  "latitude", "longitude", "map_sheet", "diameter_group", "height_group",
  "species_group", "is_conifer", "is_deciduous", "basal_area_m2",
  "basal_area_source_m2", "basal_area_difference_m2", "measurement_source",
  "source_file", "source_file_sha256", "source_table", "source_variable_names",
  "species_is_aggregate", "data_quality_flag", "observation_quality", "notes"
)
full <- ensure_columns(full, final_columns) |>
  select(all_of(final_columns))

# Petite version pédagogique ------------------------------------------------

exclusion_reasons <- full |>
  transmute(
    record_id,
    tree_id,
    plot_id,
    species_code,
    exclusion_reason = NA_character_,
    exclusion_reason = append_flag(exclusion_reason, is.na(species_code),
                                   "missing_species_code"),
    exclusion_reason = append_flag(exclusion_reason, species_is_aggregate,
                                   "aggregate_or_unresolved_species_code"),
    exclusion_reason = append_flag(exclusion_reason,
                                   is.na(diameter_cm) | diameter_cm <= 0,
                                   "missing_or_nonpositive_diameter"),
    exclusion_reason = append_flag(exclusion_reason,
                                   is.na(height_observed_m) | height_observed_m <= 0,
                                   "missing_or_nonpositive_observed_height"),
    exclusion_reason = append_flag(exclusion_reason,
                                   str_detect(dplyr::coalesce(data_quality_flag, ""),
                                              "duplicate_record_key"),
                                   "duplicate_record_key")
  )

eligible <- full |>
  left_join(exclusion_reasons |> select(record_id, exclusion_reason), by = "record_id") |>
  filter(is.na(exclusion_reason))

if (nrow(eligible) == 0L) {
  stop("Aucun arbre admissible pour la petite version.", call. = FALSE)
}

RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(small_seed)
one_per_species_plot <- eligible |>
  arrange(record_id) |>
  group_by(species_code, plot_id) |>
  slice_sample(n = 1L) |>
  ungroup()

species_frequency <- one_per_species_plot |>
  count(
    species_code, species_fr, species_latin, taxonomy_match_status,
    taxonomy_match_method, name = "eligible_plot_count"
  ) |>
  arrange(desc(eligible_plot_count), species_code)

if (nrow(species_frequency) < small_n_species) {
  stop(
    "Moins de ", small_n_species,
    " espèces admissibles après la règle une espèce–placette.", call. = FALSE
  )
}

selected_species <- species_frequency |>
  slice_head(n = small_n_species)

n_per_species <- min(
  small_n_per_species_requested,
  min(selected_species$eligible_plot_count)
)

set.seed(small_seed)
small <- one_per_species_plot |>
  semi_join(selected_species, by = "species_code") |>
  group_by(species_code) |>
  slice_sample(n = n_per_species) |>
  ungroup() |>
  mutate(
    species = dplyr::coalesce(species_fr, species_code),
    height_m = height_observed_m,
    small_sampling_seed = small_seed,
    small_n_per_species = n_per_species,
    small_sampling_rule = paste0(
      "Top ", small_n_species,
      " species by eligible plot count; one tree per species-plot; ",
      n_per_species, " sampled per species"
    )
  ) |>
  select(
    species, species_code, species_fr, species_latin, genus, family,
    diameter_cm, height_m, age_years, basal_area_m2, canopy_stratum,
    ecological_region, survey_year, plot_id, tree_id, record_id,
    data_quality_flag, observation_quality, small_sampling_seed,
    small_n_per_species, small_sampling_rule
  ) |>
  arrange(species_code, record_id)

selected_species <- selected_species |>
  mutate(
    selected_n = n_per_species,
    selection_rank = row_number(),
    sampling_seed = small_seed,
    selection_requires_taxonomic_review = is.na(species_latin) |
      is.na(taxonomy_match_status) |
      !taxonomy_match_status %in% c("reviewed", "exact_code")
  )

exclusion_log <- exclusion_reasons |>
  filter(!is.na(exclusion_reason)) |>
  mutate(stage = "small_eligibility")

not_selected_species <- one_per_species_plot |>
  anti_join(selected_species, by = "species_code") |>
  transmute(
    record_id, tree_id, plot_id, species_code,
    exclusion_reason = "species_not_in_top_frequency_selection",
    stage = "small_balancing"
  )

not_sampled_balancing <- one_per_species_plot |>
  semi_join(selected_species, by = "species_code") |>
  anti_join(small |> select(record_id), by = "record_id") |>
  transmute(
    record_id, tree_id, plot_id, species_code,
    exclusion_reason = "eligible_but_not_selected_by_balanced_sampling",
    stage = "small_balancing"
  )

not_selected_within_plot <- eligible |>
  anti_join(one_per_species_plot |> select(record_id), by = "record_id") |>
  transmute(
    record_id, tree_id, plot_id, species_code,
    exclusion_reason = "eligible_not_selected_within_species_plot",
    stage = "small_within_plot"
  )

exclusion_log <- bind_rows(exclusion_log, not_selected_species,
                          not_sampled_balancing, not_selected_within_plot) |>
  arrange(stage, species_code, record_id)

stopifnot(!anyDuplicated(full$record_id),
          !anyDuplicated(exclusion_log$record_id),
          nrow(full) == nrow(exclusion_log) + nrow(small),
          length(intersect(exclusion_log$record_id, small$record_id)) == 0L)

# Validation structurée -----------------------------------------------------

validation_summary <- bind_rows(
  tibble(metric = "full_observations", value = nrow(full), detail = NA_character_),
  tibble(metric = "full_plots", value = n_distinct(full$plot_id, na.rm = TRUE),
         detail = NA_character_),
  tibble(metric = "full_species_codes", value = n_distinct(full$species_code,
                                                            na.rm = TRUE),
         detail = NA_character_),
  tibble(metric = "small_observations", value = nrow(small), detail = NA_character_),
  tibble(metric = "small_species", value = n_distinct(small$species_code),
         detail = NA_character_),
  tibble(metric = "small_n_per_species", value = n_per_species,
         detail = NA_character_),
  tibble(metric = "missing_diameter_full", value = sum(is.na(full$diameter_cm)),
         detail = NA_character_),
  tibble(metric = "missing_observed_height_full",
         value = sum(is.na(full$height_observed_m)), detail = NA_character_),
  tibble(metric = "estimated_height_records_full",
         value = sum(full$height_source == "estimated", na.rm = TRUE),
         detail = NA_character_),
  tibble(metric = "quality_flags_nonmissing",
         value = sum(!is.na(full$data_quality_flag)), detail = NA_character_),
  tibble(metric = "duplicate_record_keys",
         value = sum(str_detect(dplyr::coalesce(full$data_quality_flag, ""),
                                "duplicate_record_key")), detail = NA_character_),
  tibble(metric = "source_file_sha256", value = NA_real_,
         detail = unique(full$source_file_sha256)[[1]])
)

# Écriture atomique ---------------------------------------------------------

outputs <- c(
  full = file.path("data_clean", "arbres_quebec.csv"),
  small = file.path("data_clean", "arbres_quebec_small.csv"),
  exclusions = file.path("data_clean", "exclusion_log.csv"),
  selection = file.path("data_clean", "small_sampling_manifest.csv"),
  validation = file.path("data_clean", "validation_summary.csv"),
  dictionary = file.path("data_clean", "data_dictionary.csv")
)

write_atomic_csv(full, outputs[["full"]], overwrite = overwrite_clean)
write_atomic_csv(small, outputs[["small"]], overwrite = overwrite_clean)
write_atomic_csv(exclusion_log, outputs[["exclusions"]], overwrite = overwrite_clean)
write_atomic_csv(selected_species, outputs[["selection"]], overwrite = overwrite_clean)
write_atomic_csv(validation_summary, outputs[["validation"]], overwrite = overwrite_clean)

project_dictionary <- read_csv("data_dictionary.csv", show_col_types = FALSE)
write_atomic_csv(project_dictionary, outputs[["dictionary"]],
                 overwrite = overwrite_clean)
write_atomic_csv(
  project_dictionary |> filter(variable %in% names(small)) |>
    mutate(
      source_table = if_else(variable == "height_m", "DENDRO_ARBRES_ETUDES;DENDRO_ARBRES", source_table),
      source_field = if_else(variable == "height_m", "HAUT_ARBRE", source_field),
      transformation = if_else(variable == "height_m", "HAUT_ARBRE / 10; hauteur observée uniquement", transformation),
      notes = if_else(variable == "height_m", "Aucune hauteur estimée dans la version pédagogique", notes)
    ) |>
    arrange(match(variable, names(small))),
  "data_clean/arbres_quebec_small_dictionary.csv", overwrite = overwrite_clean
)

if (requireNamespace("arrow", quietly = TRUE)) {
  parquet_path <- file.path("data_clean", "arbres_quebec.parquet")
  if (file.exists(parquet_path) && !overwrite_clean) {
    cli_warn(paste("Parquet existant non remplacé :", parquet_path))
  } else {
    arrow::write_parquet(full, parquet_path)
  }
}

run_log <- tibble(
  run_finished_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  source_inventory = source_inventory,
  source_gpkg = gpkg_path,
  source_sha256 = sha256_file(gpkg_path),
  dictionary_sha256 = sha256_file(dictionary_path),
  max_rows_development = max_rows,
  full_observations = nrow(full),
  small_observations = nrow(small),
  small_species = small_n_species,
  small_n_per_species = n_per_species,
  small_seed = small_seed
)
log_path <- file.path("logs", "cleaning_log.csv")
write_csv(run_log, log_path, append = file.exists(log_path),
          col_names = !file.exists(log_path), na = "")

cli_inform(c(
  "v" = paste0("Version complète : ", outputs[["full"]]),
  "v" = paste0("Version pédagogique : ", outputs[["small"]]),
  "v" = paste0("Dictionnaire : ", outputs[["dictionary"]]),
  "i" = paste0("Observations complètes : ", format(nrow(full), big.mark = " ")),
  "i" = paste0("Observations pédagogiques : ", nrow(small)),
  "i" = paste0("Espèces sélectionnées : ",
                 paste(selected_species$species_code, collapse = ", ")),
  "!" = if (any(selected_species$selection_requires_taxonomic_review))
    "Au moins une espèce sélectionnée exige une révision taxonomique avant publication."
  else "Toutes les espèces sélectionnées ont un appariement taxonomique revu."
))
