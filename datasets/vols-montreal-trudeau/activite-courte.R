# Explorer les trajectoires observées à YUL, sans les confondre avec le trafic officiel.
# Ouvrir le projet RStudio de la trousse, puis exécuter ce script.
library(readr)
library(dplyr)
library(ggplot2)

vols <- read_csv("data/processed/vols-montreal-trudeau/vols_yul.csv",
                 show_col_types = FALSE)
trafic <- read_csv("data/processed/vols-montreal-trudeau/trafic_quotidien_yul.csv",
                   show_col_types = FALSE)
liaisons <- read_csv("data/processed/vols-montreal-trudeau/liaisons_yul.csv",
                     show_col_types = FALSE)
stopifnot(nrow(vols) == 491786L, nrow(trafic) == 912L,
          nrow(liaisons) == 1460L)

# Une trajectoire locale à YUL contribue à la fois aux départs et aux arrivées.
bilan <- tibble(
  trajectoires_distinctes = nrow(vols),
  departs_observes = sum(trafic$n_departs_observes),
  arrivees_observees = sum(trafic$n_arrivees_observees),
  evenements_departs_arrivees = sum(trafic$n_evenements_observes),
  trajectoires_locales_yul = sum(vols$sens == "local_yul")
)
stopifnot(bilan$evenements_departs_arrivees - bilan$trajectoires_distinctes ==
            bilan$trajectoires_locales_yul)
print(bilan)

# Trois jours n'ont aucune observation retenue; ils ne prouvent pas une absence de vols.
print(trafic |>
  filter(n_evenements_observes == 0) |>
  select(date_locale, n_departs_observes, n_arrivees_observees))

# Décrire l'archive sur une année entière, sans lui attribuer une couverture constante.
mensuel_2025 <- trafic |>
  filter(date_locale >= as.Date("2025-01-01"),
         date_locale < as.Date("2026-01-01")) |>
  mutate(mois = format(date_locale, "%Y-%m")) |>
  group_by(mois) |>
  summarise(jours = n(),
            departs_par_jour = mean(n_departs_observes),
            arrivees_par_jour = mean(n_arrivees_observees),
            .groups = "drop")
print(mensuel_2025)
print(ggplot(mensuel_2025, aes(mois, departs_par_jour, group = 1)) +
  geom_line(color = "#185b83", linewidth = 1) +
  geom_point(color = "#185b83") +
  labs(x = "Mois de 2025", y = "Départs observés par jour, en moyenne",
       title = "Rythme mensuel dans l'archive ADS-B de YUL",
       caption = "Archives MrAirspace : couverture variable, trafic non exhaustif") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)))

# Les liaisons ne sont disponibles que lorsque les deux aéroports sont identifiés.
principales_destinations <- liaisons |>
  filter(origine_icao == "CYUL", destination_icao != "CYUL") |>
  arrange(desc(n_observations), destination_icao) |>
  slice_head(n = 10)
print(principales_destinations)

# À discuter : les durées manquantes et les codes d'aéroport ambiguës.
print(vols |>
  summarise(durees_manquantes = sum(is.na(duree_observee_min)),
            destinations_manquantes = sum(is.na(destination_icao)),
            origines_manquantes = sum(is.na(origine_icao))))
