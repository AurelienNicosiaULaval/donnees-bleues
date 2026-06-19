source("R/utils_catalogue.R")
source("R/utils_card_images.R")

catalogue <- build_catalogue("datasets")
validate_card_images(catalogue)
write_catalogue(catalogue, "data/metadata/catalogue.csv")
saveRDS(catalogue, "data/metadata/catalogue.rds")

message("Catalogue généré : data/metadata/catalogue.csv")
