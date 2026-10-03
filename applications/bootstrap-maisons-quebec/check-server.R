# Contrôler depuis ce dossier : Rscript --vanilla check-server.R.
library(shiny)
invisible(source("app.R", encoding = "UTF-8"))

# Propriétés du calcul : remise, préfixes reproductibles, bornes emboîtées,
# préservation de la graine et approximation de l’erreur-type conditionnelle.
set.seed(42)
state <- .Random.seed
reference <- bootstrap_houses(houses, bootstrap_settings(B = 5000L))
stopifnot(identical(state, .Random.seed), length(reference$first_indices) == 600L,
  anyDuplicated(reference$first_indices) > 0L,
  reference$observed["mean"] == 410580, reference$observed["median"] == 366000)
prefix <- bootstrap_houses(houses, bootstrap_settings(B = 500L))
stopifnot(identical(prefix$replicates, head(reference$replicates, 500L)))
intervals <- lapply(c(0.90, 0.95, 0.99), function(p) bootstrap_summary(reference, p))
stopifnot(all(intervals[[1]]$lower >= intervals[[2]]$lower),
  all(intervals[[2]]$lower >= intervals[[3]]$lower),
  all(intervals[[1]]$upper <= intervals[[2]]$upper),
  all(intervals[[2]]$upper <= intervals[[3]]$upper))
# Variance exacte de la moyenne sous rééchantillonnage de la loi empirique.
conditional_se <- sqrt(mean((reference$x - mean(reference$x))^2) / 600)
stopifnot(abs(sd(reference$replicates$mean) / conditional_se - 1) < 0.05)
for (original in c(FALSE, TRUE)) {
  for (statistic in c("mean", "median")) {
    built <- ggplot_build(bootstrap_plot(reference, statistic, original))
    bars <- built$data[[1L]]
    stopifnot(sum(bars$count) == if (original) 600 else 5000)
    if (!original) stopifnot(nrow(built$data[[3L]]) == 2L,
      isTRUE(all.equal(built$data[[3L]]$xintercept,
        as.numeric(quantile(reference$replicates[[statistic]], c(0.025, 0.975), type = 7)))))
  }
}
for (invalid in list(list(B = 1), list(seed = -1), list(seed = 1.5),
                     list(confidence = 1), list(variable = "inconnue")))
  stopifnot(inherits(try(do.call(bootstrap_settings, invalid), silent = TRUE), "try-error"))

testServer(bootstrap_server, {
  session$setInputs(variable = "valeur_fonciere_cad", B = "2000", confidence = "0.95",
                    seed = 20261003, statistic = "mean", run = 0)
  stopifnot(result()$settings$B == 2000L, output$pending == "Résultats à jour.")
  before <- result()
  session$setInputs(B = "500", confidence = "0.90", seed = 17)
  stopifnot(identical(before, result()), grepl("Réglages modifiés", output$pending),
    grepl("B = 2000L", output$code, fixed = TRUE))
  session$setInputs(run = 1)
  stopifnot(result()$settings$B == 500L, result()$settings$seed == 17L,
    selected_summary()$confidence == 0.90, output$pending == "Résultats à jour.")
  session$setInputs(statistic = "median")
  stopifnot(selected_summary()$estimate == 366000,
    grepl('bootstrap_plot(resultats, "median")', output$code, fixed = TRUE))
  before <- result()
  session$setInputs(seed = -1, run = 2)
  stopifnot(identical(before, result()))
})

# Exécuter les exports avec le CSV local et comparer les résultats aux calculs
# affichés, plutôt que seulement vérifier leur syntaxe.
app_root <- getwd()
for (variable in names(bootstrap_labels)) {
  for (statistic in names(bootstrap_statistics)) {
    configuration <- bootstrap_settings(variable, B = 500L, confidence = 0.99, seed = 17L)
    expected <- bootstrap_houses(houses, configuration)
    code <- export_bootstrap_code(configuration, statistic)
    stage <- tempfile("bootstrap-export-")
    dir.create(stage)
    file.copy("data/maisons-quebec.csv", file.path(stage, "maisons-quebec.csv"))
    writeLines(code, file.path(stage, "analyse.R"), useBytes = TRUE)
    tryCatch({
      setwd(stage)
      pdf("controle.pdf")
      env <- new.env(parent = globalenv())
      source("analyse.R", local = env, encoding = "UTF-8")
      stopifnot(identical(env$resultats$replicates, expected$replicates),
        identical(env$resume, bootstrap_summary(expected)),
        file.size("bootstrap-graphique.png") > 1000L,
        isTRUE(all.equal(ggplot_build(env$graphique)$data,
          ggplot_build(bootstrap_plot(expected, statistic))$data)))
    }, finally = { dev.off(); setwd(app_root); unlink(stage, recursive = TRUE) })
  }
}
cat("Bootstrap : calculs, états Shiny et quatre scripts exportés exécutés et comparés.\n")
