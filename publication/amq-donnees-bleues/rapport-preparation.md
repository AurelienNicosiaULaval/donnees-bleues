# Rapport de préparation

Date : 23 août 2026.

## État de livraison

| Élément | État vérifié |
|---|---|
| Données bleues 0.1.0 | publié en ligne |
| Étiquette `v0.1.0` et publication GitHub | publiées |
| Article LaTeX et deux PDF | préparés, compilés et inspectés |
| Brouillon de courriel | préparé, non envoyé |
| Soumission au Bulletin AMQ | non soumise |
| Cession de droits | non acceptée |
| DOI d'archivage de la plateforme | aucun DOI créé |

## Version décrite

- Version : 0.1.0
- Étiquette : `v0.1.0`
- Commit source figé : `08247d89070eb1972d33fe4be1481e051dd36b83`
- Commit de publication du rendu `docs/` : `8c18ccd0bfa2c715ecd64d87875117a3927ecc60`
- Publication GitHub : <https://github.com/AurelienNicosiaULaval/donnees-bleues/releases/tag/v0.1.0>
- Site public : <https://aureliennicosiaulaval.github.io/donnees-bleues/>
- Citation : <https://aureliennicosiaulaval.github.io/donnees-bleues/CITATION.cff>
- Date de consultation du site public : 23 août 2026

L'étiquette pointe sur le commit source validé. Le commit suivant publie les 95 pages HTML générées dans `docs/`, car GitHub Pages est configuré en mode historique sur `main/docs`. L'étiquette n'a pas été déplacée après sa publication.

## Préservation du dépôt de travail

Le dépôt source local contenait des modifications non validées et des références Git synchronisées par un service de fichiers qui n'étaient pas lisibles de manière fiable. Elles n'ont été ni écrasées, ni supprimées, ni intégrées sans examen. La validation décisive, les commits et la publication ont été effectués depuis une copie propre du dépôt public. Seul le dossier final `publication/amq-donnees-bleues/` est recopié dans le dépôt source local. Le miroir de projet n'a pas été modifié.

## Inventaire recalculé

Les nombres proviennent des catalogues reconstruits, et non du texte du README :

- 26 fiches de jeux de données;
- 52 activités, soit deux par fiche;
- trois séquences;
- trois modules transversaux;
- 50 activités au statut `pret_a_enseigner`;
- deux activités au statut `a_consolider`.

Les statuts sont documentaires. Ils ne constituent pas une preuve d'usage ou d'efficacité.

## Validations de la plateforme

- `scripts/check_datasets.R` : réussite. La source privée Université Laval, absente de l'environnement propre, a été ignorée conformément au script;
- `scripts/check_public_previews.R` : réussite;
- reconstruction du catalogue des fiches : réussite;
- reconstruction du catalogue des activités : réussite;
- rendu Quarto complet : réussite, 95 pages HTML;
- validation des titres rendus : réussite;
- contrôle des liens et ressources internes dans `docs/` : aucun fichier manquant;
- contrôle HTTP du site publié : 26 fiches sur 26 et 52 activités sur 52 ont répondu avec le code 200;
- contrôle des 26 pages source officielles : 26 réponses 200, dont une avec un agent de navigateur conventionnel;
- contrôle visuel du site public en largeur 1440 px et 390 px : français, version 0.1.0 visible, navigation mobile présente et aucun débordement horizontal;
- contrôle de `CITATION.cff` et de sa copie publiée : réussite;
- validation dans un environnement propre : <https://github.com/AurelienNicosiaULaval/donnees-bleues/actions/runs/32662549719>;
- validation propre du commit de déploiement : <https://github.com/AurelienNicosiaULaval/donnees-bleues/actions/runs/32663304516>;
- déploiement GitHub Pages vérifié : <https://github.com/AurelienNicosiaULaval/donnees-bleues/actions/runs/32663303893>.

Ces contrôles établissent l'accessibilité des pages, les contrats documentaires et la cohérence du rendu. Ils ne constituent pas une nouvelle exécution exhaustive de chaque téléchargement de données tierces. Les scripts, chemins et métadonnées ont été contrôlés, et les trois sources utilisées dans l'article ont été vérifiées directement.

