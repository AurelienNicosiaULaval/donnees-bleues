# Emploi régional au Québec

Source officielle : https://statistique.quebec.ca/fr/document/population-active-emploi-et-chomage-regions-administratives-rmr-et-quebec

Tableau retenu : https://statistique.quebec.ca/fr/produit/tableau/caracteristiques-du-marche-du-travail-donnees-mensuelles-desaisonnalisees-regions-administratives-et-ensemble-du-quebec

Fichier officiel : https://statistique.quebec.ca/docs-ken/multimedia/Fichier_complet_916.xlsx

Question d'analyse : Comment comparer l'évolution du marché du travail entre régions sans surinterpréter des estimations issues d'une enquête?

Unité statistique : une ligne représente une combinaison indicateur, territoire et mois.

Variables principales : `indicateur`, `date`, `territoire`, `unite`, `valeur_brute`, `indicateur_qualite`, `valeur`.

Notes : La page de Statistique Québec diffuse les indicateurs de l'Enquête sur la population active par région administrative. Les données proviennent de Statistique Canada et sont adaptées par l'Institut de la statistique du Québec.

Le script `preparation.R` télécharge le XLSX officiel et produit une table longue dans `data/processed/emploi-regional-quebec/emploi_regional_quebec.csv`. Les fichiers bruts et préparés sont utilisés localement et ne sont pas redistribués dans Git.
