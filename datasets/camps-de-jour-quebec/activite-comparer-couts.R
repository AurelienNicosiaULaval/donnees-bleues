# Comparer des composantes documentées dans le pilote 2026.
# Exécuter depuis la racine de la trousse entièrement extraite.
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

programmes <- read_csv("data/processed/camps-de-jour-quebec/programmes.csv", na = c("", "NA"), show_col_types = FALSE)
tarifs <- read_csv("data/processed/camps-de-jour-quebec/tarifs.csv", na = c("", "NA"), show_col_types = FALSE)
faits <- read_csv("data/processed/camps-de-jour-quebec/faits.csv", na = c("", "NA"), show_col_types = FALSE)
preuves <- read_csv("data/processed/camps-de-jour-quebec/preuves.csv", na = c("", "NA"), show_col_types = FALSE)
sources <- read_csv("data/processed/camps-de-jour-quebec/sources.csv", na = c("", "NA"), show_col_types = FALSE)
scenario <- read_csv("data/processed/camps-de-jour-quebec/scenario.csv", na = c("", "NA"), show_col_types = FALSE)
composantes <- read_csv("data/processed/camps-de-jour-quebec/calculs_scenario.csv", na = c("", "NA"), show_col_types = FALSE)
qualite <- read_csv("data/processed/camps-de-jour-quebec/qualite.csv", na = c("", "NA"), show_col_types = FALSE)

# Vérifier les relations avant les jointures; une ligne de tarif n'est pas un camp.
stopifnot(!anyDuplicated(programmes$programme_id), !anyDuplicated(tarifs$tarif_id),
  !anyDuplicated(preuves$preuve_id), !anyDuplicated(sources$source_id),
  all(tarifs$programme_id %in% programmes$programme_id),
  all(tarifs$preuve_id %in% preuves$preuve_id),
  all(preuves$source_id %in% sources$source_id))

print(tarifs |> count(periode, base_facturation, name = "lignes_de_tarif"))
print(faits |> count(statut, name = "champs"))

# Recalculer à partir des identifiants de tarifs et des multiplicateurs publiés,
# plutôt qu'employer les montants déjà copiés dans calculs_scenario.csv.
recalcul <- composantes |> select(programme_id, tarif_id, multiplicateur) |>
  left_join(select(tarifs, tarif_id, montant_min, montant_max), by = "tarif_id") |>
  group_by(programme_id) |> summarise(
    montant_min_recalcule = sum(montant_min * multiplicateur),
    montant_max_recalcule = sum(montant_max * multiplicateur), .groups = "drop") |>
  left_join(scenario, by = "programme_id")
stopifnot(!anyNA(recalcul$montant_min_recalcule),
  all(abs(recalcul$montant_min_recalcule - recalcul$montant_min) < 1e-8),
  all(abs(recalcul$montant_max_recalcule - recalcul$montant_max) < 1e-8))
print(recalcul |> select(municipalite, montant_min_recalcule, montant_max_recalcule, statut))
print(scenario |> filter(is.na(montant_min)) |> select(municipalite, reserve))

# Les deux tarifs de Victoriaville ci-dessous ont des grains différents :
# deuxième enfant à la semaine, et chaque enfant d'une famille de deux à la journée.
print(tarifs |> filter(programme_id == "victoriaville_municipal",
  (periode == "semaine" & rang_min == 2) |
  (periode == "jour" & famille_min == 2)) |>
  select(composante, montant_min, periode, base_facturation, rang_min, famille_min, condition))

documentation_tarifs <- tarifs |> left_join(
  select(preuves, preuve_id, source_id, url, retrieved_at, ligne_txt, localisation), by = "preuve_id")
print(documentation_tarifs |> filter(programme_id == "rimouski_municipal", residence == "resident",
  rang_min == 1, periode == "semaine") |> select(composante, montant_min, url, retrieved_at))
print(qualite)

graphique <- recalcul |>
  mutate(programme = if_else(programme_id == "sherbrooke_actifamille", "Sherbrooke (Acti-Famille)", municipalite)) |>
  ggplot(aes(x = reorder(programme, montant_min_recalcule),
    y = montant_min_recalcule, colour = statut)) +
  geom_linerange(aes(ymin = montant_min_recalcule, ymax = montant_max_recalcule), linewidth = 1.4) +
  geom_point(size = 3) + coord_flip() +
  scale_colour_manual(values = c(somme_tarifs_documentes = "#1e5a81", calcul_conditionnel = "#bf853c"),
    labels = c(calcul_conditionnel = "Calcul conditionnel", somme_tarifs_documentes = "Postes documentés")) +
  labs(x = NULL, y = "Sous-total affiché (CAD)", colour = NULL,
    title = "Quatre semaines avec couverture de 7 h 30 à 17 h 30",
    subtitle = "Premier enfant résident de 7 ans; pilote été 2026",
    caption = "Sorties facultatives et aides exclues; taxes souvent non précisées.\nCe calcul ne recherche pas le forfait d'achat le moins cher.") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom")
print(graphique)
