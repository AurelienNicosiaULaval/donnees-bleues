# Usage : Rscript --vanilla scripts/acquire_donnees_quebec.R <jeu> [identifiant-ressource]
# Sans identifiant, affiche les ressources. Aucun fichier de classe n'est remplacé.
library(jsonlite)
source('R/utils_downloads.R')
source('R/utils_ckan.R')
source('R/utils_donnees_quebec.R')
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop('Indiquer un identifiant Données bleues.', call. = FALSE)
if (length(args) == 1L) {
  print(dq_resource_options(args[[1]]), row.names = FALSE)
} else {
  path <- dq_acquire(args[[1]], args[[2]])
  message('Source acquise : ', path)
}
