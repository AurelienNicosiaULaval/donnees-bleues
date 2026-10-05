# Tarifs douaniers, prix et commerce au Québec

Édition 20261005T200817Z préparée le 5 octobre 2026.

Cette édition réunit trois objets : des listes de surtaxes canadiennes, des prix moyens de détail au Québec et des flux mensuels de commerce international. Ils gardent des unités et des clés distinctes. Une variation commune ne constitue pas une preuve causale.

## Reproduire les graphiques

Extraire la trousse complète, ouvrir Donnees-bleues.Rproj et installer les bibliothèques à l'aide du script fourni. Exécuter datasets/tarifs-douaniers-quebec/activite-lire-tarifs.R depuis la racine du projet. Le script travaille hors ligne, conserve les codes comme texte et produit quatre graphiques ainsi que deux tableaux de contrôle dans outputs/tarifs-douaniers-quebec/.

Dans le dépôt du site, Rscript scripts/prepare_datasets.R tarifs-douaniers-quebec vérifie les empreintes de la version figée et prépare les fichiers de travail. Le script preparation.R ne prétend pas reconstituer une ancienne page Internet à partir de son état actuel.

## Acquisition et versionnement

collecte-initiale.R documente la collecte initiale des contre-tarifs et des prix. collecte-commerce.R télécharge le tableau complet 12-10-0175-01 et retient le Québec à partir de janvier 2017. Les adresses consultées, heures disponibles et SHA-256 sont dans captures_sources.csv. Les pages intégrales ne sont pas redistribuées. La capture initiale contenait un échec TLS pour la Gazette; une acquisition ultérieure réussie a fourni l'annexe analysée. L'ancien échec ne devient pas une réussite rétroactive.

Les tables extraites et publiées sont des éditions immuables. Une nouvelle collecte doit créer un nouveau dossier daté. Les dates d'annonce, de publication d'un texte, d'effet d'une mesure et de consultation restent distinctes.

## Couverture

Le fichier couverture.csv distingue les données intégrées des sources seulement inventoriées. Les tarifs ordinaires, tous les régimes étrangers, les exemptions et les remises ne sont pas intégrés exhaustivement. Les quatre articles de presse constituent une sélection éditoriale et non un corpus représentatif. Aucune veille automatique n'est configurée.

Les catégories et groupes de partenaires du commerce peuvent se recouvrir. Sélectionner un total ou ses composantes avant de sommer. Exportations nationales et exportations totales ne sont pas interchangeables. Les agrégats de l'ISQ cités dans l'analyse ne sont pas distribués comme une table de données dans cette édition.

## Réutilisation

Consulter DATA_LICENSE.md et DICTIONNAIRE.md. Les scores pédagogiques sont une appréciation éditoriale; aucun usage en classe n'est documenté.
