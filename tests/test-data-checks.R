# Jeux synthétiques réservés aux tests des invariants d'importation.
source("R/utils_data_checks.R")
expect_error <- function(expression, pattern) {
  message <- tryCatch({ force(expression); NA_character_ }, error = function(e) conditionMessage(e))
  if (is.na(message) || !grepl(pattern, message)) stop("Erreur attendue : ", pattern)
}
schema <- employment_schema()
panel <- expand.grid(indicateur = schema$indicators, territoire = schema$territories,
                     date = as.Date(c("2026-07-01", "2026-08-01", "2026-09-01")), stringsAsFactors = FALSE)
panel$unite <- ifelse(grepl("Taux", panel$indicateur), "%", "k")
panel$valeur <- 10
panel$valeur_brute <- "10"
validate_monthly_panel(panel, schema$indicators, schema$territories)
# Une nouvelle période complète est acceptée, une corruption ne l'est pas.
expect_error(validate_monthly_panel(rbind(panel, panel[1, ]), schema$indicators, schema$territories), "unique")
expect_error(validate_monthly_panel(panel[-1, ], schema$indicators, schema$territories), "combinaisons")
expect_error(validate_monthly_panel(subset(panel, date != as.Date("2026-08-01")), schema$indicators, schema$territories), "absente")
wrong_unit <- panel
wrong_unit$unite[wrong_unit$indicateur == "Emploi"] <- "%"
expect_error(validate_monthly_panel(wrong_unit, schema$indicators, schema$territories), "unités attendues")
wrong_value <- panel
wrong_value$valeur[which(grepl("Taux", panel$indicateur))[1]] <- 101
expect_error(validate_monthly_panel(wrong_value, schema$indicators, schema$territories), "dépasse")
expect_error(validate_unique_key(data.frame(id = c(1, 1)), "id"), "dupliquée")
expect_error(validate_unique_key(data.frame(id = c(1, NA)), "id"), "manquante")
message("Contrôles d'import : nouvelle période acceptée; doublons, pertes de cellules et unités invalides détectés.")
