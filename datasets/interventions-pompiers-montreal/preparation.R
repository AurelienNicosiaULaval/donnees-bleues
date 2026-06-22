# Préparer le jeu de données : Interventions des pompiers de Montréal.
#
# Ce script est volontairement conservateur : la page officielle contient
# plusieurs ressources par période. Choisir la ressource utile au cours,
# conserver une copie brute et documenter la date de téléchargement.

official_source_url <- "https://donnees.montreal.ca/fr/dataset/interventions-service-securite-incendie-montreal"

current_csv_url <- "https://donnees.montreal.ca/dataset/2fc8a2b9-1556-410e-a118-c46e97e9f19e/resource/71e86320-e35c-4b4c-878a-e52124294355/download/donneesouvertes-interventions-sim.csv"

stop(
  "Choisir et documenter la ressource à préparer depuis ", official_source_url,
  ". Ressource CSV courante : ", current_csv_url,
  call. = FALSE
)
