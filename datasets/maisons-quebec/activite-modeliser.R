# Régression et validation par voisinage, 120 minutes indicatives.
# Ouvrir le projet RStudio de la trousse, puis cliquer Source.
# Cible : valeur au rôle municipal, pas prix de vente. Données MAMH, CC BY 4.0.
library(readr)
library(dplyr)
library(ggplot2)

maisons <- read_csv("data/processed/maisons-quebec/maisons_quebec.csv",
  col_types = cols(maison_id = col_character(), arrondissement_code = col_character(),
    voisinage_code = col_character(), lien_physique_code = col_character(),
    genre_construction_code = col_character()), show_col_types = FALSE)
stopifnot(nrow(maisons) == 600L, !anyDuplicated(maisons$maison_id))
dir.create("outputs", showWarnings = FALSE)

# 1. Prétraitement fixé avant d'observer les résultats du test.
# Regroupement des deux modalités en rangée selon leur définition, pas selon leur valeur.
# Les lignes incomplètes sont comptées; aucune imputation globale avant la séparation.
analyse <- maisons |>
  mutate(type_maison = factor(case_when(lien_physique_code == "1" ~ "Détaché",
    lien_physique_code == "2" ~ "Jumelé", lien_physique_code %in% c("3", "4") ~ "En rangée"),
    levels = c("Détaché", "Jumelé", "En rangée")),
    annee_centree = annee_construction - 1970) |>
  filter(is.finite(valeur_fonciere_cad), valeur_fonciere_cad > 0,
    is.finite(aire_etages_m2), aire_etages_m2 > 0,
    is.finite(superficie_terrain_m2), superficie_terrain_m2 > 0,
    is.finite(annee_centree), !is.na(type_maison), !is.na(voisinage_code))
effectifs <- tibble(etape = c("CSV", "Cas utilisables", "Cas écartés pour l'activité"),
  n = c(nrow(maisons), nrow(analyse), nrow(maisons) - nrow(analyse)))
stopifnot(nrow(analyse) > 100L)

# 2. Test réservé : environ 20 % des codes de voisinage, jamais utilisés pour choisir le modèle.
# Les codes administratifs ne sont pas une garantie d'indépendance spatiale.
RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
set.seed(20261002)
groupes <- sort(unique(analyse$voisinage_code))
stopifnot(length(groupes) >= 10L)
groupes_test <- sample(groupes, max(1L, floor(0.20 * length(groupes))), replace = FALSE)
apprentissage <- analyse |> filter(!voisinage_code %in% groupes_test)
test <- analyse |> filter(voisinage_code %in% groupes_test)
stopifnot(!length(intersect(apprentissage$voisinage_code, test$voisinage_code)),
  all(levels(analyse$type_maison) %in% as.character(apprentissage$type_maison)))
partage <- analyse |> transmute(maison_id, voisinage_code,
  ensemble = if_else(voisinage_code %in% groupes_test, "Test", "Apprentissage"))
partage_resume <- partage |> group_by(ensemble) |>
  summarise(maisons = n(), voisinages = n_distinct(voisinage_code), .groups = "drop")

# 3. Modèles fixés, uniquement des caractéristiques physiques.
# Interdiction de prédire le total avec ses composantes terrain + bâtiment.
formule_simple <- valeur_fonciere_cad ~ aire_etages_m2
formule_log <- log(valeur_fonciere_cad) ~ log(aire_etages_m2) +
  log(superficie_terrain_m2) + annee_centree + type_maison
modele_simple <- lm(formule_simple, data = apprentissage)
modele_log <- lm(formule_log, data = apprentissage)
# Correction de retransformation estimée seulement dans l'apprentissage.
# Elle vise une moyenne en dollars; elle n'assure pas une moyenne conditionnelle exacte.
smearing <- mean(exp(residuals(modele_log)))
predictions <- test |> transmute(maison_id, voisinage_code, observe_cad = valeur_fonciere_cad,
  reference_mediane = median(apprentissage$valeur_fonciere_cad),
  reference_moyenne = mean(apprentissage$valeur_fonciere_cad),
  regression_simple = as.numeric(predict(modele_simple, newdata = test)),
  regression_log = exp(as.numeric(predict(modele_log, newdata = test))) * smearing)
model_names <- c("reference_mediane", "reference_moyenne", "regression_simple", "regression_log")
scores <- bind_rows(lapply(model_names, function(name) {
  error <- predictions[[name]] - predictions$observe_cad
  tibble(modele = name, n_test = nrow(test), mae_cad = mean(abs(error)),
    rmse_cad = sqrt(mean(error^2)), biais_cad = mean(error))
}))

