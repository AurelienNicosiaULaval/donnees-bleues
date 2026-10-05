# Analyse descriptive hors ligne depuis la racine de la trousse ou du dépôt.
library(readr)
library(dplyr)
library(tidyr)
library(tibble)
library(ggplot2)
library(scales)

# Les identifiants sont lus comme du texte, notamment les codes commençant par 0.
lire <- function(f) read_csv(f, col_types = cols(.default = col_character()), show_col_types = FALSE)
historique <- lire("data/processed/tarifs-douaniers-quebec/observations_contre_tarifs.csv")
actuels <- lire("data/processed/tarifs-douaniers-quebec/contre_tarifs_20260908.csv")
prix <- lire("data/processed/tarifs-douaniers-quebec/prix_moyens_quebec.csv")
annexes <- lire("data/processed/tarifs-douaniers-quebec/annexes_2026.csv")
commerce <- lire("data/processed/tarifs-douaniers-quebec/commerce_quebec.csv")
actualite <- lire("data/processed/tarifs-douaniers-quebec/actualite.csv")
evenements <- lire("data/processed/tarifs-douaniers-quebec/evenements.csv")
sources <- lire("data/processed/tarifs-douaniers-quebec/sources.csv")
couverture <- lire("data/processed/tarifs-douaniers-quebec/couverture.csv")
captures <- lire("data/processed/tarifs-douaniers-quebec/captures_sources.csv")
controles <- lire("data/processed/tarifs-douaniers-quebec/controles_qualite.csv")

stopifnot(nrow(historique) == 2774L, nrow(actuels) == 648L,
 nrow(prix) == 12650L, nrow(commerce) == 86710L,
 !anyDuplicated(actuels$code_tarifaire), !anyDuplicated(prix[c("mois", "vecteur")]),
 !anyDuplicated(commerce[c("mois", "vecteur")]), !anyDuplicated(sources$source_id),
 all(captures$source_id %in% sources$source_id | captures$source_id %in% c("statcan_prix_zip", "banque_transmission")),
 all(controles$resultat == "reussi"), nrow(couverture) == 7L,
 all(grepl("^https://", na.omit(evenements$source_url))), nrow(actualite) == 4L)
comparaison <- annexes |> select(code_tarifaire, taux_decret = taux_surtaxe_pourcent) |>
 left_join(actuels |> select(code_tarifaire, taux_liste = taux_surtaxe_pourcent), by = "code_tarifaire")
stopifnot(nrow(comparaison) == 335L, !anyNA(comparaison$taux_liste), all(comparaison$taux_decret == comparaison$taux_liste))
actuels <- actuels |> mutate(taux_surtaxe_pourcent = as.numeric(taux_surtaxe_pourcent))
prix <- prix |> mutate(date = as.Date(paste0(mois, "-01")), prix_cad = as.numeric(prix_cad))
commerce <- commerce |> mutate(date = as.Date(paste0(mois, "-01")), valeur_milliers_cad = as.numeric(valeur_milliers_cad))
stopifnot(max(prix$mois) == "2026-07", max(commerce$mois) == "2026-07")

theme_db <- theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(),
 plot.title = element_text(face = "plain", colour = "#153449"), legend.position = "bottom",
 plot.caption = element_text(hjust = 0), plot.background = element_rect(fill = "white", colour = NA))
repartition <- actuels |> count(taux_surtaxe_pourcent, name = "codes")
print(repartition)
plot_codes <- ggplot(repartition, aes(factor(taux_surtaxe_pourcent), codes)) +
 geom_col(fill = "#285B9A", width = 0.65) + geom_text(aes(label = codes), vjust = -0.4) +
 scale_y_continuous(expand = expansion(mult = c(0, 0.12))) + theme_db +
 labs(title = "648 codes dans le panneau du 8 septembre 2026", x = "Surtaxe indiquée (%)", y = "Codes tarifaires (nombre)",
 caption = "Finances Canada, consultation du 5 octobre 2026.\nComptage de codes, avant exemptions et remises; aucune pondération par les importations.")
print(plot_codes)

# Pour ce seul code, les deux sources donnent explicitement les périodes.
lingots <- historique |> filter(code_tarifaire == "72061000")
stopifnot(lingots$taux_surtaxe_pourcent[lingots$source_table == "1"] == "50",
 lingots$date_application_initiale_source[lingots$source_table == "2"] == "2025-03-13",
 lingots$fin_periode_table_source_inclusive[lingots$source_table == "2"] == "2026-09-07")
