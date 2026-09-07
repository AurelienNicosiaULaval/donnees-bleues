# Exécuter une seule fois si les bibliothèques nécessaires sont absentes.
# Quarto et R doivent être installés séparément.
paquets <- c("readr", "dplyr", "tidyr", "ggplot2", "knitr", "scales", "rmarkdown")
absents <- paquets[!vapply(paquets, requireNamespace, logical(1), quietly = TRUE)]
if (length(absents)) {
  install.packages(absents, repos = "https://cloud.r-project.org")
}
message("Bibliothèques disponibles. Ouvrez un fichier .qmd et cliquez sur Render.")
# sf est facultatif : nécessaire seulement pour recréer l’extrait géospatial.
