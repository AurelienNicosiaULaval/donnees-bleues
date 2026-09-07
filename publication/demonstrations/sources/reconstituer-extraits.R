# Reconstituer les extraits acquis automatiquement auprès des producteurs.
# Depuis le dossier demonstrations : Rscript sources/reconstituer-extraits.R
# Résultat dans data-reconstituees pour préserver la version fournie.
# Dépendances : readr, dplyr, tidyr, sf avec GDAL ; connexion Internet.
# Recensement : environ 47 Mo compressés, 650 Mo après extraction.
# Raster : requêtes partielles sur la source de 9,5 Go, seul un extrait est lu.

library(readr)
library(dplyr)
library(tidyr)
library(sf)

options(timeout = 600)
cache <- Sys.getenv("DB_DEMO_CACHE", unset = file.path(tempdir(), "db-sources"))
sortie <- "data-reconstituees"
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
dir.create(sortie, showWarnings = FALSE)

# 1. Profil du recensement 2021, subdivisions de recensement du Québec.
url_recensement <- paste0(
  "https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/details/",
  "download-telecharger/comp/GetFile.cfm?Lang=F&FILETYPE=CSV&GEONO=020")
archive <- file.path(cache, "recensement2021-sdr.zip")
if (!file.exists(archive)) download.file(url_recensement, archive, mode = "wb")
nom_csv <- "98-401-X2021020_Francais_CSV_data.csv"
unzip(archive, files = nom_csv, exdir = cache)
ids <- c(1, 58, 63, 64, 65, 68, 69, 70, 78, 86, 89, 97, 126, 127, 128,
         1998, 1999, 2229)

# Noms uniques : le fichier original répète l’intitulé « SYMBOLE ».
colonnes <- c("annee", "idugd", "code_sdr", "niveau_geo", "nom_sdr", "nrt_qa",
              "nrt_qd", "qualite_geo", "id", "libelle", "note", "c", "symbole_c",
              "hommes", "symbole_h", "femmes", "symbole_f", "taux",
              "symbole_taux", "taux_h", "symbole_taux_h", "taux_f", "symbole_taux_f")
types <- cols(.default = col_skip(), idugd = col_character(),
              code_sdr = col_character(), niveau_geo = col_character(),
              nom_sdr = col_character(), qualite_geo = col_character(),
              id = col_integer(), libelle = col_character(),
              c = col_character(), symbole_c = col_character())
retenir <- DataFrameCallback$new(function(x, pos) filter(x, id %in% ids))
long <- read_csv_chunked(
  file.path(cache, nom_csv), callback = retenir, chunk_size = 100000,
  skip = 1, col_names = colonnes, col_types = types,
  locale = locale(encoding = "Windows-1252"), trim_ws = FALSE, progress = FALSE)
long <- long |> mutate(c = trimws(c), symbole_c = trimws(symbole_c))

long |>
  distinct(id, libelle) |>
  arrange(id) |>
  rename(id_caracteristique = id, libelle_statistique_canada = libelle) |>
  write_csv(file.path(sortie, "dictionnaire-recensement.csv"), na = "")

large <- long |>
  select(code_sdr, nom_sdr, idugd, niveau_geo, qualite_geo, id, c, symbole_c) |>
  pivot_wider(names_from = id, values_from = c(c, symbole_c),
              names_glue = "{.value}{id}")
ordre <- c("code_sdr", "nom_sdr", "idugd", "niveau_geo", "qualite_geo",
           as.vector(rbind(paste0("c", ids), paste0("symbole_c", ids))))
large <- large |> select(all_of(ordre))
stopifnot(nrow(large) == 1282, all(substr(large$code_sdr, 1, 2) == "24"))
write_csv(large, file.path(sortie, "recensement-quebec-2021-indicateurs.csv"), na = "")

# 2. Écarts de température de surface, INSPQ / CERFO, millésime 2020-2022.
Sys.setenv(GDAL_DISABLE_READDIR_ON_OPEN = "EMPTY_DIR",
           CPL_VSIL_CURL_ALLOWED_EXTENSIONS = ".tif", GDAL_HTTP_TIMEOUT = "60")
url_raster <- paste0("/vsicurl/https://dq-prd-bucket1.s3.ca-central-1.amazonaws.com/",
                     "inspq/EcartTemperatureRelatif2022_Ecoumene2021.tif")
tif <- file.path(cache, "chaleur.tif")
xyz <- file.path(cache, "chaleur.xyz")
if (!file.exists(tif)) {
  gdal_utils("translate", url_raster, tif,
    options = c("-projwin_srs", "EPSG:4326", "-projwin",
                "-71.28", "46.84", "-71.20", "46.78",
                "-of", "GTiff", "-co", "COMPRESS=DEFLATE"), quiet = TRUE)
}
gdal_utils("translate", tif, xyz, options = c("-of", "XYZ"), quiet = TRUE)
pixels <- read_table(xyz, col_names = c("x_m", "y_m", "ecart_c"),
                     col_types = cols(.default = col_double()),
                     na = c("nan", "-nan", "NaN", "-99999"), progress = FALSE)
extrait <- pixels |>
  filter(round((x_m - min(x_m)) / 15) %% 4 == 0,
         round((max(y_m) - y_m) / 15) %% 4 == 0,
         is.finite(ecart_c))
stopifnot(nrow(extrait) == 9806)
write_csv(extrait, file.path(sortie, "chaleur-quebec-2020-2022.csv"))
message("Extraits recréés dans ", sortie, ". La version data reste inchangée.")
# Les 42 crues sont une transcription du tableau de l’annexe 3.
# Consulter PROVENANCE.md pour la page source, les codes et les vérifications.
