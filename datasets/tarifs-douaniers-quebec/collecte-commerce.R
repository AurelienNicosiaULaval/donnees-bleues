# Nouvelle capture du commerce provincial. Chaque exécution crée un dossier.
# Rscript datasets/tarifs-douaniers-quebec/collecte-commerce.R [dossier_sortie]
library(readr)
library(dplyr)
library(jsonlite)
library(digest)

args <- commandArgs(trailingOnly = TRUE)
racine <- if (length(args)) args[1] else "data/raw/tarifs-douaniers-quebec/commerce"
capture <- paste0(format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"), "_", Sys.getpid())
dest <- file.path(racine, capture)
stopifnot(!dir.exists(dest))
dir.create(dest, recursive = TRUE)
url <- "https://www150.statcan.gc.ca/n1/tbl/csv/12100175-fra.zip"
archive <- file.path(dest, "12100175-fra.zip")
options(timeout = 600)
download.file(url, archive, mode = "wb", method = "libcurl")
heure <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
utils::unzip(archive, files = c("12100175.csv", "12100175_MetaData.csv"), exdir = dest)
selection <- DataFrameCallback$new(function(d, pos) d |>
 filter(.data$GÉO == "Québec", .data[["PÉRIODE DE RÉFÉRENCE"]] >= "2017-01"))
commerce <- read_delim_chunked(file.path(dest, "12100175.csv"), delim = ";", callback = selection,
 chunk_size = 200000, col_types = cols(.default = col_character()), progress = FALSE)
stopifnot(ncol(commerce) == 17L)
names(commerce) <- c("mois", "geographie", "dguid", "commerce", "produit_scpan", "partenaire", "unite", "unite_id", "facteur_scalaire", "scalaire_id", "vecteur", "coordonnees", "valeur_milliers_cad", "statut_source", "symbole_source", "termine_source", "decimales_source")
commerce <- commerce |> mutate(valeur_milliers_cad = as.numeric(valeur_milliers_cad), source_id = "statcan_commerce_12100175",
 date_capture_utc = heure, base_prix = "courants", desaisonnalise = "non", base_commerce = "douaniere")
stopifnot(nrow(commerce) > 0, !anyDuplicated(commerce[c("mois", "vecteur")]), all(commerce$facteur_scalaire == "milliers"))
write_csv(commerce, file.path(dest, "commerce_quebec.csv"), na = "NA")
write_json(list(capture_id = capture, source_url = url, acquired_at_utc = heure,
 sha256_zip = digest(file = archive, algo = "sha256"), rows = nrow(commerce),
 premier_mois = min(commerce$mois), dernier_mois = max(commerce$mois),
 r_version = as.character(getRversion())), file.path(dest, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
message("Nouvelle capture conservée : ", dest)
