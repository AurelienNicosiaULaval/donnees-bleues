# Trois démonstrations pédagogiques avec des données québécoises

Aurélien Nicosia, Données bleues. Version du 5 septembre 2026.

| Document | Question statistique | Données incluses |
|:--|:--|:--|
| [Îlots de chaleur](01-ilots-chaleur.html) · [source Quarto](01-ilots-chaleur.qmd) | Comment k-means transforme-t-il des valeurs continues en classes ? | 9 806 pixels tirés de la cartographie INSPQ / CERFO, 2020-2022, autour de Québec |
| [ACP des municipalités](02-acp-quebec.html) · [source Quarto](02-acp-quebec.qmd) | Comment résumer six indicateurs et interpréter les axes ? | Recensement de 2021, extrait de 1 282 SDR du Québec ; 661 SDR retenues |
| [Crues de la Saint-Charles](03-crues-saint-charles.html) · [source Quarto](03-crues-saint-charles.qmd) | Comment estimer une crue centennale avec 42 ans de données ? | 42 maxima annuels 1969-2010, station 050904, rapport CEHQ de 2011 |

Chaque démonstration contient une question de départ, les définitions des variables, le code R, les résultats recalculés, des graphiques, des vérifications de sensibilité et des exercices accompagnés de pistes de réponse repliables. Les durées et préalables sont des propositions pour préparer une séance, pas des usages déjà attestés dans un cours.

## Lire

Ouvrir un fichier `.html` dans un navigateur. Les graphiques, le style et les formules sont inclus dans chaque HTML : aucune connexion n’est nécessaire pour la lecture. Les liens vers les publications originales nécessitent Internet.

## Modifier et recalculer dans RStudio

1. Décompresser tout le dossier en conservant son arborescence.
2. Ouvrir `Demonstrations-Donnees-bleues.Rproj` dans RStudio.
3. Si nécessaire, ouvrir `INSTALLER.R` et cliquer sur Source pour installer les bibliothèques manquantes. R et Quarto doivent être installés sur l’ordinateur.
4. Ouvrir l’un des trois `.qmd` et cliquer sur Render. Toutes les données de l’analyse sont dans `data/`.

Les documents utilisent R, readr, dplyr, tidyr, ggplot2, knitr et scales. Ils chargent explicitement ces bibliothèques. Les versions de l’environnement de validation sont consignées dans `ENVIRONNEMENT.txt` et dans chaque HTML. Un changement de version peut occasionner de petites différences numériques ou graphiques.

Pour compiler les trois documents depuis ce dossier :

```sh
quarto render
```

## Ce que les documents reproduisent

- Crues : concordance avec les six quantiles du tableau 4 du rapport, à sa précision d’affichage. Le diviseur n - 1 pour la variance des logarithmes reproduit les paramètres publiés ; le MV strict et le bootstrap sont montrés séparément.
- ACP : reconstruction pédagogique avec de nouvelles données de 2021 et une autre échelle territoriale. Il ne s’agit pas du calcul de l’indice officiel de défavorisation. Les écarts de définition sont explicites.
- Chaleur : nouvelle classification sur un extrait d’une carte de prédictions. La forêt aléatoire de production n’est pas réentraînée et les classes officielles ne sont pas reproduites.

## Reconstituer les extraits depuis les sources

Cette étape est facultative. `sources/reconstituer-extraits.R` refait l’extraction du recensement et du raster, avec la bibliothèque supplémentaire sf. Les résultats vont dans `data-reconstituees/`, sans écraser les fichiers fournis. Le téléchargement du recensement demande environ 47 Mo, puis 650 Mo d’espace temporaire. Le raster est consulté par requêtes partielles.

Les 42 débits ont été transcrits du rapport, puis contrôlés sur l’image de son tableau. Voir `PROVENANCE.md` pour les sources, transformations, limites et empreintes SHA-256. Les rapports originaux ne sont pas redistribués dans ce dossier.

## Attribution et licences

Les textes, exercices et figures originales de ces démonstrations relèvent de la licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr), conformément aux contenus de Données bleues. Attribution : Aurélien Nicosia, Données bleues, titre de la démonstration, 2026, https://donneesbleues.ca/ ; indiquer les modifications. Le code original relève de MIT, voir `LICENSE-CODE`.

Les données de tiers conservent leurs conditions propres et leurs attributions, détaillées dans `PROVENANCE.md`. Les calculs pédagogiques ne constituent pas une approbation par leurs producteurs.
