source("R/utils_activities.R")

catalogue_activites <- build_activity_catalogue("datasets")
validate_activity_catalogue(catalogue_activites)
write_activity_catalogue(catalogue_activites, "data/metadata/catalogue_activites.csv")
saveRDS(catalogue_activites, "data/metadata/catalogue_activites.rds")

message("Catalogue d'activités généré : data/metadata/catalogue_activites.csv")

