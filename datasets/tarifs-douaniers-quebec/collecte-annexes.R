# Nouvelle lecture d'un texte juridique fixe. Conserver chaque capture séparément.
# Rscript datasets/tarifs-douaniers-quebec/collecte-annexes.R [dossier_sortie]
library(rvest)
library(xml2)
library(tibble)
library(dplyr)
library(readr)
library(jsonlite)
library(digest)

args <- commandArgs(trailingOnly = TRUE)
racine <- if (length(args)) args[1] else "data/raw/tarifs-douaniers-quebec/annexes"
capture <- paste0(format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"), "_", Sys.getpid())
dest <- file.path(racine, capture)
stopifnot(!dir.exists(dest))
dir.create(dest, recursive = TRUE)
url <- "https://gazette.gc.ca/rp-pr/p2/2026/2026-09-23/html/sor-dors186-fra.html"
brut <- file.path(dest, "gazette-dors186.html")
curl <- Sys.which("curl")
if (!nzchar(curl)) stop("Le programme curl est nécessaire à cette acquisition.")
statut <- system2(curl, c("--fail", "--location", "--max-time", "120", shQuote(url), "--output", shQuote(brut)))
if (statut != 0L) stop("Acquisition échouée; aucun résultat tarifaire n'est publié par ce script.")
heure <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
page <- read_html(brut)
annexes <- bind_rows(lapply(1:3, function(i) {
 titres <- html_elements(page, "h3")
 titre <- titres[html_text2(titres) == paste("ANNEXE", i)]
 stopifnot(length(titre) == 1L)
 liste <- xml_find_first(titre, "following-sibling::ul[1]")
 codes <- html_text2(html_elements(liste, "li"))
 tibble(annexe = i, code_affiche = codes, code_tarifaire = gsub("\\.", "", codes),
 taux_surtaxe_pourcent = c(15,25,50)[i], instrument = "DORS/2026-186",
 date_enregistrement = "2026-09-04", date_publication = "2026-09-23",
 date_effet = "2026-09-08", source_url = url)
}))
stopifnot(nrow(annexes) == 335L, !anyDuplicated(annexes$code_tarifaire),
 all(grepl("^[0-9]{8}$", annexes$code_tarifaire)))
write_csv(annexes, file.path(dest, "annexes_2026.csv"), na = "NA")
write_json(list(capture_id = capture, acquired_at_utc = heure, source_url = url,
 sha256_html = digest(file = brut, algo = "sha256"), lignes = nrow(annexes),
 portee = "Annexes 1 à 3; exemptions, remises et autres instruments non modélisés"),
 file.path(dest, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
message("Capture du texte fixe conservée : ", dest)
