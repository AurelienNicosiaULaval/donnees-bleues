# Préparer uniquement les variables utilisées dans les activités sur les stations.
library(dplyr)
library(readr)

preparer_air_api <- function(fichier) {
  x <- readr::read_csv(fichier, show_col_types = FALSE)
  attendues <- c('ID_STATION', 'NOM_STATION', 'RA', 'TYPE_MILIEU',
                 'DATE_OUVERTURE', 'DATE_FERMETURE', 'LATITUDE', 'LONGITUDE')
  if (!all(attendues %in% names(x)) || !nrow(x)) stop('Champs des stations absents.', call. = FALSE)
  regions <- c('Bas-Saint-Laurent', 'Saguenay-Lac-Saint-Jean', 'Capitale-Nationale',
    'Mauricie', 'Estrie', 'Montréal', 'Outaouais', 'Abitibi-Témiscamingue',
    'Côte-Nord', 'Nord-du-Québec', 'Gaspésie-Iles-de-la-Madeleine',
    'Chaudière-Appalaches', 'Laval', 'Lanaudière', 'Laurentides', 'Montérégie', 'Centre-du-Québec')
  resultat <- x |>
    transmute(station_id = as.integer(ID_STATION), station_name = NOM_STATION,
      region_code = as.integer(RA), region_administrative = regions[region_code],
      type_milieu = TYPE_MILIEU, date_ouverture = as.Date(DATE_OUVERTURE),
      date_fermeture = as.Date(DATE_FERMETURE), latitude = as.numeric(LATITUDE),
      longitude = as.numeric(LONGITUDE),
      annee_ouverture = as.integer(format(date_ouverture, '%Y')),
      annee_fermeture = as.integer(format(date_fermeture, '%Y')),
      decennie_ouverture = paste0(floor(annee_ouverture / 10) * 10, 's'),
      station_sans_date_fermeture = is.na(date_fermeture)) |>
    arrange(region_code, station_name, station_id)
  if (anyNA(resultat$station_id) || anyDuplicated(resultat$station_id) ||
      anyNA(resultat$region_administrative) || anyNA(resultat$date_ouverture) ||
      anyNA(resultat$latitude) || anyNA(resultat$longitude))
    stop('Identifiants ou variables essentielles des stations invalides.', call. = FALSE)
  resultat
}
