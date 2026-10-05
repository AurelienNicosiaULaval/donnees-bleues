# Garde-fous sur le grain des prix et les réserves du pilote figé.
root <- file.path("datasets", "camps-de-jour-quebec", "downloads", "20261005T182735Z")
manifest <- jsonlite::read_json(file.path(root, "manifest_publication.json"))
for (table in manifest$tables) {
  path <- file.path(root, table$file)
  stopifnot(digest::digest(file = path, algo = "sha256") == table$sha256)
  x <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(nrow(x) == table$rows, identical(names(x), unlist(table$columns)))
}
tarifs <- readr::read_csv(file.path(root, "tarifs.csv"), show_col_types = FALSE)
scenario <- readr::read_csv(file.path(root, "scenario.csv"), show_col_types = FALSE)
sources <- readr::read_csv(file.path(root, "sources.csv"), show_col_types = FALSE)
stopifnot(!anyDuplicated(tarifs$tarif_id), nrow(sources) == 14L,
  !any(c("path_html", "path_txt", "error") %in% names(sources)))
famille <- tarifs[tarifs$programme_id == "tingwick_municipal" & tarifs$base_facturation == "famille" & tarifs$famille_min == 2, ]
stopifnot(nrow(famille) == 1L, famille$montant_min == 300, famille$periode == "saison", is.na(famille$rang_min))
jour <- tarifs[which(tarifs$programme_id == "victoriaville_municipal" & tarifs$periode == "jour" & tarifs$famille_min == 2), ]
stopifnot(nrow(jour) == 1L, jour$montant_min == 15.5, jour$base_facturation == "enfant_selon_taille_famille", is.na(jour$rang_min))
stopifnot(sum(scenario$statut == "somme_tarifs_documentes") == 6L,
  sum(scenario$statut == "calcul_conditionnel") == 1L,
  sum(is.na(scenario$montant_min)) == 3L,
  scenario$montant_min[scenario$programme_id == "sherbrooke_actifamille"] == 474,
  scenario$montant_max[scenario$programme_id == "sherbrooke_actifamille"] == 506,
  all(tarifs$periode[tarifs$programme_id == "drummondville_ccsp" & tarifs$composante == "camp"] == "non_precisee"))
cat("Camps de jour : empreintes, grains familiaux et exclusions du scénario vérifiés.\n")
