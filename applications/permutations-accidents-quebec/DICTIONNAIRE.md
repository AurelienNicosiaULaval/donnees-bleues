# Variables du parcours de permutation

La table de classe conserve les 108 186 rapports de 2022. Les colonnes viennent du CSV officiel SAAQ, préparé par `preparation.R`.

| Variable | Interprétation |
|---|---|
| annee | Année du rapport, 2022 dans cette version. |
| gravite | Libellé officiel : dommages matériels seulement, dommages matériels inférieurs au seuil de rapportage, léger, mortel ou grave. |
| region_nom | Nom de région extrait de la variable administrative. Peut manquer; il n’intervient pas dans ce parcours. |
| jour_semaine_code | `SEM` : lundi au vendredi; `FDS` : samedi ou dimanche. Aucun jour précis n’est fourni par ce code. |
| type_jour | Libellé du code précédent. |
| accident_avec_victime | Vrai pour les gravités « Léger » et « Mortel ou grave »; faux pour les deux catégories de dommages matériels. |

Le fichier inclus dans l’application reprend uniquement `annee`, `jour_semaine_code` et `gravite`. Le statut de victime est recalculé après validation des codes. Il désigne la présence de victimes dans un accident, sans compter leur nombre.

Les deux variables utilisées pour la comparaison ne comportent ni valeur manquante ni code inconnu dans la version figée. Une valeur inconnue provoque un arrêt du script; elle n’est pas assimilée à « sans victimes ».
