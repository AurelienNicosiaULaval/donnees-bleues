# Contrôles de structure indépendants du nombre de périodes téléchargées.
employment_schema <- function() {
  list(
    indicators = c("Chômage", "Emploi", "Emploi à temps partiel", "Emploi à temps plein",
                   "Population active", "Taux d'activité", "Taux d'emploi", "Taux de chômage"),
    territories = c("Abitibi-Témiscamingue", "Bas-Saint-Laurent", "Capitale-Nationale",
      "Centre-du-Québec", "Chaudière-Appalaches", "Côte-Nord et Nord-du-Québec", "Estrie",
      "Gaspésie--Îles-de-la-Madeleine", "Lanaudière", "Laurentides", "Laval", "Mauricie",
      "Montréal", "Montérégie", "Outaouais", "Québec", "Saguenay--Lac-Saint-Jean")
  )
}

validate_monthly_panel <- function(data, expected_indicators, expected_territories) {
  required <- c("indicateur", "territoire", "date", "unite", "valeur", "valeur_brute")
  missing <- setdiff(required, names(data))
  if (length(missing)) stop("Colonnes du panel absentes : ", paste(missing, collapse = ", "), call. = FALSE)
  if (!nrow(data)) stop("Le panel mensuel est vide.", call. = FALSE)
  keys <- data[c("indicateur", "territoire", "date")]
  if (anyNA(keys) || anyDuplicated(keys)) {
    stop("Chaque combinaison indicateur-territoire-mois doit être renseignée et unique.", call. = FALSE)
  }
  if (!inherits(data$date, "Date") || any(format(data$date, "%d") != "01")) {
    stop("La période doit être le premier jour d'un mois.", call. = FALSE)
  }
  if (!setequal(unique(data$indicateur), expected_indicators) ||
      !setequal(unique(data$territoire), expected_territories)) {
    stop("Les indicateurs ou territoires diffèrent du schéma documenté du tableau 916.", call. = FALSE)
  }
  expected_per_month <- length(expected_indicators) * length(expected_territories)
  if (any(table(data$date) != expected_per_month)) {
    stop("Une période ne contient pas toutes les combinaisons indicateur-territoire.", call. = FALSE)
  }
  months <- sort(unique(data$date))
  if (!identical(months, seq(min(months), max(months), by = "month"))) {
    stop("Une période mensuelle est absente du panel.", call. = FALSE)
  }
  if (anyNA(data$unite) || any(!nzchar(trimws(data$unite)))) {
    stop("Les unités de mesure doivent être renseignées.", call. = FALSE)
  }
  units_by_indicator <- split(data$unite, data$indicateur)
  if (any(vapply(units_by_indicator, function(x) length(unique(x)) != 1L, logical(1)))) {
    stop("Un indicateur mélange plusieurs unités de mesure.", call. = FALSE)
  }
  values <- data$valeur[!is.na(data$valeur)]
  if (!length(values) || any(!is.finite(values)) || any(values < 0)) {
    stop("Les mesures du marché du travail doivent être finies et non négatives.", call. = FALSE)
  }
  rates <- grepl("taux", data$indicateur, ignore.case = TRUE)
  if (any(data$unite[rates] != "%") || any(data$unite[!rates] != "k")) {
    stop("Les unités attendues sont % pour les taux et k pour les effectifs.", call. = FALSE)
  }
  if (any(data$valeur[rates] > 100, na.rm = TRUE)) {
    stop("Un taux du marché du travail dépasse 100 pour cent.", call. = FALSE)
  }
  invisible(data)
}

validate_unique_key <- function(data, columns, name = "table") {
  if (!nrow(data) || !all(columns %in% names(data))) {
    stop("Table vide ou clé absente : ", name, call. = FALSE)
  }
  key <- data[columns]
  if (anyNA(key) || anyDuplicated(key)) stop("Clé manquante ou dupliquée : ", name, call. = FALSE)
  invisible(data)
}

# RSQAQ hourly records mark the interval end in Eastern Standard Time year-round.
parse_air_hour_end <- function(value) {
  parsed <- as.POSIXct(value, tz = 'Etc/GMT+5')
  if (anyNA(parsed)) stop('Heure de mesure RSQAQ illisible.', call. = FALSE)
  parsed
}

air_calendar_day <- function(hour_end) {
  as.Date(hour_end - 1, tz = 'Etc/GMT+5')
}
