# Comparer deux proportions par permutation. Aurélien Nicosia (2026).
# Code MIT; données SAAQ et contenus originaux CC BY 4.0.
# Rapports publiés pour 2022. Le modèle ne mesure pas un risque par trajet.
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(scales)
})

accident_groups <- c(SEM = "Lundi au vendredi", FDS = "Samedi ou dimanche")
accident_gravity <- c("Dommages matériels seulement",
  "Dommages matériels inférieurs au seuil de rapportage", "Léger", "Mortel ou grave")

read_permutation_accidents <- function(path) {
  data <- read_csv(path, col_types = cols(.default = col_character()),
                   show_col_types = FALSE)
  stopifnot(all(c("annee", "jour_semaine_code", "gravite") %in% names(data)),
    nrow(data) == 108186L, !anyNA(data[c("annee", "jour_semaine_code", "gravite")]),
    all(data$annee == "2022"), all(data$jour_semaine_code %in% names(accident_groups)),
    all(data$gravite %in% accident_gravity))
  data |> transmute(group = jour_semaine_code,
    victim = gravite %in% c("Léger", "Mortel ou grave"))
}

permutation_settings <- function(B = 2000L, seed = 20261003L) {
  stopifnot(length(B) == 1L, is.finite(B), B == as.integer(B), B >= 100L, B <= 20000L,
    length(seed) == 1L, is.finite(seed), seed >= 0, seed <= 2147483646,
    seed == as.integer(seed))
  list(B = as.integer(B), seed = as.integer(seed))
}

permutation_counts <- function(data) {
  stopifnot(is.logical(data$victim), !anyNA(data),
    all(data$group %in% names(accident_groups)), all(names(accident_groups) %in% data$group))
  tibble(group = names(accident_groups), label = unname(accident_groups),
    n = vapply(names(accident_groups), function(g) sum(data$group == g), integer(1)),
    victims = vapply(names(accident_groups), function(g)
      sum(data$victim[data$group == g]), integer(1))) |>
    mutate(proportion = victims / n)
}

# Exact signifie ici : somme de la loi conditionnelle, sans erreur Monte-Carlo.
# Le critère bilatéral est |p_FDS - p_SEM|, avec les égalités incluses.
# Ce n’est pas la convention bilatérale par probabilités de fisher.test().
permutation_exact <- function(n_weekend, n_weekday, victims, observed_weekend) {
  total <- as.double(n_weekend) + n_weekday
  support <- seq.int(max(0, victims - n_weekday), min(victims, n_weekend))
  numerator <- support * total - victims * n_weekend
  observed <- observed_weekend * total - victims * n_weekend
  extreme <- abs(numerator) >= abs(observed)
  min(1, sum(dhyper(support[extreme], m = victims, n = total - victims, k = n_weekend)))
}

permutation_accidents <- function(data, settings) {
  counts <- permutation_counts(data)
  n <- as.double(nrow(data))
  nw <- counts$n[counts$group == "FDS"]
  ns <- n - nw
  total_victims <- sum(data$victim)
  observed_w <- counts$victims[counts$group == "FDS"]
  # Le numérateur entier évite une ambiguïté d’arrondi pour les ex aequo.
  observed_numerator <- observed_w * n - total_victims * nw
  difference <- function(x) 100 * (x * n - total_victims * nw) / (nw * ns)

  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  })
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(settings$seed)
  # Premier mélange explicite : chaque valeur binaire est réaffectée sans remise.
  first <- sample(data$victim, size = n, replace = FALSE)
  first_w <- sum(first[data$group == "FDS"])
  # Les autres mélanges sont simulés par leur décompte hypergéométrique.
  # Même loi que la permutation de tous les labels, sans B tableaux de 108186 lignes.
  simulated_w <- c(first_w, rhyper(settings$B - 1L,
    m = total_victims, n = n - total_victims, k = nw))
  numerators <- simulated_w * n - total_victims * nw
  replicates <- tibble(repetition = seq_len(settings$B),
    victims_weekend = simulated_w, difference_pp = difference(simulated_w),
    extreme = abs(numerators) >= abs(observed_numerator))
  list(settings = settings, counts = counts, n = n, victims = total_victims,
    observed_pp = difference(observed_w), replicates = replicates,
    exact_p = permutation_exact(nw, ns, total_victims, observed_w),
    first = tibble(position = seq_len(n), group = data$group,
      observed_victim = data$victim, permuted_victim = first))
}

