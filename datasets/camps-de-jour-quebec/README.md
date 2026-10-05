# Camps de jour au Québec, pilote 2026

Compilation de tarifs, horaires et conditions publiques de dix programmes, à partir de quatorze pages consultées le 5 octobre 2026. Sherbrooke couvre seulement Loisirs Acti-Famille; Drummondville couvre seulement le Centre communautaire Saint-Pierre. Ce périmètre ne constitue pas un recensement provincial.

La version `20261005T182735Z` se trouve dans `downloads/20261005T182735Z/`. Elle contient huit tables : programmes, faits, tarifs, preuves, sources, scénario, composantes du scénario et qualité. Les fichiers `empreintes.csv` et `manifest_publication.json` décrivent leur contenu. Les CSV sont encodés en UTF-8; une cellule vide signifie une valeur manquante.

Les 108 lignes du CSV principal sont des tarifs, pas des camps distincts. Les périodes, bases de facturation, catégories de résidence, rangs d'enfant et tailles de famille sont conservés. Les forfaits pour l'été ne sont pas divisés pour inventer un prix hebdomadaire. Le dictionnaire `DICTIONNAIRE.md` et la notice `DATA_LICENSE.md` accompagnent la compilation.

## Reproduire l'analyse

Télécharger la trousse sur la fiche Données bleues, l'extraire complètement, ouvrir `Donnees-bleues.Rproj` et installer les packages avec `installer-packages.R` avant la séance. Exécuter ensuite `datasets/camps-de-jour-quebec/activite-comparer-couts.R`. Le script lit les huit CSV, vérifie les jointures, recalcule le scénario et produit les tableaux et le graphique sans Internet.

Dans le dépôt source Données bleues, la commande suivante prépare les mêmes tables à partir des CSV figés fournis :

```sh
Rscript datasets/camps-de-jour-quebec/preparation.R
```

La collecte des pages était automatisée et leur transcription semi-manuelle. Les archives HTML et texte ont servi à vérifier les observations; leurs empreintes et localisations restent documentées. Ces archives ne font pas partie de la distribution publique. Les huit CSV permettent de reproduire les sommes et analyses; leur préparation ne reconstitue pas une archive historique à partir d'une page modifiée.

Le scénario porte sur un premier enfant résident de sept ans, quatre semaines ordinaires de cinq jours, avec couverture de 7 h 30 à 17 h 30. Il conserve six sommes de postes documentés, un calcul conditionnel à Sherbrooke et trois cas non calculables. Ces sous-totaux n'observent pas les dépenses des familles, les aides effectivement reçues, les places ni l'accompagnement disponibles. Les unités, hypothèses et informations manquantes sont déterminantes pour la comparaison.

Conserver la version, les sources, les conditions et la mention des transformations lors d'une réutilisation. Aucun renseignement individuel sur un enfant, parent ou ménage n'est collecté dans ces tables.
