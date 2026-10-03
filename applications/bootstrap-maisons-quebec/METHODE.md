# Sélection et validation, version 1.0.0

Source : MAMH, [rôles d’évaluation foncière](https://www.donneesquebec.ca/recherche/dataset/roles-d-evaluation-fonciere-du-quebec), extraction 2026, municipalité de Québec, téléchargée le 1er octobre 2026. L’index officiel pointe vers `https://donneesouvertes.affmunqc.net/role/RL23027_2026.xml`.

Le rôle est entré en vigueur en 2025 (RLM02A). Les 600 unités sélectionnées ont une référence au marché du 1er juillet 2023 (RL0401A). Le nom du fichier 2026 ne transforme pas ces valeurs en prix immobiliers de 2026.

| Étape successive | Unités conservées |
|:--|--:|
| Toutes les unités du XML | 175 478 |
| Usage 1000 et exactement un logement | 132 559 |
| Lien physique 1 à 4 | 99 478 |
| Exclusion du genre unimodulaire 3; genre inconnu conservé | 99 072 |
| Tirage aléatoire simple sans remise | 600 |

Le programme R lit le XML par blocs et conserve l’ordre source. Il utilise `Mersenne-Twister`, `Inversion`, `Rejection` et la graine 20261001. Les indices tirés sont triés avant l’attribution des identifiants pédagogiques. La probabilité d’inclusion est 600/99072 pour chaque unité admissible de l’instantané. Il n’y a aucune sélection selon la valeur, les superficies, l’âge ou la complétude des autres champs. Aucune imputation ou correction numérique n’est effectuée. Les 19 colonnes du tirage sont complètes.

L’empreinte SHA-256 du XML est `971896db6bf6bcae5a711bbd4b2b33f945b770d237bd4164d8f4f5cd54feff9a`. Une nouvelle ressource portant d’autres octets interrompt la préparation : elle nécessite une nouvelle version ou le cache source vérifié. Le dossier enseignant local conserve l’original et son reçu; la trousse étudiante ne contient que les 600 lignes dérivées.

Les fichiers `selection.csv`, `qualite.csv`, `provenance_lignes.csv`, `selection.json` et `manifest.json` sont produits avec le CSV. La provenance par ligne donne sa position dans le XML épinglé, sans adresse ou matricule. Le script est exécutable depuis la racine de Données bleues; `DB_OFFLINE=true` permet de réutiliser le cache et ses reçus vérifiés. Sous RStudio : `Sys.setenv(DB_OFFLINE = "true")` avant `source("datasets/maisons-quebec/preparation.R")`.

## Validation de la régression

La cible est `valeur_fonciere_cad`. Les modèles prédéfinis sont une régression brute sur l’aire d’étages et une régression du logarithme sur les logarithmes des superficies, l’année de construction centrée en 1970 et le type de maison. Les deux catégories en rangée sont regroupées selon leur définition.

La graine 20261002 réserve 67 des 336 codes de voisinage au test. Dans le tirage obtenu : 500 maisons et 269 voisinages pour l’apprentissage, 100 maisons et 67 voisinages pour le test. Aucun code n’apparaît des deux côtés. Les références constantes (moyenne et médiane) sont calculées dans l’apprentissage seulement. Le facteur de retransformation du modèle logarithmique est la moyenne de `exp(résidu)` de l’apprentissage. Cette correction globale ne garantit pas la moyenne conditionnelle si la dispersion dépend des caractéristiques.

Une validation croisée facultative à cinq plis regroupe les voisinages, seulement dans l’apprentissage. Chaque correction de retransformation et chaque référence y sont réestimées dans le pli d’apprentissage. Les résultats du test sont présentés pour tous les modèles prédéfinis. Ils ne servent pas à modifier les modèles ni à choisir des seuils. Aucun résultat n’est présenté comme un prix de vente prédit, une validation temporelle ou une preuve causale.

La valeur totale est égale à la somme des valeurs terrain et bâtiment. Utiliser ces composantes pour prédire le total fournit directement la réponse; elles sont conservées pour apprendre à reconnaître cette fuite, mais exclues des formules de prédiction.

Le tirage aléatoire permet de décrire le périmètre admissible de cet instantané, sous les limites des données administratives. Il ne représente pas les copropriétés intégrées, les immeubles à plusieurs logements, toutes les habitations de Québec ou les maisons de la province. Les codes de voisinage n’établissent pas l’indépendance spatiale entre ensembles.
