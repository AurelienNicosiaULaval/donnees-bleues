# Trois activités avec la trousse hors ligne

Extraire tout le ZIP, ouvrir `Donnees-bleues.Rproj`, installer les packages avec `installer-packages.R` avant la séance, puis ouvrir l’un des scripts ci-dessous et cliquer Source. Les sorties sont enregistrées dans `outputs/`. Les durées sont indicatives; les activités n’ont pas été testées en classe.

## Exploration, 60 à 90 minutes

Script : `datasets/maisons-quebec/activite-courte.R`.

Livrable : tableau descriptif par lien physique, graphiques des valeurs et des associations sur des axes bruts et logarithmiques, six réponses justifiées.

1. Une valeur de 400 000 CAD prouve-t-elle une vente à ce prix en 2026 ? Donner le sens des trois dates.
2. Comparer moyenne et médiane globales en vous appuyant sur l’histogramme.
3. Comparer les maisons détachées et jumelées par leur médiane et leur IQR. L’écart est-il un effet causal du type ?
4. La corrélation augmente-t-elle avec les logarithmes ? Qu’est-ce qu’un nombre seul ne montre pas ?
5. Ces effectifs décrivent-ils les maisons de toute la province ? Nommer la population admissible et deux exclusions.
6. Vérifier que la valeur totale égale terrain + bâtiment. Expliquer la fuite de cible si les deux composantes prédisent le total.

Corrigé : (1) évaluation au rôle 2025, référence au 1er juillet 2023, extraction 2026, sans prix de transaction; (2) moyenne 410 580 CAD et médiane 366 000 CAD, distribution asymétrique vers les grandes valeurs; (3) détachées : médiane 376 000 CAD, IQR 146 500 CAD, jumelées : médiane 313 500 CAD, IQR 85 250 CAD, sans affectation aléatoire et sans contrôle des autres différences; (4) la corrélation diminue ici, environ 0,835 à 0,772, et ne montre pas les groupes ou les observations influentes; (5) seulement le périmètre admissible de Québec, avec exclusions des logements multiples, unités intégrées et genre unimodulaire; (6) les composantes fournissent la réponse par addition.

## Régression et validation, 120 minutes

Script : `datasets/maisons-quebec/activite-modeliser.R`.

Livrable : scores MAE et RMSE en dollars sur le test, coefficients, résidus dans l’apprentissage, valeurs observées et prédites sur le test, conclusion comparant les modèles aux références constantes. La validation croisée à cinq plis est facultative.

1. Pourquoi importer les codes de voisinage comme texte ?
2. Pourquoi séparer l’apprentissage et le test par voisinage ? Est-ce une preuve d’indépendance spatiale ?
3. Pourquoi exclure les valeurs du terrain et du bâtiment des prédicteurs ?
4. Quel modèle prédéfini a les plus petites erreurs sur les 100 maisons de test ? Citer MAE et RMSE.
5. Peut-on estimer la médiane de référence et la retransformation sur les 600 maisons ?
6. Peut-on utiliser le résultat comme prix de vente validé ou comme effet causal d’un agrandissement ?

Corrigé : (1) identifiants sans interprétation arithmétique; (2) absence de même code des deux côtés, sans preuve d’indépendance entre codes; (3) fuite de cible; (4) régression simple, MAE d’environ 82 838 CAD et RMSE d’environ 112 686 CAD, contre 90 690 et 148 110 CAD pour le modèle logarithmique multiple dans cette séparation; (5) non, uniquement dans l’apprentissage et dans chaque pli d’apprentissage; (6) ni transactions observées ni identification causale. La complexité n’améliore pas automatiquement la prédiction.

Le modèle reste fixé après consultation du test. Ne pas essayer plusieurs formules sur ce test pour retenir la meilleure. Une modification ultérieure exige une autre évaluation indépendante.

Référence pour la retransformation : Duan, N. (1983), [Smearing Estimate: A Nonparametric Retransformation Method](https://doi.org/10.1080/01621459.1983.10478017), Journal of the American Statistical Association, 78(383), 605-610. Le facteur global du script ne garantit pas la moyenne conditionnelle lorsque la dispersion dépend des caractéristiques.

## Bootstrap, 60 à 90 minutes

Script : `datasets/maisons-quebec/activite-bootstrap.R`.

Livrable : deux intervalles percentiles à 95 %, comparaison des 500, 2 000 et 5 000 premiers tirages d’une même suite, six réponses sur la remise, l’erreur-type et l’interprétation. La graine est 20261003; chaque tirage contient 600 lignes. L’application et la lecture associées sont accessibles depuis la page de l’activité.

1. Comparer le nombre de lignes et de maisons distinctes dans le premier tirage.
2. Distinguer l’écart-type des maisons de l’erreur-type de la moyenne.
3. Donner les intervalles de la moyenne et de la médiane et leurs paramètres cibles.
4. Comparer les bornes lorsque B augmente; identifier ce qui reste inchangé.
5. Comparer les niveaux de confiance sur les mêmes tirages et interpréter le niveau nominal.
6. Corriger un énoncé portant sur les prix de vente et les maisons de toute la province.

Corrigé : (1) la remise permet de répéter des identifiants et d’omettre des maisons; (2) dispersion individuelle et variation d’une statistique répondent à deux questions; (3) les deux paramètres sont distincts, les bornes exactes sont calculées dans la page et dans outputs/bootstrap-resume.csv; (4) B ne change pas les 600 observations, les bornes fluctuent numériquement sans diminution monotone garantie de leur largeur; (5) les intervalles sont emboîtés à tirages fixes, le niveau nominal décrit une procédure répétée sans attribuer une probabilité au paramètre fixe dans un intervalle réalisé; (6) valeurs évaluées, population admissible de Québec, intervalle d’un paramètre et approximation bootstrap du plan sans remise, avec couverture exacte non établie.

Voir `DICTIONNAIRE.md`, `METHODE.md` et `DATA_LICENSES.md` pour les définitions, la sélection et l’attribution MAMH.