## Publication et archivage

La branche principale, l'étiquette et la publication GitHub ont été poussées sans forcer. Aucun fichier d'intégration Zenodo ou autre mécanisme de DOI utilisable n'a été trouvé dans le dépôt. Aucun DOI n'a donc été inventé et aucun compte externe n'a été créé.

## Contrôle des normes AMQ

- titre : 41 caractères, sous la recommandation de 50 caractères;
- résumé : 98 mots, sans formule;
- mots-clés : cinq;
- auteur, fonction, affiliation, courriel et adresse postale : vérifiés sur les pages officielles de l'Université Laval;
- niveaux de titres : deux niveaux utilisés dans le manuscrit;
- figure et tableau : appelés dans le texte, numérotés et accompagnés d'une légende;
- figure : création originale du projet, fournie séparément en PDF et JPG avec source LaTeX reproductible;
- bibliographie : saisie manuellement dans le fichier source, sans BibTeX;
- correspondance citations et bibliographie : dix références citées et dix références présentes;
- texte : révision française effectuée, sans formule dans le résumé et sans résultat pédagogique non observé;
- longueur : 13 pages pour la version auteur et 13 pages pour la version anonyme, format Letter;
- maximum de 20 pages : respecté;
- adresse de soumission actuelle : `bulletin@amq.math.ca`;
- soumission : non effectuée.

## Gabarit et divergence typographique

Le fichier `gabarit-original/GabaritAMQ101.tex` est une copie intacte du fichier téléchargé le 23 août 2026. Le préambule effectif reprend ses paquets, macros et géométrie officielle, notamment une zone de texte de 18,6 cm sur 14,4 cm, des marges horizontales de 3,6 cm et des marges verticales de 4,3 cm et 5 cm.

Une divergence existe entre les documents officiels. Les normes de mars 2018 demandent une police de 12 points et un double interligne. Le gabarit actuellement distribué déclare `article` en 10 points et applique un facteur d'interligne de 1,2. Conformément à la consigne de privilégier le gabarit courant sans modifier silencieusement ses marges, le manuscrit conserve la configuration du gabarit. Cette divergence devrait être signalée à la rédaction si elle demande une autre présentation.

Le gabarit produit aussi des avertissements liés à des options de géométrie redondantes. Ils proviennent de sa configuration officielle et ne causent ni erreur de compilation ni débordement du manuscrit.

## Contrôle des PDF

Les deux sources ont été compilées avec `latexmk` et pdfLaTeX. Les journaux finaux ne contiennent aucune erreur, référence indéfinie, citation indéfinie ou boîte horizontale débordante. Les polices sont incorporées.

Les 13 pages de chaque PDF ont été converties en images et inspectées visuellement, soit 26 pages au total. Le contrôle a porté sur les marges, les coupures, les accents, la figure, le tableau, le code R, les liens et la bibliographie. Aucun défaut bloquant n'a été observé dans les versions finales.

## Références et droits

Les références scientifiques, leurs DOI, les sources de données, les documents de l'AMQ et les coordonnées de l'auteur sont consignés dans `sources-verifiees.md`. La figure est une création originale schématique et ne reproduit aucun contenu tiers. Le tableau est une synthèse originale des métadonnées du projet.

## Éléments à confirmer avant toute soumission

- l'autorisation explicite de l'auteur pour transmettre le dossier;
- la version que la rédaction souhaite recevoir, avec auteur, anonyme, ou les deux;
- le souhait de l'auteur concernant la publication de son adresse électronique;
- la préférence de la rédaction au sujet de la divergence entre le gabarit 10 points et les normes 12 points à double interligne;
- l'existence éventuelle d'une consigne plus récente sur la déclaration d'outils génératifs;
- toute modification finale demandée par l'auteur après sa propre relecture.

Le brouillon de courriel n'a pas été envoyé. Aucune soumission, acceptation éditoriale ou cession de droits ne doit être déduite de la préparation de ce dossier.
