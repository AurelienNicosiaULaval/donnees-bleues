# Examiner les intervalles d'observation sans interprétation causale.
# Exécuter depuis la racine de la trousse entièrement extraite.
library(readr)
library(dplyr)
library(ggplot2)

positions <- read_csv("data/processed/caribous-riviere-aux-feuilles/positions_caribous.csv",
  col_types = cols(id_individu_source = col_character(), id_annee_source = col_character(),
    id_depuis_idyr = col_character(), heure_source = col_character(),
    date_heure_source = col_character()), show_col_types = FALSE)
pas <- read_csv("data/processed/caribous-riviere-aux-feuilles/pas_caribous.csv",
  col_types = cols(id_individu_source = col_character(),
    date_heure_depart = col_character(), date_heure_arrivee = col_character()), show_col_types = FALSE) |>
  mutate(vitesse_ligne_droite_kmh = vitesse_pas_m_h / 1000)
segments <- read_csv("data/processed/caribous-riviere-aux-feuilles/segments_caribous.csv",
  col_types = cols(id_individu_source = col_character(), id_annees_source = col_character(),
    date_heure_debut = col_character(), date_heure_fin = col_character()), show_col_types = FALSE)

# Les pas restent dans leur segment; une position initiale n'a pas de pas entrant.
stopifnot(nrow(positions) == 1911L, nrow(segments) == 319L, nrow(pas) == 1592L,
  nrow(pas) == nrow(positions) - nrow(segments),
  !anyDuplicated(segments$cle_segment), all(pas$cle_segment %in% segments$cle_segment),
  all(pas$duree_h > 0), all(positions$id_individu_source %in% segments$id_individu_source))

effectifs <- positions |> group_by(type_deplacement) |> summarise(
  positions = n(), individus = n_distinct(id_individu_source),
  segments = n_distinct(cle_segment), .groups = "drop")
print(effectifs)

# Chaque ligne pèse un pas : ce résumé ne donne pas un poids égal aux individus.
intervalles <- pas |> group_by(type_deplacement) |> summarise(
  pas = n(), mediane_h = median(duree_h), minimum_h = min(duree_h),
  maximum_h = max(duree_h), au_dela_13_1h = sum(intervalle_sup_13_1h), .groups = "drop")
print(intervalles)
print(positions |> filter(!id_coherent) |>
  select(id_individu_source, id_annee_source, cle_segment, date_heure_source))

graphique <- ggplot(pas, aes(x = duree_h, y = vitesse_ligne_droite_kmh,
                           color = type_deplacement)) +
  geom_point(alpha = 0.5, size = 1.4) +
  scale_color_manual(values = c("Traversée sur glace" = "#087A94",
    "Traversée à la nage" = "#D26B29", "Contournement" = "#724E91")) +
  labs(x = "Intervalle entre deux observations (heures civiles)",
    y = "Vitesse par ligne droite (km/h)", color = "Type du segment",
    caption = "Extraits sélectionnés; mesures répétées. Datum GPS : hypothèse WGS84. Fuseau non documenté.") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom")
print(graphique)

# La vitesse moyenne temporelle d'un segment est distance totale / durée totale.
resume_segments <- pas |> group_by(cle_segment) |> summarise(
  distance_km = sum(distance_ligne_droite_m) / 1000, duree_h = sum(duree_h),
  moyenne_non_ponderee_kmh = mean(vitesse_ligne_droite_kmh), .groups = "drop") |>
  mutate(vitesse_par_duree_kmh = distance_km / duree_h)
print(resume_segments |> arrange(desc(abs(moyenne_non_ponderee_kmh - vitesse_par_duree_kmh))) |> head(10))