permutation_summary <- function(result) {
  counts <- result$counts
  extreme <- sum(result$replicates$extreme)
  tibble(n_weekday = counts$n[1L], victims_weekday = counts$victims[1L],
    proportion_weekday = counts$proportion[1L], n_weekend = counts$n[2L],
    victims_weekend = counts$victims[2L], proportion_weekend = counts$proportion[2L],
    difference_pp = result$observed_pp, extreme = extreme,
    B = nrow(result$replicates), p_mc = (extreme + 1) / (nrow(result$replicates) + 1),
    resolution = 1 / (nrow(result$replicates) + 1), p_exact = result$exact_p,
    seed = result$settings$seed)
}

permutation_format <- function(x, digits = 2L) {
  formatC(x, format = "f", digits = digits, big.mark = " ", decimal.mark = ",")
}
permutation_p_format <- function(x) {
  if (x < 0.0001) formatC(x, format = "e", digits = 2, decimal.mark = ",")
  else permutation_format(x, 4L)
}

permutation_plot <- function(result, observed = FALSE) {
  if (observed) {
    return(ggplot(result$counts, aes(factor(label, levels = unname(accident_groups)), proportion)) +
      geom_col(fill = "#185b83", width = 0.55) +
      geom_text(aes(label = paste0(permutation_format(100 * proportion), " %")), vjust = -0.5) +
      scale_x_discrete(labels = c("Lundi au\nvendredi", "Samedi ou\ndimanche")) +
      scale_y_continuous(labels = label_percent(decimal.mark = ","), limits = c(0, 0.3)) +
      labs(x = NULL, y = "Proportion d’accidents avec victimes",
        title = "Les proportions observées dans les rapports 2022",
        caption = "Dénominateur : les accidents rapportés de chaque groupe, sans nombre de trajets.") +
      theme_minimal(base_size = 13))
  }
  summary <- permutation_summary(result)
  ggplot(result$replicates, aes(difference_pp)) +
    geom_histogram(bins = 35, fill = "#185b83", colour = "white", linewidth = 0.3) +
    geom_vline(xintercept = 0, colour = "#536779", linetype = "dotted") +
    geom_vline(xintercept = result$observed_pp, colour = "#c36b25", linewidth = 1) +
    geom_vline(xintercept = -result$observed_pp, colour = "#c36b25", linetype = "dashed") +
    scale_x_continuous(labels = label_number(decimal.mark = ",")) +
    labs(x = "Écart FDS - semaine\n(points de pourcentage)", y = "Nombre de permutations",
      title = "Que produirait le mélange des statuts de victime ?",
      subtitle = "Trait orange plein : écart observé; pointillé orange : seuil opposé du test bilatéral.",
      caption = paste0(summary$extreme, " mélanges au moins aussi extrêmes sur ", summary$B,
        "; p Monte-Carlo = ", permutation_p_format(summary$p_mc), ". Modèle conditionnel d’échangeabilité.")) +
    theme_minimal(base_size = 13) + theme(panel.grid.minor = element_blank())
}

# ACTIVITÉ : exécution autonome depuis le projet de la trousse.
fichier <- "data/processed/rapports-accident/rapports_accident_2022_prepares.csv"
if (!file.exists(fichier)) stop("Extraire la trousse entière et ouvrir Donnees-bleues.Rproj.")
accidents <- read_permutation_accidents(fichier)
reglages <- permutation_settings(B = 5000L)
resultats <- permutation_accidents(accidents, reglages)
resume <- permutation_summary(resultats)
print(resultats$counts)
print(resume)

# Une permutation conserve les groupes et le nombre total de victimes.
premier_melange <- resultats$first
print(head(premier_melange, 12))
comptes_melanges <- permutation_counts(tibble(group = premier_melange$group,
  victim = premier_melange$permuted_victim))
print(comptes_melanges)

# Préfixes des mêmes simulations : comparer uniquement B.
stabilite <- bind_rows(lapply(c(500L, 2000L, 5000L), function(B) {
  prefixe <- resultats
  prefixe$settings$B <- B
  prefixe$replicates <- head(resultats$replicates, B)
  permutation_summary(prefixe)
}))
print(stabilite)
graphique_observe <- permutation_plot(resultats, observed = TRUE)
graphique_permutations <- permutation_plot(resultats)
print(graphique_observe)
print(graphique_permutations)

dir.create("outputs", showWarnings = FALSE)
write_csv(resume, "outputs/permutations-resume.csv")
write_csv(resultats$counts, "outputs/permutations-proportions.csv")
write_csv(stabilite, "outputs/permutations-stabilite.csv")
write_csv(premier_melange, "outputs/permutations-premier-melange.csv")
write_csv(resultats$replicates, "outputs/permutations-repetitions.csv")
ggsave("outputs/permutations-observe.png", graphique_observe,
  width = 9, height = 5, dpi = 160, bg = "white")
ggsave("outputs/permutations-distribution.png", graphique_permutations,
  width = 9, height = 5, dpi = 160, bg = "white")