# 4. Validation croisée facultative, uniquement dans l'apprentissage (5 plis par voisinage).
train_groups <- sort(unique(apprentissage$voisinage_code))
fold_ids <- sample(rep(1:5, length.out = length(train_groups)))
plis <- tibble(voisinage_code = train_groups, pli = fold_ids)
train_cv <- apprentissage |> left_join(plis, by = "voisinage_code")
cv_predictions <- bind_rows(lapply(1:5, function(k) {
  fitting <- train_cv |> filter(pli != k)
  held_out <- train_cv |> filter(pli == k)
  stopifnot(!length(intersect(fitting$voisinage_code, held_out$voisinage_code)),
    all(levels(analyse$type_maison) %in% as.character(fitting$type_maison)))
  m <- lm(formule_log, data = fitting)
  retransformation <- mean(exp(residuals(m)))
  held_out |> transmute(maison_id, pli, observe_cad = valeur_fonciere_cad,
    prediction_cad = exp(as.numeric(predict(m, newdata = held_out))) * retransformation,
    reference_mediane = median(fitting$valeur_fonciere_cad))
}))
stopifnot(nrow(cv_predictions) == nrow(apprentissage),
  !anyDuplicated(cv_predictions$maison_id), all(is.finite(cv_predictions$prediction_cad)))
cv_scores <- bind_rows(lapply(c("reference_mediane", "prediction_cad"), function(name) {
  error <- cv_predictions[[name]] - cv_predictions$observe_cad
  tibble(modele = name, n = nrow(cv_predictions), mae_cad = mean(abs(error)),
    rmse_cad = sqrt(mean(error^2)))
}))
coefficients <- tibble(terme = names(coef(modele_log)), estimation = unname(coef(modele_log)))
diagnostic <- tibble(ajuste_log = fitted(modele_log), residu_log = residuals(modele_log),
  levier = hatvalues(modele_log), distance_cook = cooks.distance(modele_log),
  maison_id = apprentissage$maison_id)
influence <- diagnostic |> arrange(desc(distance_cook)) |> slice_head(n = 5)
residual_plot <- ggplot(diagnostic, aes(x = ajuste_log, y = residu_log)) +
  geom_point(alpha = 0.55, colour = "#185b83") + geom_hline(yintercept = 0, colour = "#b95319") +
  labs(x = "Log de la valeur ajustée", y = "Résidu sur l'échelle logarithmique",
    title = "Diagnostics dans l'apprentissage") + theme_minimal(base_size = 12)
prediction_plot <- ggplot(predictions, aes(x = observe_cad, y = regression_log)) +
  geom_abline(slope = 1, intercept = 0, colour = "#b95319") +
  geom_point(alpha = 0.6, colour = "#185b83") +
  scale_x_continuous(labels = scales::label_number(big.mark = " ")) +
  scale_y_continuous(labels = scales::label_number(big.mark = " ")) +
  coord_equal() + labs(x = "Valeur foncière observée (CAD)",
    y = "Valeur prédite (CAD)", title = "Voisinages réservés au test") + theme_minimal(base_size = 12)

# 5. Résultats reproductibles, pas de conclusion causale ni de prévision des ventes futures.
print(effectifs); print(partage_resume); print(coefficients); print(scores); print(cv_scores)
print(influence); print(residual_plot); print(prediction_plot)
write_csv(effectifs, "outputs/maisons-effectifs-modele.csv")
write_csv(partage, "outputs/maisons-partage.csv")
write_csv(scores, "outputs/maisons-scores-test.csv")
write_csv(cv_scores, "outputs/maisons-scores-cv.csv")
write_csv(cv_predictions, "outputs/maisons-predictions-cv.csv")
write_csv(predictions, "outputs/maisons-predictions-test.csv")
write_csv(coefficients, "outputs/maisons-coefficients.csv")
write_csv(influence, "outputs/maisons-influence.csv")
ggsave("outputs/maisons-residus.png", residual_plot, width = 8, height = 5, dpi = 160)
ggsave("outputs/maisons-test.png", prediction_plot, width = 7, height = 6, dpi = 160)
capture.output(sessionInfo(), file = "outputs/sessionInfo.txt")
message("Validation de valeurs foncières dans l'instantané. Aucune mesure de performance sur les ventes.")
