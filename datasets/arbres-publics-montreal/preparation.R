# Préparer le jeu de données : Arbres publics sur le territoire de Montréal.
#
# Ce script est volontairement conservateur : la ressource officielle peut
# être volumineuse ou exister en plusieurs formats. Choisir la ressource utile
# depuis la page source, conserver une copie brute et documenter la date.

official_source_url <- "https://www.donneesquebec.ca/recherche/dataset/vmtl-arbres"

stop(
  "Choisir et documenter la ressource à préparer depuis ", official_source_url, ".",
  call. = FALSE
)
