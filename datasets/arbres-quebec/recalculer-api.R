# Refaire le tirage avec l’archive PET5 locale de référence.
library(digest)
source('datasets/arbres-quebec/preparation-api.R')
archive <- Sys.getenv('DB_ARBRES_PET5', unset = '')
if (!nzchar(archive)) stop('Indiquer le chemin de l’archive locale : Sys.setenv(DB_ARBRES_PET5 = "chemin/PET5_GPKG.zip").', call. = FALSE)
preparer_arbres_forestiers_api(archive, 'data/raw/recalcul-api/arbres-quebec/20261110T200718Z')
