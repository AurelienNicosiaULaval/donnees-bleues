# Carte et qualité des données des arbres publics
# Ouvrir le projet RStudio de l’archive, puis exécuter ce script.
# Source : https://www.donneesquebec.ca/recherche/dataset/vmtl-arbres
# Les données de classe sont figées; ce script ne les télécharge pas.

library(dplyr)
library(readr)
library(ggplot2)

donnees <- read_csv("data/processed/arbres-publics-montreal/arbres_publics_montreal.csv", col_types = cols(.default = col_skip(), arrondissement = col_character(), essence_fr = col_character(), dhp = col_double()), show_col_types = FALSE)
stopifnot(nrow(donnees) > 0)

resume <- donnees |> group_by(arrondissement) |> summarise(
  arbres = n(), essences = n_distinct(essence_fr, na.rm = TRUE),
  diametres_connus = sum(!is.na(dhp)), diametre_median_cm = median(dhp, na.rm = TRUE),
  .groups = "drop")
print(resume)
print(ggplot(resume, aes(x = reorder(arrondissement, diametre_median_cm), y = diametre_median_cm)) +
  geom_col() + coord_flip() + labs(x = "Arrondissement", y = "Diamètre médian à hauteur de poitrine (cm)",
    subtitle = "Inventaire des arbres publics; couverture et dates à vérifier"))
