# Concise labels shared by resource pages and catalogues.
# Source conditions and dates remain in their original metadata fields.
editorial_text <- function(value, fallback = "") {
  values <- trimws(as.character(unlist(value, use.names = FALSE)))
  values <- values[!is.na(values) & nzchar(values)]
  if (length(values)) paste(values, collapse = "; ") else fallback
}

editorial_sentences <- function(value) {
  values <- trimws(as.character(unlist(value, use.names = FALSE)))
  values <- values[!is.na(values) & nzchar(values)]
  paste(ifelse(grepl('[.!?]$', values), values, paste0(values, '.')), collapse = ' ')
}

editorial_license <- function(value) {
  value <- editorial_text(value, "Conditions à consulter")
  if (grepl("Aucune licence ouverte", value, ignore.case = TRUE)) return("Réutilisation à valider")
  if (grepl("ECCC", value, fixed = TRUE) && grepl("CC.?BY", value, ignore.case = TRUE)) {
    return("Licences distinctes selon les fichiers")
  }
  if (grepl("ECCC", value, fixed = TRUE)) return("Licence d’ECCC")
  if (grepl("MIT|CC0", value) && grepl(";", value, fixed = TRUE)) return("Licences distinctes selon les fichiers")
  if (grepl("CC.?BY.?NC.?SA", value, ignore.case = TRUE)) return("CC BY-NC-SA")
  if (grepl("CC.?BY.?NC", value, ignore.case = TRUE)) return("CC BY-NC")
  if (grepl("CC.?BY.?SA", value, ignore.case = TRUE)) return("CC BY-SA")
  if (grepl("CC.?BY.?4[.]0", value, ignore.case = TRUE) &&
      !grepl(";|MIT|CC0|Canada|distinct", value, ignore.case = TRUE)) return("CC BY 4.0")
  if (grepl("Licence ouverte de Statistique Canada", value, ignore.case = TRUE)) return("Licence ouverte de Statistique Canada")
  if (grepl("Licence du gouvernement ouvert", value, ignore.case = TRUE) &&
      !grepl(";|SAAQ|CC.?BY", value, ignore.case = TRUE)) return("Licence du gouvernement ouvert du Canada")
  # Mixed or restricted conditions must not become an unrestricted licence label.
  if (grepl("ISQ|reproduction|redistribution|institutionnel|conditions", value, ignore.case = TRUE)) return("Conditions particulières")
  "Conditions particulières"
}

editorial_duration <- function(value) {
  # Durations used for filtering omit optional extensions; the full label remains
  # in the activity metadata and on its detail page.
  value <- as.character(value)
  sub(" minutes.*$", " minutes", value)
}

editorial_dataset_metadata <- function(root = ".") {
  paths <- list.files(file.path(root, "datasets"), pattern = "^metadata[.]yml$",
                     recursive = TRUE, full.names = TRUE)
  items <- lapply(paths, yaml::read_yaml)
  setNames(items, vapply(items, function(item) item$id, character(1)))
}

editorial_sources <- function(metadata) {
  value <- metadata$source_authors
  if (is.null(value)) value <- metadata$organisme
  if (is.null(value)) value <- metadata$source_name
  as.character(unlist(value, use.names = FALSE))
}

editorial_course_label <- function(courses) {
  values <- as.character(unlist(courses, use.names = FALSE))
  if (length(values) == 2L && all(grepl("STT-(4230|6230)", values)) &&
      all(grepl("Programmation pour la science des données", values))) {
    return("STT-4230 et STT-6230, Programmation pour la science des données, Université Laval")
  }
  editorial_text(values, "Usage en cours non documenté")
}
