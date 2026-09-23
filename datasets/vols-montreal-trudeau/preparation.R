# Préparer les tables de classe à partir de l'instantané YUL suivi dans ce dépôt.
# Exécuter depuis la racine : Rscript datasets/vols-montreal-trudeau/preparation.R
library(dplyr)
library(readr)
library(jsonlite)
library(digest)

id <- "vols-montreal-trudeau"
dossier_source <- file.path("datasets", id, "source")
dossier_sortie <- file.path("data", "processed", id)
dir.create(dossier_sortie, recursive = TRUE, showWarnings = FALSE)

empreintes_attendues <- c(
  vols = "31b416c7a3607d94bb14a8e80d9dfe556f364c23862ec3946ef5855e18337ff0",
  trafic_quotidien = "5ddb1b4bf9c03f8c6aa4ad8a2cecccdedb48a44efb909bb741a2c3068b81db09",
  liaisons = "415da71eeda18ae53330559fd4f8890b61cc4d94f3daf13ee4842f159df4a9ff"
)
chemins <- file.path(dossier_source, paste0(names(empreintes_attendues), ".rds"))
stopifnot(all(file.exists(chemins)))
empreintes <- vapply(chemins, digest, character(1), file = TRUE,
                     algo = "sha256", USE.NAMES = FALSE)
stopifnot(identical(unname(empreintes), unname(empreintes_attendues)))

tables <- setNames(lapply(chemins, readRDS), names(empreintes_attendues))
vols <- tables$vols
trafic <- tables$trafic_quotidien
liaisons <- tables$liaisons
stopifnot(
  nrow(vols) == 491786L, nrow(trafic) == 912L, nrow(liaisons) == 1460L,
  !anyDuplicated(vols$vol_id), !anyDuplicated(trafic$date_locale),
  !anyDuplicated(paste(liaisons$origine_icao, liaisons$destination_icao)),
  sum(trafic$n_departs_observes) == 248842L,
  sum(trafic$n_arrivees_observees) == 245510L,
  sum(trafic$n_evenements_observes) ==
    sum(trafic$n_departs_observes + trafic$n_arrivees_observees),
  sum(vols$sens == "local_yul") == 2566L
)

# Conserver toutes les trajectoires, avec un choix explicite de variables de classe.
vols_classe <- vols |>
  select(source_period, date_yul, heure_yul_utc, sens, origine_icao,
         destination_icao, compagnie_icao, type_appareil, duree_observee_min,
         n_origine_candidats, n_destination_candidats)
chemins_sortie <- file.path(dossier_sortie,
  c("vols_yul.csv", "trafic_quotidien_yul.csv", "liaisons_yul.csv"))
write_csv(vols_classe, chemins_sortie[1], na = "")
write_csv(trafic, chemins_sortie[2], na = "")
write_csv(liaisons, chemins_sortie[3], na = "")

instant_source <- "2026-09-23 10:55:36 UTC"
url_source <- "https://github.com/MrAirspace/aircraft-flight-schedules/releases"
sources <- lapply(seq_along(chemins), function(i) list(
  source_url = url_source,
  acquisition_kind = "instantane_derive_archives_ADS-B",
  acquired_at_utc = instant_source,
  local_file = file.path(dossier_source, basename(chemins[i])),
  sha256 = unname(empreintes[i])
))
manifest <- list(
  dataset_id = id,
  prepared_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  source_snapshot_at_utc = instant_source,
  observation_period = c("2024-01-01", "2026-06-30"),
  sources = sources,
  tables = lapply(seq_along(chemins_sortie), function(i) list(
    path = chemins_sortie[i],
    rows = nrow(list(vols_classe, trafic, liaisons)[[i]]),
    sha256 = digest(chemins_sortie[i], file = TRUE, algo = "sha256")
  ))
)
write_json(manifest, file.path(dossier_sortie, "manifest.json"),
           auto_unbox = TRUE, pretty = TRUE)
message("YUL : ", nrow(vols_classe), " trajectoires et deux tables de synthèse préparées.")
