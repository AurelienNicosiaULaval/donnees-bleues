# Les trois sources conservées et les variables nécessaires à la jointure.
ressources_api <- list(
  list(cle = "permis", ressource = "9555031e-cfc5-4b78-bec9-4ab84b549f67", archive = "datasets/construction-quartiers-quebec/snapshots/permis/20261110T181014Z/source-api.zip", champs = c("DATE_DELIVRANCE", "DOMAINE", "LONGITUDE", "LATITUDE")),
  list(cle = "batiments", ressource = "0920b952-b349-4ddd-a7e3-eebf6f6b6336", archive = "datasets/construction-quartiers-quebec/snapshots/batiments/20261110T181302Z/source-api.zip", champs = c("ID", "TYPE_BATIMENT", "GEOMETRIE")),
  list(cle = "quartiers", ressource = "11b26afb-8215-4723-8dc5-78c93eec8763", archive = "datasets/construction-quartiers-quebec/snapshots/quartiers/20261110T180945Z/source-api.zip", champs = c("ID", "NOM", "SUPERFICIE", "PERIMETRE", "GEOMETRIE"))
)
