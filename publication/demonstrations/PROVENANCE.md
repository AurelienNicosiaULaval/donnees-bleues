# Provenance des données et portée des reproductions

Version préparée le 5 septembre 2026. Les CSV fournis permettent de refaire les analyses sans accès aux services externes. Les empreintes des fichiers sont dans `sources/manifest-sha256.csv`.

## 1. Îlots de chaleur

Producteurs : Institut national de santé publique du Québec (coordination) et Centre d’enseignement et de recherche en foresterie de Sainte-Foy (réalisation).

- [Fiche Données Québec](https://www.donneesquebec.ca/recherche/dataset/ilots-de-chaleur-fraicheur-urbains-et-ecarts-de-temperature-relatifs-2020-2022).
- [Raster des écarts de température](https://dq-prd-bucket1.s3.ca-central-1.amazonaws.com/inspq/EcartTemperatureRelatif2022_Ecoumene2021.tif).
- [Rapport méthodologique de Budei et coll., 2023](https://www.donneesquebec.ca/recherche/dataset/533d0db2-399b-47a6-b397-0e6101e9a3a6/resource/ef5f91cb-f6c9-48f4-ae06-bbfb3483e06e/download/rapport-metho-ilots-chaleur-fraicheur-2020-2022-inspq-cerfo_2023-01_21-0924.pdf).
- Licence du jeu de données indiquée dans les métadonnées CKAN : Attribution CC BY 4.0. Source consultée le 5 septembre 2026.

Le fichier est un raster de prédictions d’écarts de température de surface, et non une collection de mesures de température de l’air. Le nom du produit vise 2020-2022. Il ne faut pas interpréter chaque pixel comme une observation faite à un instant commun.

Acquisition : requêtes HTTP partielles via GDAL 3.8.5 ; fenêtre demandée en EPSG:4326, ouest −71,28, est −71,20, nord 46,84, sud 46,78. Le découpage est un rectangle dans la grille source, projetée en EPSG:32198. La fenêtre résultante a 389 colonnes et 459 lignes. Son origine supérieure gauche est (−211680, 320175) m ; le pas est (15, −15) m. Ces paramètres précisent le découpage effectif, qui dépend de l’alignement sur la grille.

On retient les indices de ligne et de colonne 0, 4, 8, etc., avant d’exclure les valeurs non finies ou sans données. Le CSV contient 9 806 centres de pixels et leurs valeurs. Le pas entre centres est de 60 m ; chaque valeur reste celle d’un pixel de 15 m. Aucune interpolation, moyenne par bloc ou simulation n’est utilisée. Les carrés de 60 m des graphiques sont une convention d’affichage.

Les classes calculées sont propres à cet extrait. Le produit officiel classe les écarts par centre de population. Le modèle de forêt aléatoire ayant produit les valeurs n’est pas refait. La version extraite du raster est figée dans le CSV ; une évolution du fichier distant peut modifier une acquisition ultérieure.

## 2. ACP des territoires québécois

Producteur : Statistique Canada, Profil du Recensement de la population de 2021, fichier `98-401-X2021020_Francais_CSV_data.csv`.

- [Page de téléchargement](https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/details/download-telecharger.cfm?Lang=F).
- [Archive des SDR québécoises](https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/details/download-telecharger/comp/GetFile.cfm?Lang=F&FILETYPE=CSV&GEONO=020).
- [Licence ouverte de Statistique Canada](https://www.statcan.gc.ca/fr/avis/licence-ouverte).

L’extrait contient les 1 282 subdivisions de recensement du fichier québécois, leurs identifiants, les indicateurs de qualité géographique, 18 caractéristiques et leurs symboles de qualité pour la colonne du total. Les colonnes des hommes et des femmes ne sont pas utilisées. Les chiffres absents restent absents ; `x` et `..` dans les colonnes de symboles sont conservés. L’extraction n’impute aucune valeur. L’encodage du CSV source est Windows-1252 ; l’extrait est en UTF-8.

Le dictionnaire reprend les libellés des caractéristiques. Les six ratios et mesures sont calculés dans le Quarto, et non importés comme des scores préfabriqués. Les 661 SDR d’au moins 1 000 habitants ont toutes les six valeurs disponibles. Les autres SDR sont exclues par le seuil, indépendamment du fait qu’elles aient ou non des données complètes.

Ce travail est inspiré de Pampalon et coll. (2014), [Valider un indice de défavorisation en santé publique](https://doi.org/10.24095/hpcdp.34.1.03f). Il ne reproduit pas l’indice officiel. Différences : SDR au lieu d’aires de diffusion, recensement 2021, revenu de 2020 parmi les bénéficiaires, personnes seules rapportées à tous les âges, indicateurs non ajustés pour l’âge et le sexe, et poids égal de chaque SDR. Les populations d’origine et les dénominateurs sont indiqués dans le Quarto. Aucune interprétation individuelle ou causale ne découle des scores.

Adapté de Statistique Canada, Profil du Recensement de la population de 2021. Cela ne constitue pas une approbation de ce produit par Statistique Canada.

## 3. Crues de la rivière Saint-Charles

Source : Audrey Lavoie et Jean Francoeur, Centre d’expertise hydrique du Québec (2011), Révision des cotes de crues, rivière Saint-Charles, tronçon 5, CEHQ 4132-0509-05-8756.

- [Rapport diffusé par la Ville de Québec](https://www.ville.quebec.qc.ca/citoyens/propriete/docs/zones_inondables/saint_charles_troncon5/rapport_cotes_crues_saintcharles_VQ20140620_troncon5.pdf).
- Tableau des données : annexe 3, page imprimée 36, page PDF 44 (numérotation à partir de 1).
- Quantiles de référence : tableau 4 ; paramètres et autres quantiles : annexe 3, page imprimée 39.

Transcription des 42 dates, valeurs et codes du tableau, puis tri par date. Les valeurs sont des maxima annuels du débit journalier en m³/s, station 050904, 1969-2010. Codes conservés : E estimé, J jaugeage, M manque de données, P préliminaire. Les cellules vides correspondent à l’absence de code. Les valeurs transcrites ont été comparées à l’image du tableau du PDF.

Vérifications : années 1969-2010 sans doublon ; extrema 43,3 et 93,5 ; moyenne des logarithmes 4,1104399 ; écart-type des logarithmes avec n − 1 de 0,1863225. Les six quantiles avec cette convention retrouvent le tableau 4 au dixième. Le MV strict utilise 0,1840910 et donne donc des résultats légèrement différents. Le tableau 4 indique 82,8 m³/s pour 20 ans, contre 82,9 dans l’annexe ; le calcul avec n − 1 donne 82,84018.

Le rapport complet n’est pas redistribué. Son accessibilité ne permet pas de lui attribuer automatiquement la licence des contenus originaux de Données bleues. Le CSV reprend les faits numériques utiles, avec leur provenance. Les graphiques, la comparaison d’estimateurs, les simulations bootstrap et les exercices sont de nouvelles productions pédagogiques. Aucun calcul de cote d’inondation ou de risque actuel n’est revendiqué.

## Validation de la version fournie

Les trois Quarto ont été exécutés entièrement dans des sessions de rendu distinctes. Les assertions de cohérence incluses dans leur code passent. Les fichiers HTML incorporent les 14 figures et leurs dépendances de présentation, sans ressource externe nécessaire au rendu. Les figures ont été inspectées.

Le script R d’acquisition a également été exécuté. Les valeurs du recensement, les codes et le dictionnaire recréés sont identiques à ceux fournis ; l’extrait raster correspond à l’arrondi numérique près (tolérance absolue de 10⁻¹²). Les versions de R, Quarto et des bibliothèques sont consignées dans `ENVIRONNEMENT.txt`.
