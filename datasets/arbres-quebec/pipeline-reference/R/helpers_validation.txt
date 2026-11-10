# Fonctions de validation et de dérivation ---------------------------------

append_flag <- function(existing, condition, flag) {
  existing <- dplyr::coalesce(as.character(existing), "")
  addition <- ifelse(dplyr::coalesce(condition, FALSE), flag, "")
  out <- ifelse(existing == "", addition,
                ifelse(addition == "", existing, paste(existing, addition, sep = ";")))
  dplyr::na_if(out, "")
}

safe_numeric <- function(x) {
  if (is.numeric(x)) return(as.double(x))
  x <- stringr::str_replace_all(as.character(x), ",", ".")
  suppressWarnings(readr::parse_double(x, na = c("", "NA", "N/A", "NULL")))
}

safe_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, c("POSIXct", "POSIXlt"))) return(as.Date(x))
  x <- as.character(x)
  # GeoPackage exports use ISO 8601 timestamps, including milliseconds and Z.
  # Keep their calendar date; these are survey dates, not local event times.
  iso_date <- grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T", x)
  x[!is.na(iso_date) & iso_date] <- substr(x[!is.na(iso_date) & iso_date], 1, 10)
  parsed <- suppressWarnings(lubridate::parse_date_time(
    x,
    orders = c("Ymd", "Y-m-d", "Y/m/d", "dmY", "d/m/Y", "mdY", "m/d/Y")
  ))
  as.Date(parsed)
}

fixed_diameter_group <- function(diameter_cm) {
  cut(
    diameter_cm,
    breaks = c(-Inf, 10, 20, 30, 40, Inf),
    right = FALSE,
    labels = c("<10", "10–<20", "20–<30", "30–<40", "≥40")
  )
}

fixed_height_group <- function(height_m) {
  cut(
    height_m,
    breaks = c(-Inf, 5, 10, 15, 20, Inf),
    right = FALSE,
    labels = c("<5", "5–<10", "10–<15", "15–<20", "≥20")
  )
}

classify_observation_quality <- function(species_code, diameter_cm,
                                         height_observed_m,
                                         height_estimated_m,
                                         taxonomy_match_status,
                                         data_quality_flag) {
  severe <- stringr::str_detect(
    dplyr::coalesce(data_quality_flag, ""),
    "nonpositive_diameter|nonpositive_observed_height|invalid_age|duplicate_record_key"
  )
  dplyr::case_when(
    severe ~ "review_required",
    is.na(species_code) | is.na(diameter_cm) ~ "insufficient",
    !is.na(height_observed_m) & taxonomy_match_status == "reviewed" ~
      "A_observed_taxonomy_reviewed",
    !is.na(height_observed_m) ~ "B_observed_height",
    !is.na(height_estimated_m) ~ "C_estimated_height",
    TRUE ~ "D_diameter_only"
  )
}

screen_quality_flags <- function(data) {
  data <- data |>
    dplyr::mutate(data_quality_flag = NA_character_)

  data$data_quality_flag <- append_flag(
    data$data_quality_flag, is.na(data$species_code), "missing_species_code"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag, is.na(data$diameter_cm), "missing_diameter"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    !is.na(data$diameter_cm) & data$diameter_cm <= 0,
    "nonpositive_diameter"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    !is.na(data$diameter_cm) & data$diameter_cm > 300,
    "suspect_diameter_gt_300cm"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    !is.na(data$height_observed_m) & data$height_observed_m <= 0,
    "nonpositive_observed_height"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    !is.na(data$height_observed_m) & data$height_observed_m > 70,
    "suspect_observed_height_gt_70m"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    !is.na(data$height_estimated_m) & data$height_estimated_m <= 0,
    "nonpositive_estimated_height"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    !is.na(data$age_years) & data$age_years < 0,
    "invalid_age"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    !is.na(data$age_years) & data$age_years > 500,
    "suspect_age_gt_500"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    data$height_source == "estimated",
    "height_estimated_not_observed"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    dplyr::coalesce(data$species_is_aggregate, FALSE),
    "aggregate_or_unresolved_species_code"
  )
  data$data_quality_flag <- append_flag(
    data$data_quality_flag,
    is.na(data$taxonomy_match_status) |
      !data$taxonomy_match_status %in% c("reviewed", "exact_code"),
    "taxonomy_not_reviewed"
  )
  data
}

# Ces seuils sont des filtres de dépistage très prudents, non des limites
# biologiques officielles. Aucune ligne n'est supprimée de la version complète
# à cause d'eux; toute révision doit être documentée.
