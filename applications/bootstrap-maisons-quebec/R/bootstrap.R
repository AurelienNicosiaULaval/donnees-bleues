# Bootstrap des maisons à Québec. Aurélien Nicosia (2026).
# Code MIT; données MAMH et contenus CC BY 4.0.
# Valeurs au rôle 2025, référence au marché 2023-07-01, extraction 2026.
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(scales)
})

bootstrap_labels <- c(valeur_fonciere_cad = "Valeur foncière évaluée (CAD)",
                      aire_etages_m2 = "Aire d’étages brute (m²)")
bootstrap_statistics <- c(mean = "Moyenne", median = "Médiane")

read_bootstrap_houses <- function(path) {
  houses <- read_csv(path, show_col_types = FALSE, col_types = cols(
    maison_id = col_character(), arrondissement_code = col_character(),
    voisinage_code = col_character(), lien_physique_code = col_character(),
    genre_construction_code = col_character()))
  stopifnot(nrow(houses) == 600L, ncol(houses) == 19L,
            !anyDuplicated(houses$maison_id),
            all(vapply(houses[names(bootstrap_labels)], function(x)
              is.numeric(x) && all(is.finite(x)), logical(1))))
  houses
}

bootstrap_settings <- function(variable = "valeur_fonciere_cad", B = 2000L,
                               confidence = 0.95, seed = 20261003L) {
  stopifnot(length(variable) == 1L, variable %in% names(bootstrap_labels),
    length(B) == 1L, is.finite(B), B == as.integer(B), B >= 100L, B <= 10000L,
    length(confidence) == 1L, confidence %in% c(0.90, 0.95, 0.99),
    length(seed) == 1L, is.finite(seed), seed >= 0, seed <= 2147483646,
    seed == as.integer(seed))
  list(variable = variable, B = as.integer(B), confidence = confidence,
       seed = as.integer(seed))
}

bootstrap_houses <- function(houses, settings) {
  x <- houses[[settings$variable]]
  stopifnot(length(x) >= 2L, all(is.finite(x)))
  # Conserver l’état aléatoire de l’appelant. Fixer les trois algorithmes
  # garantit les mêmes tirages dans R natif et dans WebR.
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
  n <- length(x)
  draws <- matrix(NA_real_, nrow = settings$B, ncol = 2L,
                  dimnames = list(NULL, c("mean", "median")))
  first_indices <- NULL
  for (b in seq_len(settings$B)) {
    indices <- sample.int(n, size = n, replace = TRUE)
    if (b == 1L) first_indices <- indices
    draws[b, ] <- c(mean(x[indices]), median(x[indices]))
  }
  list(settings = settings, n = n, x = x,
    observed = c(mean = mean(x), median = median(x)),
    replicates = tibble(repetition = seq_len(settings$B),
                        mean = draws[, 1L], median = draws[, 2L]),
    first_indices = first_indices)
}

bootstrap_summary <- function(result, confidence = result$settings$confidence) {
  stopifnot(confidence %in% c(0.90, 0.95, 0.99))
  alpha <- 1 - confidence
  bind_rows(lapply(names(bootstrap_statistics), function(statistic) {
    values <- result$replicates[[statistic]]
    bounds <- quantile(values, c(alpha / 2, 1 - alpha / 2), type = 7,
                       names = FALSE)
    tibble(statistic = statistic, estimate = unname(result$observed[statistic]),
      standard_error = sd(values), lower = bounds[1L], upper = bounds[2L],
      confidence = confidence, B = nrow(result$replicates), n = result$n)
  }))
}

bootstrap_plot <- function(result, statistic = "mean", original = FALSE) {
  stopifnot(statistic %in% names(bootstrap_statistics))
  label <- unname(bootstrap_labels[result$settings$variable])
  summary <- bootstrap_summary(result) |> filter(.data$statistic == .env$statistic)
  values <- if (original) result$x else result$replicates[[statistic]]
  plot <- ggplot(tibble(value = values), aes(value)) +
    geom_histogram(bins = 35, fill = "#185b83", colour = "white", linewidth = 0.3) +
    geom_vline(xintercept = result$observed[statistic], colour = "#c36b25",
               linewidth = 1) +
    scale_x_continuous(labels = label_number(big.mark = " ", decimal.mark = ",")) +
    labs(x = label, y = if (original) "Nombre de maisons" else "Nombre de rééchantillonnages",
      title = if (original) "Les 600 valeurs observées" else
        paste0("Les ", result$settings$B, " ", tolower(bootstrap_statistics[statistic]), "s rééchantillonnées"),
      subtitle = if (original) "Une observation par maison\nTrait orange : statistique observée" else
        "Une statistique par tirage de 600 lignes avec remise\nTrait orange : statistique observée") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"))
  if (!original) plot <- plot +
    geom_vline(xintercept = c(summary$lower, summary$upper),
               colour = "#226e59", linetype = "dashed", linewidth = 1) +
    labs(caption = paste0("Traits verts : intervalle percentile à ",
                         100 * result$settings$confidence, " % (approximation)."))
  plot
}

bootstrap_format <- function(x, digits = 0L) {
  formatC(x, format = "f", digits = digits, big.mark = " ", decimal.mark = ",")
}
