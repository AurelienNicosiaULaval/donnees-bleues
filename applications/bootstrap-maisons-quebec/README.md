# Bootstrap des maisons à Québec

Application pédagogique de Données bleues, par Aurélien Nicosia, Université Laval (2026).

Installer une fois les bibliothèques avec Internet :

```r
install.packages(c("shiny", "readr", "dplyr", "ggplot2", "scales"))
```

Ouvrir ce dossier dans RStudio, puis lancer :

```r
library(shiny)
runApp()
```

Le CSV de 600 maisons est inclus. Après installation, l’application locale fonctionne hors ligne. La version publiée utilise Shinylive sur GitHub Pages. B peut valoir 500, 2 000 ou 5 000; chaque tirage contient 600 lignes avec remise. Moyenne et médiane sont calculées sur les mêmes tirages. Les quantiles utilisent le type 7 de R. La graine et les algorithmes aléatoires sont explicites.

Les résultats restent ceux du dernier calcul lorsque les réglages sont modifiés. Un message invite à recalculer. Les exports reproduisent les résultats affichés, avec le CSV figé version 1.0.0.

Le bootstrap ordinaire est une approximation du tirage initial sans remise parmi 99 072 unités admissibles. Sa couverture exacte n’est pas établie, notamment pour les médianes des valeurs arrondies. Il ne corrige pas les erreurs administratives ni une population cible mal définie. Les valeurs sont des évaluations foncières, sans prix de vente observés. Lire METHODE.md, DICTIONNAIRE.md et DATA_LICENSES.md.

Code original MIT; données MAMH et contenus CC BY 4.0. Calculs et exports contrôlés techniquement; utilisation en classe non documentée.

Développement dans le dépôt : `R/bootstrap.R` est reconstruit par `scripts/build_bootstrap_tools.R` à partir du début de `datasets/maisons-quebec/activite-bootstrap.R`. Modifier ce script source, puis reconstruire. Exécuter `check-server.R` pour vérifier le serveur et les exports.