periodes <- tibble(date = as.Date(c("2025-03-13", "2026-09-08", "2026-10-05")), surtaxe = c(25, 50, 50))
plot_tarifs <- ggplot(periodes, aes(date, surtaxe)) + geom_step(direction = "hv", colour = "#285B9A", linewidth = 1.1) +
 geom_point(size = 2, colour = "#285B9A") + scale_y_continuous(limits = c(0, 55), breaks = c(0, 15, 25, 50)) +
 scale_x_date(date_breaks = "4 months", date_labels = "%Y-%m") + theme_db +
 labs(title = "Lingots américains : deux régimes de surtaxe", subtitle = "Code canadien 7206.10.00; suivi arrêté au 5 octobre 2026",
 x = "Date", y = "Surtaxe (%)", caption = "Finances Canada, liste et page acier/aluminium (2026).\nTaux avant exemptions et remises. Aucune valeur imputée avant le 13 mars 2025.")
print(plot_tarifs)

# Un indice par série compare des variations relatives, pas des conditionnements.
choix <- c("Lait, 2 litres", "Café torréfié ou moulu, 340 grammes", "Oeufs, 1 douzaine")
series <- prix |> filter(produit %in% choix, mois >= "2025-01")
base <- series |> filter(mois == "2025-01") |> select(vecteur, base_prix = prix_cad)
stopifnot(nrow(base) == 3L, !anyNA(base$base_prix), all(base$base_prix > 0))
series <- series |> left_join(base, by = "vecteur") |> mutate(indice = prix_cad / base_prix * 100,
 libelle = recode(produit, "Lait, 2 litres" = "Lait (2 L)", "Café torréfié ou moulu, 340 grammes" = "Café (340 g)", "Oeufs, 1 douzaine" = "Oeufs (douzaine)"))
stopifnot(nrow(series) == 57L, !anyNA(series$indice))
plot_prix <- ggplot(series, aes(date, indice, colour = libelle)) + geom_hline(yintercept = 100, colour = "grey70") +
 geom_line(linewidth = 0.9) + scale_colour_manual(values = c("#285B9A", "#B66A20", "#327E82")) +
 scale_x_date(date_breaks = "4 months", date_labels = "%Y-%m") + theme_db +
 labs(title = "Prix moyens de trois produits au Québec", subtitle = "Janvier 2025 = 100, dans chaque série; dernière observation : juillet 2026",
 x = "Mois", y = "Indice calculé", colour = NULL, caption = "Adapté de Statistique Canada, tableau 18-10-0245-01 (2026).\nConditionnements distincts. Origine douanière inconnue; aucune estimation causale.")
print(plot_prix)

# Le total et sa composante américaine sont montrés, mais jamais additionnés.
flux <- commerce |> filter(produit_scpan == "Total de toutes les marchandises", partenaire %in% c("Tous les pays", "États-Unis"))
stopifnot(nrow(flux) == 460L)
plot_commerce <- ggplot(flux, aes(date, valeur_milliers_cad / 1e6, colour = partenaire)) + geom_line(linewidth = 0.65) +
 facet_wrap(~commerce, ncol = 1) + scale_colour_manual(values = c("#327E82", "#285B9A")) +
 scale_x_date(date_breaks = "2 years", date_labels = "%Y") + scale_y_continuous(labels = label_number(decimal.mark = ",")) + theme_db +
 labs(title = "Commerce international de marchandises du Québec", subtitle = "Janvier 2017 à juillet 2026; la série américaine est une composante du total",
 x = "Mois", y = "Milliards de dollars courants", colour = NULL,
 caption = "Adapté de Statistique Canada, tableau 12-10-0175-01 (2026).\nBase douanière, non désaisonnalisée; exportations nationales; données révisables.")
print(plot_commerce)

sortie <- "outputs/tarifs-douaniers-quebec"
dir.create(sortie, recursive = TRUE, showWarnings = FALSE)
write_csv(repartition, file.path(sortie, "comptage_codes.csv"))
write_csv(comparaison, file.path(sortie, "rapprochement_decret_liste.csv"))
graphiques <- list(codes = plot_codes, surtaxe = plot_tarifs, prix = plot_prix, commerce = plot_commerce)
for (n in names(graphiques)) ggsave(file.path(sortie, paste0(n, ".png")), graphiques[[n]], width = 9,
 height = if (n == "commerce") 7.5 else 5.5, dpi = 180)
message("Quatre graphiques et deux tableaux écrits dans ", sortie)
