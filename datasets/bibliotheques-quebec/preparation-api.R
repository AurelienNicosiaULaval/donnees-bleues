# Préparer la table utilisée dans les activités à partir d'un instantané DataStore.
# Les titres de champs publiés par DataStore omettent parfois les accents du CSV.
library(dplyr)
library(readr)
library(stringi)

preparer_bibliotheques_api <- function(fichier) {
  donnees <- read_csv(fichier, col_types = cols(.default = col_character()),
                      na = c('', 'NA'), show_col_types = FALSE)
  noms <- c('Bibliothèque ou Centre régional', 'Région administrative',
            'Population desservie', 'Catégorie de la bibl.', 'Visites (Total)',
            'Prêts / Tous les doc. (Total)')
  normaliser <- function(x) tolower(stri_trans_general(x, 'Latin-ASCII'))
  for (nom in noms) {
    indices <- which(normaliser(names(donnees)) == normaliser(nom))
    if (length(indices) != 1L) stop('Champ absent ou ambigu : ', nom, call. = FALSE)
    names(donnees)[indices] <- nom
  }
  nombre <- function(x) parse_number(gsub('\u00a0', ' ', x, fixed = TRUE),
                                      locale = locale(decimal_mark = ',', grouping_mark = ' '))
  ratio <- function(x, n) if_else(!is.na(n) & n > 0, x / n, NA_real_)
  donnees |>
    transmute(bibliotheque = `Bibliothèque ou Centre régional`,
      region_administrative = `Région administrative`,
      population_desservie = nombre(`Population desservie`),
      categorie_bibliotheque = `Catégorie de la bibl.`,
      visites_total = nombre(`Visites (Total)`),
      prets_total = nombre(`Prêts / Tous les doc. (Total)`),
      visites_par_habitant = ratio(visites_total, population_desservie),
      prets_par_habitant = ratio(prets_total, population_desservie)) |>
    arrange(region_administrative, bibliotheque)
}
