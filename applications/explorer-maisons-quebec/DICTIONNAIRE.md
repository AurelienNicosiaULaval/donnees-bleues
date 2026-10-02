# Dictionnaire : Maisons du Québec, version 1.0.0

Une ligne représente une unité d’évaluation à un logement dans la ville de Québec. Les types détaché, jumelé et en rangée sont retenus; les unités intégrées et le genre unimodulaire sont exclus. Le fichier contient 600 lignes et 19 colonnes.

| Variable | Type et unité | Champ source et définition |
|:--|:--|:--|
| `maison_id` | Texte | Identifiant pédagogique MQ-0001 à MQ-0600, dans l’ordre du tirage trié par ligne source. Ce n’est pas un matricule. |
| `municipalite` | Texte | Québec, code géographique RLM01A = 23027. |
| `arrondissement_code` | Texte | RL0102A, code administratif de l’arrondissement. Conserver le code sans lui attribuer un nom non vérifié. |
| `voisinage_code` | Texte | RL0107A, code administratif de voisinage. Sert au regroupement pour la validation; ne garantit pas l’indépendance spatiale. |
| `superficie_terrain_m2` | Numérique, m² | RL0302A, superficie du terrain. |
| `aire_etages_m2` | Numérique, m² | RL0308A, somme des surfaces brutes des étages entiers du bâtiment principal, avec attique, garage intégré et verrière intégrée le cas échéant. Ce n’est pas la surface habitable nette. |
| `nombre_etages_max` | Entier | RL0306A, nombre maximal d’étages complets des bâtiments de l’unité. |
| `annee_construction` | Entier, année | RL0307A, construction originelle du bâtiment principal, sans requalification à partir des rénovations. |
| `annee_construction_statut` | Texte | RL0307B décodé : R = Réelle, E = Estimée. |
| `lien_physique_code` | Texte | RL0309A : 1 = détaché, 2 = jumelé, 3 = en rangée avec un seul côté mitoyen, 4 = en rangée avec plusieurs côtés mitoyens. |
| `lien_physique` | Texte | Étiquette française dérivée du code précédent. |
| `genre_construction_code` | Texte | RL0310A : 1 = plain-pied, 2 = niveaux décalés, 3 = unimodulaire (exclu), 4 = étage mansardé, 5 = étages entiers. |
| `nombre_logements` | Entier | RL0311A, égal à 1 par le critère de sélection. |
| `valeur_terrain_cad` | Entier, CAD | RL0402A, valeur du terrain au rôle en vigueur. Composante de la réponse totale. |
| `valeur_batiment_cad` | Entier, CAD | RL0403A, valeur du ou des bâtiments au rôle en vigueur. Composante de la réponse totale. |
| `valeur_fonciere_cad` | Entier, CAD | RL0404A, valeur totale de l’immeuble au rôle, à la date de référence. Pas un prix de vente. |
| `date_reference_marche` | Date ISO | RL0401A, date à laquelle les conditions du marché ont été considérées : 2023-07-01. |
| `annee_role` | Entier, année | RLM02A, année d’entrée en vigueur du rôle : 2025. |
| `annee_extraction` | Entier, année | Année du fichier d’extraction MAMH : 2026. |

Les champs absents ou vides deviennent `NA`, sans imputation. Le tirage obtenu ne contient aucune valeur manquante dans ces 19 colonnes. Aucun seuil de valeur foncière, de superficie ou d’année de construction ne sert à choisir les 600 lignes.

Les adresses, matricules, cadastres et renseignements de propriétaires ne sont pas exportés. Les combinaisons de caractéristiques restent potentiellement reconnaissables dans la source publique; ce fichier n’est pas certifié anonyme.

Sources : MAMH (2022), [répertoire des renseignements, version 2.5](https://www.donneesquebec.ca/recherche/dataset/061c8cb7-ca4e-45be-a990-61fce7e7d2dc/resource/427a72a7-f34c-495b-aa23-9de71a84a066/download/repertoire-des-renseignements-prescrits-du-role-devaluation-fonciere-version-2.5.pdf), et [guide des données ouvertes](https://www.donneesquebec.ca/recherche/dataset/061c8cb7-ca4e-45be-a990-61fce7e7d2dc/resource/6f2599be-e49d-4b9a-8702-b12ad0f56141/download/gui_donneesrolesformatouvert_vf20220627.pdf), pages 16 à 20. Le XML téléchargé porte la version 2.6. Les champs retenus ont été vérifiés contre ces définitions; aucune validation du XML complet contre un schéma XSD 2.6 n’est revendiquée.
