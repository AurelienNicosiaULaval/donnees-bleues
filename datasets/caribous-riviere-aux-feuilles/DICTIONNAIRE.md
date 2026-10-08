# Dictionnaire des données préparées

Version du 8 octobre 2026. Source : Leblond, St-Laurent et Côté (2017),
[Dryad, 10.5061/dryad.4k275](https://doi.org/10.5061/dryad.4k275).
Les noms normalisés ci-dessous sont ceux des CSV préparés ; les fichiers
originaux sont conservés séparément.

## positions_caribous.csv

Une ligne représente une position GPS déposée. Les 1 911 lignes restent dans
leur segment d'origine. Les identifiants doivent être importés comme du texte.

| Variable | Contenu et limite |
| :--- | :--- |
| `id_individu_source` | Colonne `ID`, convertie en texte sans arrondi supplémentaire. 52 valeurs distinctes. |
| `id_annee_source` | Colonne `IDYR`, conservée telle quelle. 95 valeurs distinctes. |
| `id_depuis_idyr` | Préfixe de `IDYR` après retrait du suffixe `_année`. Valeur de contrôle, sans correction du `ID`. |
| `id_coherent` | Correspondance exacte entre `id_individu_source` et `id_depuis_idyr`. Faux pour six lignes. |
| `segment_source` | Colonne `SEGMENT`. Numéro fourni par les auteurs ; les numéros ne sont pas tous consécutifs. |
| `cle_segment` | Préfixe `RAF_` suivi du numéro de segment. 319 valeurs, chacune liée à un seul individu dans ces fichiers. |
| `type_deplacement` | Type de segment donné par son fichier : glace, nage ou contournement. Ce n'est pas un état latent estimé. |
| `latitude`, `longitude` | Colonnes `LATITUDE`, `LONGITUDE`, en degrés. Datum non indiqué dans les sources consultées. |
| `annee_source` | Colonne `YEAR`. Concorde avec l'année de `DATE`. |
| `date_source`, `heure_source` | Colonnes `DATE` et `TIME`. Date civile et heure `HH:MM:SS` ; fuseau non documenté. |
| `date_heure_source` | Concaténation `YYYY-MM-DDTHH:MM:SS`, sans suffixe de fuseau. |
| `jour_annee_source` | Colonne `JULIAN DATE` : jour de l'année, de 1 à 366 ; ce n'est pas une date julienne astronomique. Concorde avec `DATE`. |
| `periode_modis_source` | Colonne `MODIS PERIOD`. Code conservé ; règle exacte non documentée dans le dépôt consulté. |
| `code_periode_source` | Colonne `PERIOD CODE`, conservée sans décodage. |
| `etat_source` | Colonne `STATE` : `ICE`, `WATER`, `OTHER`. Code original attaché à la position, distinct du type de segment. |
| `comportement_source` | Colonne `BEHAVIOR` : `TRAV` ou `CONT`. Code conservé. |
| `type_plan_eau_source` | Colonne `TYPE` : `LAKE` ou `RIVER`. Pas de catégorie explicite de réservoir dans ces tables. |
| `fichier_source`, `ligne_excel` | Classeur d'origine et numéro de ligne, en comptant l'en-tête en ligne 1. |
| `rang_dans_segment` | Ordre chronologique de la position dans le segment. |
| `x_lambert_m`, `y_lambert_m` | Coordonnées dérivées en EPSG:32198, sous l'hypothèse WGS84 pour les coordonnées GPS. |

## pas_caribous.csv

Une ligne relie deux observations successives dans un même segment. Les
1 592 pas sont tous observés, sans pas aléatoires ou témoins ajoutés.

| Variable | Contenu et limite |
| :--- | :--- |
| `cle_segment`, `segment_source`, `id_individu_source`, `type_deplacement` | Identifiants et type hérités des positions. |
| `rang_arrivee` | Rang de la position d'arrivée dans le segment. |
| `date_heure_depart`, `date_heure_arrivee` | Chaînes des dates/heures originales, sans fuseau. |
| `longitude_depart`, `latitude_depart`, `longitude_arrivee`, `latitude_arrivee` | Coordonnées originales des deux extrémités. |
| `duree_h` | Écart d'horloge civile en heures. Aucune conversion vers UTC. |
| `distance_ligne_droite_m` | Distance euclidienne entre extrémités après projection en EPSG:32198. Dépend de l'hypothèse de datum. |
| `vitesse_pas_m_h` | Distance par ligne droite divisée par `duree_h`. Ne mesure pas la vitesse instantanée. |
| `angle_rotation_abs_deg` | Angle absolu entre le pas courant et le précédent, de 0° (même direction) à 180° (direction opposée). Manquant pour le premier pas de chaque segment ou une distance nulle. |
| `intervalle_sup_13_1h` | Intervalle supérieur à 13,1 h. Indicateur de contrôle fondé sur 13 h plus six minutes de tolérance ; les lignes sont conservées. |

Les distances sont celles des lignes droites entre observations, pas la
longueur du trajet effectivement parcouru. Les angles sont calculés dans la
projection ; ils ne sont pas présentés comme une reproduction des calculs de
l'article.

## segments_caribous.csv

Une ligne par segment, avec les identifiants, le type et les champs suivants :

| Variable | Contenu |
| :--- | :--- |
| `id_annees_source` | Une ou plusieurs valeurs de `IDYR`, séparées par `;` si le segment traverse un changement d'année. |
| `n_positions`, `n_pas` | Nombre de positions et nombre de pas, égal à `n_positions - 1`. |
| `date_heure_debut`, `date_heure_fin` | Première et dernière date/heure du segment. |
| `duree_totale_h` | Somme des durées des pas du segment. |
| `distance_cumulee_lignes_droites_m` | Somme des distances calculées entre positions. |
| `vitesse_moyenne_des_pas_m_h` | Moyenne arithmétique des vitesses des pas ; différente du rapport distance totale/durée totale si les intervalles diffèrent. |
| `intervalle_min_h`, `intervalle_max_h` | Intervalle minimal et maximal entre observations du segment. |
| `contient_intervalle_sup_13_1h` | Au moins un pas dépasse le seuil de contrôle. |

## Données complémentaires et données spatiales

`resume_types.csv` résume les nombres de positions, individus, segments et pas
ainsi que la plage des dates et les intervalles par catégorie.

`glace_eau_table_source.csv` conserve les six colonnes du classeur
`Ice-Water_Proportion_Data.xlsx`, avec un numéro de ligne Excel. `Sum lake
(MODIS 37)` et `Sum lake-ice (MODIS 100)` sont les décomptes de cellules eau et
glace selon les notes Dryad. `Proportion` est l'indice (glace - eau)/(glace +
eau), avec -1 pour l'eau et +1 pour la glace selon l'article. Le fichier ne
comporte pas de colonne année et 30 valeurs du jour central sont non
numériques. Les blocs ne sont pas datés par supposition.

`nao_ao_table_source.csv` conserve les 28 colonnes du classeur `NAO_AO_Data.xlsx`
et ajoute le numéro de ligne Excel. `Area` prend les valeurs `Nichicun`,
`MODIS` ou une valeur manquante. `Year` est l'année ; `Breakup Date` et `Freeze
Date` sont des jours de l'année d'après l'article. Les 24 autres colonnes
donnent les indices mensuels NAO et AO. Les valeurs manquantes restent
manquantes, y compris les 16 lignes sans zone et sans dates de gel/dégel.

`caribous_et_lacs.gpkg` comprend trois couches :

- `positions_hypothese_wgs84` : positions, CRS assigné EPSG:4326 sous l'hypothèse documentée ;
- `segments_interpolation_lineaire` : segments, projetés en EPSG:32198, avec la même hypothèse pour les points ;
- `plans_eau_source` : géométrie multipartie originale, EPSG:32198 attesté par le fichier `.prj`.

La géométrie de plans d'eau est dissoute en une seule entité. Le champ `CODE`
vaut 1 ; aucun nom de lac n'est fourni. Elle ne constitue pas un inventaire
exhaustif des lacs québécois.
