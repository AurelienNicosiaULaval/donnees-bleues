# Ouvrir Donnees-bleues.Rproj, puis cliquer sur Source dans RStudio.
# Les CSV sont inclus. Aucun téléchargement n'est effectué pendant l'activité.
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

passagers <- read_csv("data/processed/empress-of-ireland/empress_passengers.csv", show_col_types = FALSE)
equipage <- read_csv("data/processed/empress-of-ireland/empress_crew_groups.csv", show_col_types = FALSE)
stopifnot(nrow(passagers) == 24L, sum(passagers$frequency) == 1057L,
  sum(passagers$frequency[passagers$survived == 1L]) == 217L)
passagers <- passagers |>
  mutate(classe = factor(class, c("first", "second", "third"), c("1re", "2e", "3e")),
    sexe = factor(sex, c("male", "female"), c("Masculin", "Féminin")),
    age = factor(age_group, c("adult", "child"), c("Adulte", "Enfant")),
    statut = factor(survived, c(0, 1), c("Décès", "Survie")))

groupes_source <- read_csv("data/processed/empress-of-ireland/empress_passenger_groups.csv", show_col_types = FALSE)
comparaison <- read_csv("data/processed/empress-of-ireland/empress_sources_comparison.csv", show_col_types = FALSE)
stopifnot(nrow(groupes_source) == 12L, sum(groupes_source$total) == 1057L,
  sum(groupes_source$survivors) == 217L, sum(comparaison$listed_people) == 1472L,
  sum(comparaison$unknown_status) == 1019L)

# Une ligne représente une cellule de tableau; il faut additionner frequency.
portrait <- passagers |>
  group_by(classe) |>
  summarise(personnes = sum(frequency), survivants = sum(frequency[survived == 1L]),
    deces = personnes - survivants, proportion_survie = survivants / personnes, .groups = "drop")
strates <- passagers |>
  group_by(classe, sexe, age) |>
  summarise(personnes = sum(frequency), survivants = sum(frequency[survived == 1L]),
    deces = personnes - survivants, .groups = "drop") |>
  mutate(proportion_survie = if_else(personnes > 0L, survivants / personnes, NA_real_))
contingence <- xtabs(frequency ~ classe + statut, data = passagers)

theme_set(theme_minimal(base_size = 12))
graphique_effectifs <- ggplot(passagers, aes(classe, frequency, fill = statut)) +
  geom_col(width = .65) +
  scale_fill_manual(values = c("#667785", "#0072B2")) +
  labs(x = "Classe des passagers", y = "Nombre de personnes", fill = NULL) +
  theme(legend.position = "bottom")
graphique_proportions <- ggplot(portrait, aes(classe, proportion_survie)) +
  geom_col(fill = "#0072B2", width = .65) +
  geom_text(aes(label = sprintf("%d / %d", survivants, personnes)), vjust = -.5) +
  scale_y_continuous(labels = function(x) paste0(round(100 * x), " %"), limits = c(0, .5)) +
  labs(x = "Classe des passagers", y = "Proportion de survivants")
graphique_strates <- ggplot(filter(strates, personnes > 0L),
    aes(classe, proportion_survie, colour = sexe, size = personnes)) +
  geom_point(position = position_dodge(width = .3)) +
  facet_wrap(~ age) +
  scale_colour_manual(values = c("#0072B2", "#D55E00")) +
  scale_y_continuous(labels = function(x) paste0(round(100 * x), " %"), limits = c(0, .55)) +
  labs(x = "Classe des passagers", y = "Proportion de survivants",
    colour = "Sexe dans le rapport", size = "Effectif") +
  theme(legend.position = "bottom")

# Prolongement facultatif : modèle binomial de comptes regroupés.
# La cellule vide est exclue de l'ajustement, sans inventer de personne.
# L'âge est la catégorie historique; son seuil numérique n'est pas établi ici.
modele <- glm(cbind(survivants, deces) ~ classe + sexe + age,
  family = binomial(), data = filter(strates, personnes > 0L))
coefficients <- tibble(terme = names(coef(modele)), log_rapport_cotes = unname(coef(modele)),
  rapport_cotes = exp(unname(coef(modele))))
ajustement <- filter(strates, personnes > 0L) |>
  mutate(proportion_ajustee = unname(predict(modele, type = "response")))
stopifnot(modele$converged, all(is.finite(coef(modele))),
  abs(sum(ajustement$personnes * ajustement$proportion_ajustee) - 217) < 1e-5)

# Le tableau de l'équipage utilise des départements et rôles, sans inventer
# un croisement sexe-âge absent des tableaux examinés.
bilan <- tibble(groupe = c("Passagers", "Équipage"),
  personnes = c(sum(passagers$frequency), sum(equipage$total)),
  survivants = c(sum(passagers$frequency[passagers$survived == 1L]), sum(equipage$survivors))) |>
  mutate(deces = personnes - survivants, proportion_survie = survivants / personnes)

dir.create("outputs", showWarnings = FALSE)
write_csv(portrait, "outputs/portrait_classes.csv")
write_csv(strates, "outputs/portrait_strates.csv")
write_csv(coefficients, "outputs/regression_logistique.csv")
write_csv(ajustement, "outputs/ajustement_strates.csv")
write_csv(bilan, "outputs/bilan_passagers_equipage.csv")
ggsave("outputs/effectifs.png", graphique_effectifs, width = 7, height = 4.5, dpi = 160)
ggsave("outputs/proportions.png", graphique_proportions, width = 7, height = 4.5, dpi = 160)
ggsave("outputs/strates.png", graphique_strates, width = 8, height = 4.8, dpi = 160)
print(portrait)
print(contingence)
print(strates)
print(bilan)
print(coefficients)
print(graphique_effectifs)
print(graphique_proportions)
print(graphique_strates)
