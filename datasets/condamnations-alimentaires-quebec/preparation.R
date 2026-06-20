# Préparation : Condamnations des établissements alimentaires au Québec
# Source officielle : Données Québec / MAPAQ
# Source pédagogique : UlavalSSD::listecondamnation

library(dplyr)
library(readr)
library(stringr)
library(UlavalSSD)

dir.create("data_processed", showWarnings = FALSE)

condamnations <- listecondamnation |>
  mutate(
    amende_num = parse_number(Amende, locale = locale(grouping_mark = " ")),
    ville_montreal = str_detect(Adresse_lieu_infraction, regex("MONTREAL|MONTRÉAL", ignore_case = TRUE))
  )

write_csv(condamnations, "data_processed/condamnations_alimentaires_quebec.csv")

