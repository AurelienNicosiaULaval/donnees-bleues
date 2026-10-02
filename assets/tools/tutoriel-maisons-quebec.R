# Données bleues : tutoriel Maisons à Québec
# Aurélien Nicosia (2026). Code MIT; données MAMH et contenus CC BY 4.0.
# Valeurs au rôle 2025, référence au marché 2023-07-01, extraction 2026.

# Charger explicitement les bibliothèques.
library(readr)
library(dplyr)
library(ggplot2)
library(scales)

# Dans le dépôt, utiliser le CSV figé; ailleurs, utiliser le fichier
# téléchargé ou récupérer cette même version publique.
fichier <- "maisons-quebec.csv"
if (file.exists("assets/data/maisons-quebec.csv")) {
  fichier <- "assets/data/maisons-quebec.csv"
} else if (file.exists("../assets/data/maisons-quebec.csv")) {
  fichier <- "../assets/data/maisons-quebec.csv"
}
if (!file.exists(fichier)) {
  download.file("https://donneesbleues.ca/assets/data/maisons-quebec.csv",
                fichier, mode = "wb")
}
maisons <- read_csv(fichier, show_col_types = FALSE, col_types = cols(
  maison_id = col_character(),
  arrondissement_code = col_character(),
  voisinage_code = col_character(),
  lien_physique_code = col_character(),
  genre_construction_code = col_character()
))
stopifnot(nrow(maisons) == 600L, ncol(maisons) == 19L,
          !anyDuplicated(maisons$maison_id),
          all(maisons$annee_role == 2025),
          all(maisons$date_reference_marche == as.Date("2023-07-01")))

maisons |>
  summarise(
    nombre = n(),
    valeurs_manquantes = sum(is.na(pick(everything()))),
    valeur_mediane_cad = median(valeur_fonciere_cad),
    aire_mediane_m2 = median(aire_etages_m2)
  )

maisons_filtrees <- maisons |>
  filter(
    lien_physique %in% c("Détaché", "Jumelé"),
    between(annee_construction, 1950, 2000)
  )

resume_groupes <- maisons_filtrees |>
  group_by(lien_physique) |>
  summarise(
    nombre = n(),
    valeur_mediane_cad = median(valeur_fonciere_cad),
    aire_mediane_m2 = median(aire_etages_m2),
    .groups = "drop"
  )
resume_groupes
stopifnot(nrow(maisons_filtrees) == 403L)

# Conserver les observations utilisables pour les deux échelles.
donnees_graphique <- maisons_filtrees |>
  filter(if_all(c(aire_etages_m2, valeur_fonciere_cad),
                ~ is.finite(.x) & .x > 0))
nrow(maisons_filtrees) - nrow(donnees_graphique)

nombres <- label_number(big.mark = " ", decimal.mark = ",")
nuage <- ggplot(donnees_graphique,
                aes(aire_etages_m2, valeur_fonciere_cad)) +
  geom_point(colour = "#185b83", alpha = 0.45, size = 1.8) +
  labs(x = "Aire d’étages brute (m²)",
       y = "Valeur foncière évaluée (CAD)") +
  theme_minimal(base_size = 14) +
  theme(panel.grid.minor = element_blank())

graphique_brut <- nuage +
  scale_x_continuous(labels = nombres) +
  scale_y_continuous(labels = nombres)
graphique_brut

graphique_log <- nuage +
  scale_x_log10(labels = nombres) +
  scale_y_log10(labels = nombres)
graphique_log

boites <- ggplot(donnees_graphique,
                 aes(lien_physique, valeur_fonciere_cad)) +
  geom_boxplot(outlier.shape = NA, fill = "#dceaf0", colour = "#185b83") +
  geom_point(
    position = position_jitter(width = 0.14, height = 0, seed = 20261001),
    alpha = 0.35, colour = "#185b83", size = 1.2
  ) +
  scale_y_continuous(labels = nombres) +
  labs(x = "Type de maison", y = "Valeur foncière évaluée (CAD)") +
  theme_minimal(base_size = 14)
boites

# write_csv(maisons_filtrees, "maisons-filtrees.csv")
# ggsave("maisons-graphique.png", graphique_log,
#        width = 9, height = 5.5, dpi = 160, bg = "white")

maisons |>
  filter(lien_physique %in% c("Détaché", "Jumelé")) |>
  group_by(lien_physique) |>
  summarise(nombre = n(),
            valeur_mediane_cad = median(valeur_fonciere_cad),
            aire_mediane_m2 = median(aire_etages_m2),
            .groups = "drop")
