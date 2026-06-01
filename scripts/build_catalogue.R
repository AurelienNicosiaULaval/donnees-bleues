source("R/utils_catalogue.R")

catalogue <- build_catalogue("datasets")
write_catalogue(catalogue, "data/metadata/catalogue.csv")
saveRDS(catalogue, "data/metadata/catalogue.rds")

message("Catalogue généré : data/metadata/catalogue.csv")

