# Conserver seulement les champs nécessaires aux activités, en ordre de référence.
library(readr)
library(dplyr)
library(stringr)
library(digest)
extraire_accidents_api <- function(fichier) {
  attendu <- '17fc60a26fb8ed8cc0fac871a7e4efc30cda95b93500e7a7f8213ba45008232a'
  if (!identical(digest::digest(file=fichier,algo='sha256'),attendu))
    stop('Le fichier SAAQ 2022 a changé; réviser les activités avant de l’utiliser.',call.=FALSE)
  x <- readr::read_csv(fichier,col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE)
  champs <- c('AN','NO_SEQ_COLL','GRAVITE','REG_ADM','JR_SEMN_ACCDN')
  if (!all(champs %in% names(x)) || nrow(x)!=108186L || anyNA(x$NO_SEQ_COLL) || anyDuplicated(x$NO_SEQ_COLL))
    stop('Structure ou effectif des rapports 2022 inattendus.',call.=FALSE)
  x |> arrange(NO_SEQ_COLL) |> select(AN,GRAVITE,REG_ADM,JR_SEMN_ACCDN)
}
preparer_accidents_api <- function(fichier) {
  x <- readr::read_csv(fichier,col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE)
  champs <- c('AN','GRAVITE','REG_ADM','JR_SEMN_ACCDN')
  categories <- c('Dommages matériels seulement','Dommages matériels inférieurs au seuil de rapportage','Léger','Mortel ou grave')
  if (!identical(names(x),champs) || nrow(x)!=108186L || anyNA(x[c('AN','GRAVITE','JR_SEMN_ACCDN')]) ||
      any(x$AN!='2022') || any(!x$GRAVITE %in% categories) || any(!x$JR_SEMN_ACCDN %in% c('SEM','FDS')))
    stop('Projection pédagogique des accidents invalide.',call.=FALSE)
  x |>
    transmute(annee=as.integer(AN),gravite=GRAVITE,
      region_nom=stringr::str_squish(stringr::str_remove(REG_ADM,'\\s*\\([0-9]{2}\\)$')),
      jour_semaine_code=stringr::str_squish(JR_SEMN_ACCDN),
      type_jour=if_else(jour_semaine_code=='SEM','Lundi au vendredi','Samedi ou dimanche'),
      accident_avec_victime=gravite %in% c('Mortel ou grave','Léger'))
}
