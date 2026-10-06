# Première collecte reproductible. Aucun fichier d'une collecte antérieure
# n'est remplacé. Les observations des tableaux de synthèse ne constituent
# pas un moteur de calcul des droits effectivement dus.

# Bibliothèques
library(httr2)
library(rvest)
library(xml2)
library(dplyr)
library(readr)
library(tibble)
library(DBI)
library(RSQLite)
library(digest)
library(jsonlite)

main <- function() {
  # Chemins indépendants du répertoire courant
  script_argument <- grep("^--file=", commandArgs(), value = TRUE)
  if (length(script_argument) != 1L) stop("Exécuter avec Rscript collecte-initiale.R")
  project_dir <- dirname(normalizePath(sub("^--file=", "", script_argument)))
  replay_argument <- grep("^--replay=", commandArgs(trailingOnly = TRUE), value = TRUE)
  if (length(replay_argument) > 1L) stop("Un seul répertoire de relecture est autorisé")
  replay_dir <- if (length(replay_argument)) normalizePath(sub("^--replay=", "", replay_argument)) else NULL
  replay_manifest <- if (!is.null(replay_dir)) {
    read_csv(file.path(replay_dir, "manifest.csv"),
             col_types = cols(.default = col_character(), octets = col_double()))
  } else NULL
  collection_id <- paste0(format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"), "_", Sys.getpid())
  collection_dir <- file.path(project_dir, "collectes", collection_id)
  if (dir.exists(collection_dir)) stop("La collecte existe déjà")
  dir.create(collection_dir, recursive = TRUE)
  raw_dir <- file.path(collection_dir, "sources-brutes")
  dir.create(raw_dir)
  sources <- read_csv(file.path(project_dir, "inventaire-sources.csv"), show_col_types = FALSE)
  manifest <- tibble(source_id = character(), url = character(), observed_at_utc = character(),
                     fichier = character(), sha256 = character(), octets = double(), methode = character())
  download_errors <- tibble(source_id = character(), url = character(), erreur = character())

  # Télécharger chaque preuve et garder une empreinte du contenu exact
  capture <- function(source_id, url, filename) {
    path <- file.path(raw_dir, filename)
    if (file.exists(path)) stop("Refus d'écraser une source : ", filename)
    if (!is.null(replay_manifest)) {
      original <- replay_manifest[replay_manifest$source_id == source_id, ]
      if (nrow(original) != 1L) stop("Source absente ou non unique dans la relecture : ", source_id)
      original_path <- file.path(replay_dir, original$fichier)
      bytes <- readBin(original_path, what = "raw", n = file.info(original_path)$size)
      if (digest(bytes, algo = "sha256", serialize = FALSE) != original$sha256) {
        stop("Empreinte du fichier original différente : ", source_id)
      }
      writeBin(bytes, path)
      manifest <<- bind_rows(manifest, tibble(
        source_id = source_id, url = original$url, observed_at_utc = original$observed_at_utc,
        fichier = file.path("sources-brutes", filename), sha256 = original$sha256,
        octets = length(bytes), methode = "relecture_snapshot_empreinte_verifiee"
      ))
      write_csv(manifest, file.path(collection_dir, "manifest.csv"))
      return(path)
    }
    response <- tryCatch(request(url) |>
      req_timeout(30) |>
      req_retry(max_tries = 2) |>
      req_perform(), error = identity)
    if (inherits(response, "error")) {
      # Le curl natif utilise le magasin de certificats du système.
      # La vérification TLS reste active; aucun certificat n'est contourné.
      curl_bin <- Sys.which("curl")
      if (!nzchar(curl_bin)) stop(response)
      partial_path <- paste0(path, ".part")
      curl_output <- system2(curl_bin, args = c(
        "--fail", "--silent", "--show-error", "--location", "--max-time", "30",
        "--output", shQuote(partial_path), "--write-out", shQuote("%{url_effective}"), shQuote(url)
      ), stdout = TRUE, stderr = TRUE)
      if (!is.null(attr(curl_output, "status")) || !file.exists(partial_path)) stop(response)
      bytes <- readBin(partial_path, what = "raw", n = file.info(partial_path)$size)
      effective_url <- tail(curl_output, 1)
      unlink(partial_path)
      method <- "curl_natif_TLS_verifie"
    } else {
      bytes <- resp_body_raw(response)
      effective_url <- resp_url(response)
      method <- "httr2_TLS_verifie"
    }
    writeBin(bytes, path)
    manifest <<- bind_rows(manifest, tibble(
      source_id = source_id, url = effective_url,
      observed_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      fichier = file.path("sources-brutes", filename),
      sha256 = digest(bytes, algo = "sha256", serialize = FALSE), octets = length(bytes), methode = method
    ))
    write_csv(manifest, file.path(collection_dir, "manifest.csv"))
    message("Source conservée : ", source_id)
    path
  }

  source_url <- function(id) sources$url[match(id, sources$source_id)]
  tariff_path <- capture("finances_liste", source_url("finances_liste"), "contre-tarifs.html")
  tariff_html <- read_html(tariff_path)
  tables <- html_elements(tariff_html, "table")
  if (length(tables) != 3L) stop("Structure de la source modifiée : réviser le parseur")
  period_labels <- vapply(tables, function(node) {
    html_elements(node, xpath = "ancestor::details/summary") |> html_text2() |> paste(collapse = " ")
  }, character(1))
  expected_labels <- c("En vigueur à compter du 8 septembre 2026",
                       "En vigueur à compter du 1 septembre 2025 à 7 septembre 2026",
                       "En vigueur jusqu'au 31 août 2025")
  if (!identical(period_labels, expected_labels)) stop("Périodes de la source modifiées : réviser le parseur")
  period_starts <- c("2026-09-08", "2025-09-01", NA_character_)
  period_ends <- c(NA_character_, "2026-09-07", "2025-08-31")

  tariff_observations <- bind_rows(lapply(seq_along(tables), function(i) {
    tab <- html_table(tables[[i]], convert = FALSE)
    if (!all(c("Numéro tarifaire", "Description", "Taux tarifaire") %in% names(tab))) {
      stop("Colonnes tarifaires modifiées")
    }
    initial_effective <- if ("Date d'entrée en vigueur" %in% names(tab)) {
      tab[["Date d'entrée en vigueur"]]
    } else rep(NA_character_, nrow(tab))
    tibble(
      collection_id = collection_id, source_id = "finances_liste", source_table = i,
      source_row = seq_len(nrow(tab)), pays_percepteur = "CAN", pays_origine = "USA",
      nomenclature = "Numero_tarifaire_canadien", code_tarifaire = gsub("[.]", "", tab[["Numéro tarifaire"]]),
      code_affiche_source = tab[["Numéro tarifaire"]], code_sh6 = substr(code_tarifaire, 1, 6),
      position_source = tab[["Position du Système harmonisé (SH)"]],
      description_source = tab[["Description"]], taux_surtaxe_pourcent = parse_number(tab[["Taux tarifaire"]]),
      date_application_initiale_source = initial_effective,
      periode_table_source = period_labels[i], debut_periode_table_source = period_starts[i],
      fin_periode_table_source_inclusive = period_ends[i],
      statut_validation = "table_recapitulative_extraite_conditions_non_resolues",
      observed_at_utc = manifest$observed_at_utc[manifest$source_id == "finances_liste"]
    )
  }))

  # Contrôles de structure : les limites juridiques restent explicites
  stopifnot(all(grepl("^[0-9]{8}$", tariff_observations$code_tarifaire)),
            !anyNA(tariff_observations$taux_surtaxe_pourcent),
            all(tariff_observations$taux_surtaxe_pourcent >= 0),
            nrow(distinct(tariff_observations, source_table, code_tarifaire)) == nrow(tariff_observations))
  dates_present <- na.omit(tariff_observations$date_application_initiale_source)
  stopifnot(all(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", dates_present)))

  # Documents nécessaires à la validation juridique ultérieure
  capture_document <- function(id, filename) {
    tryCatch(capture(id, source_url(id), filename), error = function(error) {
      download_errors <<- bind_rows(download_errors, tibble(
        source_id = id, url = source_url(id), erreur = conditionMessage(error)
      ))
      message("Capture documentaire non obtenue : ", id)
      NULL
    })
  }
  capture_document("gazette_2026_186", "decret-2026-186.html")
  capture_document("asfc_25_11", "avis-acier-aluminium.html")

  # URL du ZIP trouvée dans la page officielle, sans endpoint supposé
  price_page_path <- capture("statcan_prix", source_url("statcan_prix"), "prix-page.html")
  price_page <- read_html(price_page_path)
  price_links <- html_elements(price_page, "a") |> html_attr("href")
  price_zip_url <- unique(na.omit(price_links[grepl("/tbl/csv/18100245-fra[.]zip$", price_links)]))
  if (length(price_zip_url) != 1L) stop("ZIP officiel des prix introuvable")
  price_zip_path <- capture("statcan_prix_zip", price_zip_url, "prix-moyens.zip")
  zip_entries <- unzip(price_zip_path, list = TRUE)$Name
  price_csv_name <- zip_entries[grepl("^18100245[.]csv$", zip_entries)]
  if (length(price_csv_name) != 1L) stop("CSV de prix inattendu dans le ZIP")
  extraction_dir <- file.path(raw_dir, "prix-extraits")
  dir.create(extraction_dir)
  unzip(price_zip_path, files = price_csv_name, exdir = extraction_dir)
  price_raw <- read_csv2(file.path(extraction_dir, price_csv_name), show_col_types = FALSE)
  if (!all(c("GÉO", "PÉRIODE DE RÉFÉRENCE", "VALEUR") %in% names(price_raw))) {
    stop("Schéma de prix modifié : réviser le parseur")
  }
  prices_qc <- price_raw |> filter(.data[["GÉO"]] == "Québec")
  if (nrow(prices_qc) == 0L) stop("Aucune observation québécoise")
  prices_qc <- prices_qc |>
    mutate(collection_id = collection_id, source_id = "statcan_prix",
           observed_at_utc = manifest$observed_at_utc[manifest$source_id == "statcan_prix_zip"])
  price_key <- intersect(c("PÉRIODE DE RÉFÉRENCE", "VECTEUR"), names(prices_qc))
  if (length(price_key) != 2L) stop("Clé des séries de prix introuvable")
  stopifnot(nrow(distinct(prices_qc, across(all_of(price_key)))) == nrow(prices_qc))

  # Une base SQLite autonome par collecte, sans remplacement des versions
  database_path <- file.path(collection_dir, "tarifs-quebec.sqlite")
  connection <- dbConnect(SQLite(), database_path)
  on.exit(dbDisconnect(connection), add = TRUE)
  dbWithTransaction(connection, {
    dbWriteTable(connection, "inventaire_sources", sources)
    dbWriteTable(connection, "captures_sources", manifest)
    dbWriteTable(connection, "erreurs_capture", download_errors)
    dbWriteTable(connection, "observations_contre_tarifs", tariff_observations)
    dbWriteTable(connection, "prix_moyens_quebec", prices_qc)
    dbExecute(connection, "CREATE UNIQUE INDEX cle_tarif ON observations_contre_tarifs(collection_id, source_table, code_tarifaire)")
    dbExecute(connection, 'CREATE UNIQUE INDEX cle_prix ON prix_moyens_quebec(collection_id, "PÉRIODE DE RÉFÉRENCE", "VECTEUR")')
  })
  stopifnot(dbGetQuery(connection, "PRAGMA integrity_check")[[1]] == "ok")
  write_csv(tariff_observations, file.path(collection_dir, "contre-tarifs-observations.csv"))
  write_csv(prices_qc, file.path(collection_dir, "prix-moyens-quebec.csv"))
  quality <- tibble(
    controle = c("Codes tarifaires sur huit chiffres", "Clé unique par tableau tarifaire",
                 "Clé unique par mois et série de prix", "Intégrité SQLite"),
    resultat = rep("réussi", 4)
  )
  write_csv(quality, file.path(collection_dir, "controles-qualite.csv"))
  write_csv(download_errors, file.path(collection_dir, "erreurs-capture.csv"))
  summary <- list(
    collection_id = collection_id, date_reference_projet = "2026-10-05",
    mode = if (is.null(replay_dir)) "collecte_en_ligne" else "relecture_sources_conservees",
    source_collection = if (is.null(replay_dir)) NA_character_ else basename(replay_dir),
    lignes_contre_tarifs = nrow(tariff_observations),
    lignes_par_tableau = as.list(table(tariff_observations$source_table)),
    lignes_prix_quebec = nrow(prices_qc),
    premiere_periode_prix = min(prices_qc[["PÉRIODE DE RÉFÉRENCE"]]),
    derniere_periode_prix = max(prices_qc[["PÉRIODE DE RÉFÉRENCE"]]),
    valeurs_prix_manquantes = sum(is.na(prices_qc[["VALEUR"]])),
    sources_inventoriees = nrow(sources), captures_effectuees = nrow(manifest),
    captures_documentaires_non_obtenues = nrow(download_errors),
    limites = c("Historique des surtaxes extrait des panneaux récapitulatifs; droits totaux et remises non calculés.",
                "Une période de panneau n'est pas automatiquement la période juridique d'un droit.",
                "Les automobiles et les autres mesures maintenues nécessitent une validation séparée.",
                "Échanges québécois détaillés et tarifs de base non encore intégrés.",
                "Aucune correspondance SH-prix et aucune estimation causale n'ont été appliquées.")
  )
  write_json(summary, file.path(collection_dir, "bilan.json"), pretty = TRUE, auto_unbox = TRUE)
  writeLines(capture.output(sessionInfo()), file.path(collection_dir, "session-R.txt"))
  message("Collecte terminée : ", collection_dir)
  print(summary[c("lignes_contre_tarifs", "lignes_prix_quebec", "premiere_periode_prix", "derniere_periode_prix")])
}

main()
