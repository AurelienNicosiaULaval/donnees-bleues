# Activité d'introduction, 60 à 90 minutes : valeurs foncières de 600 maisons.
# Ouvrir Donnees-bleues.Rproj dans la trousse extraite, puis cliquer Source.
# Données figées MAMH, CC BY 4.0. Aucune connexion requise après installation.
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

# 1. Comprendre les données, préserver les codes de voisinage comme du texte.
maisons <- read_csv("data/processed/maisons-quebec/maisons_quebec.csv",
  col_types = cols(maison_id = col_character(), arrondissement_code = col_character(),
    voisinage_code = col_character(), lien_physique_code = col_character(),
    genre_construction_code = col_character()), show_col_types = FALSE)
stopifnot(nrow(maisons) == 600L, ncol(maisons) == 19L,
  !anyDuplicated(maisons$maison_id), all(maisons$municipalite == "Québec"),
  all(maisons$nombre_logements == 1), all(maisons$annee_role == 2025),
  all(maisons$date_reference_marche == as.Date("2023-07-01")))
dir.create("outputs", showWarnings = FALSE)

# 2. Audit sans imputation ni retrait automatique des observations extrêmes.
manquants <- maisons |> summarise(across(everything(), ~sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_manquants")
portrait <- maisons |> group_by(lien_physique) |> summarise(
  effectif = n(), valeurs_connues = sum(!is.na(valeur_fonciere_cad)),
  moyenne_cad = mean(valeur_fonciere_cad, na.rm = TRUE),
  mediane_cad = median(valeur_fonciere_cad, na.rm = TRUE),
  iqr_cad = IQR(valeur_fonciere_cad, na.rm = TRUE),
  .groups = "drop")
resume_valeur <- maisons |> summarise(
  n = sum(!is.na(valeur_fonciere_cad)),
  moyenne = mean(valeur_fonciere_cad, na.rm = TRUE),
  mediane = median(valeur_fonciere_cad, na.rm = TRUE),
  minimum = min(valeur_fonciere_cad, na.rm = TRUE),
  maximum = max(valeur_fonciere_cad, na.rm = TRUE))
estimees <- maisons |> count(annee_construction_statut, name = "effectif")

# Les logarithmes et la corrélation utilisent des paires finies et strictement positives.
paires <- maisons |> filter(is.finite(aire_etages_m2), aire_etages_m2 > 0,
  is.finite(valeur_fonciere_cad), valeur_fonciere_cad > 0)
correlations <- tibble(echelle = c("Brute", "Logarithmique"), n = nrow(paires),
  correlation = c(cor(paires$aire_etages_m2, paires$valeur_fonciere_cad),
    cor(log(paires$aire_etages_m2), log(paires$valeur_fonciere_cad))))

# 3. Visualiser les observations, pas seulement leurs résumés.
distribution_plot <- ggplot(maisons, aes(x = valeur_fonciere_cad)) +
  geom_histogram(bins = 30, fill = "#185b83", colour = "white", na.rm = TRUE) +
  scale_x_continuous(labels = scales::label_number(big.mark = " ")) +
  labs(x = "Valeur foncière évaluée (CAD)", y = "Nombre de maisons",
    title = "600 maisons à Québec", subtitle = "Référence au marché : 1er juillet 2023") +
  theme_minimal(base_size = 12)
group_plot <- ggplot(maisons, aes(x = lien_physique, y = valeur_fonciere_cad)) +
  geom_boxplot(outlier.shape = NA, fill = "#dbeaf2", na.rm = TRUE) +
  geom_point(position = position_jitter(width = 0.15, height = 0, seed = 20261001),
    alpha = 0.35, size = 1, na.rm = TRUE) +
  scale_y_continuous(labels = scales::label_number(big.mark = " ")) +
  coord_flip() + labs(x = NULL, y = "Valeur foncière évaluée (CAD)") +
  theme_minimal(base_size = 12)
scatter_plot <- ggplot(paires, aes(x = aire_etages_m2, y = valeur_fonciere_cad,
                                  colour = lien_physique)) +
  geom_point(alpha = 0.65, size = 1.8) +
  scale_colour_brewer(palette = "Dark2") +
  scale_y_continuous(labels = scales::label_number(big.mark = " ")) +
  labs(x = "Aire d'étages brute (m²)", y = "Valeur foncière évaluée (CAD)",
    colour = "Lien physique", caption = paste(nrow(maisons) - nrow(paires),
      "ligne(s) écartée(s) : paire manquante, non finie ou non positive.")) +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom")
log_plot <- scatter_plot + scale_x_log10() +
  scale_y_log10(labels = scales::label_number(big.mark = " ")) +
  labs(title = "Les mêmes observations, sur des axes logarithmiques")

# 4. Résultats à interpréter dans le périmètre du rôle municipal retenu.
print(manquants); print(portrait); print(resume_valeur); print(estimees); print(correlations)
print(distribution_plot); print(group_plot); print(scatter_plot); print(log_plot)
write_csv(portrait, "outputs/maisons-portrait.csv")
write_csv(manquants, "outputs/maisons-manquants.csv")
write_csv(correlations, "outputs/maisons-correlations.csv")
ggsave("outputs/maisons-distribution.png", distribution_plot, width = 8, height = 5, dpi = 160)
ggsave("outputs/maisons-groupes.png", group_plot, width = 8, height = 5, dpi = 160)
ggsave("outputs/maisons-association.png", scatter_plot, width = 9, height = 6, dpi = 160)
ggsave("outputs/maisons-log.png", log_plot, width = 9, height = 6, dpi = 160)
message("Les valeurs évaluées ne sont pas des prix de vente. Les associations sont descriptives.")
