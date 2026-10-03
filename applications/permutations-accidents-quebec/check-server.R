library(shiny)
invisible(source("app.R", encoding = "UTF-8"))

# Énumération exhaustive indépendante sur six unités : vérifier le critère
# bilatéral et les ex aequo, plutôt que comparer deux copies du moteur.
assignments <- combn(6L, 3L)
weekend <- c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE)
counts <- apply(assignments, 2L, function(indices) sum(weekend[indices]))
for (observed in 0:3) {
  exact <- mean(abs(counts - 1.5) >= abs(observed - 1.5))
  stopifnot(isTRUE(all.equal(permutation_exact(3, 3, 3, observed), exact)))
}
stopifnot(permutation_exact(3, 3, 0, 0) == 1,
  permutation_exact(3, 3, 6, 3) == 1)

set.seed(42)
state <- .Random.seed
reference <- permutation_accidents(accidents, permutation_settings(B = 5000L))
s <- permutation_summary(reference)
stopifnot(identical(state, .Random.seed), s$n_weekday == 82168L,
  s$n_weekend == 26018L, s$victims_weekday == 16740L, s$victims_weekend == 5758L,
  s$difference_pp > 1.75, s$difference_pp < 1.77, s$p_exact > 0, s$p_exact < 1e-8,
  sum(reference$first$permuted_victim) == sum(accidents$victim),
  identical(reference$first$group, accidents$group),
  any(reference$first$observed_victim != reference$first$permuted_victim))
prefix <- permutation_accidents(accidents, permutation_settings(B = 500L))
stopifnot(identical(prefix$replicates, head(reference$replicates, 500L)),
  identical(prefix$first, reference$first),
  all(s$p_mc >= s$resolution), s$p_mc <= 1)
# Variance et espérance analytiques du décompte sous marges fixes.
M <- sum(accidents$victim); N <- nrow(accidents); nw <- s$n_weekend
expected_variance <- nw * (M / N) * (1 - M / N) * (N - nw) / (N - 1)
stopifnot(abs(var(reference$replicates$victims_weekend) / expected_variance - 1) < 0.07,
  abs(mean(reference$replicates$victims_weekend) - nw * M / N) < 4)
built <- ggplot_build(permutation_plot(reference))
stopifnot(sum(built$data[[1L]]$count) == 5000,
  built$data[[3L]]$xintercept == reference$observed_pp,
  built$data[[4L]]$xintercept == -reference$observed_pp)
for (invalid in list(list(B = 1), list(seed = -1), list(seed = 1.5), list(B = 20001)))
  stopifnot(inherits(try(do.call(permutation_settings, invalid), silent = TRUE), "try-error"))
bad <- accidents; bad$victim[1L] <- NA
stopifnot(inherits(try(permutation_counts(bad), silent = TRUE), "try-error"))
bad <- accidents; bad$group[1L] <- "inconnu"
stopifnot(inherits(try(permutation_counts(bad), silent = TRUE), "try-error"))

testServer(permutation_server, {
  session$setInputs(B = "2000", seed = 20261003, run = 0)
  stopifnot(output$pending == "Résultats à jour.")
  before <- result()
  session$setInputs(B = "500", seed = 17)
  stopifnot(identical(before, result()), grepl("Réglages modifiés", output$pending),
    grepl("B = 2000L", output$code, fixed = TRUE))
  session$setInputs(run = 1)
  stopifnot(result()$settings$B == 500L, result()$settings$seed == 17L,
    output$pending == "Résultats à jour.", grepl("seed = 17L", output$code, fixed = TRUE))
  before <- result()
  session$setInputs(seed = -1, run = 2)
  stopifnot(identical(before, result()))
})

# Exécuter les scripts exportés avec leurs données locales et comparer toutes
# les permutations, le résumé et les données du graphique aux résultats affichés.
app_root <- getwd()
for (settings in list(permutation_settings(B = 500L, seed = 17L),
                      permutation_settings(B = 5000L))) {
  expected <- permutation_accidents(accidents, settings)
  stage <- tempfile("permutation-export-"); dir.create(stage)
  file.copy("data/accidents-quebec-2022.csv", file.path(stage, "accidents-quebec-2022.csv"))
  writeLines(export_permutation_code(settings), file.path(stage, "analyse.R"), useBytes = TRUE)
  tryCatch({
    setwd(stage); pdf("controle.pdf")
    env <- new.env(parent = globalenv())
    source("analyse.R", local = env, encoding = "UTF-8")
    actual <- read_csv("permutations-resume.csv", show_col_types = FALSE)
    stopifnot(identical(env$resultats$replicates, expected$replicates),
      isTRUE(all.equal(actual, permutation_summary(expected), check.attributes = FALSE)),
      file.size("permutations-graphique.png") > 1000L,
      isTRUE(all.equal(ggplot_build(env$graphique)$data,
        ggplot_build(permutation_plot(expected))$data)))
  }, finally = { dev.off(); setwd(app_root); unlink(stage, recursive = TRUE) })
}
cat("Permutations : énumération, marges, variance, états Shiny et scripts exportés contrôlés.\n")
