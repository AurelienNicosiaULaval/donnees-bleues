# Accidents au Québec : comparer par permutation

Outil pédagogique d’Aurélien Nicosia, Université Laval. Comparaison bilatérale de deux proportions d’accidents avec victimes parmi les rapports SAAQ publiés pour 2022. Version figée 1.0.0, sans retrait de lignes.

## Lancer dans RStudio

Extraire tout le ZIP. Ouvrir ce dossier dans RStudio, puis exécuter :

```r
install.packages(c("shiny", "readr", "dplyr", "ggplot2", "scales"))
library(shiny)
shiny::runApp(".")
```

L’installation des packages exige Internet. Le CSV est inclus; les calculs ne nécessitent ensuite aucun téléchargement de données.

L’application publique utilise Shinylive sur GitHub Pages. Le premier chargement télécharge R et ses bibliothèques. Les exports CSV, PNG et R reprennent les derniers réglages calculés. Le script R exporté peut télécharger le même CSV figé si celui-ci n’est pas placé dans son dossier.

## Hypothèses et interprétation

Les groupes sont semaine (lundi au vendredi) et fin de semaine (samedi ou dimanche). Le mélange conserve leurs tailles et le total d’accidents avec victimes. Une première permutation explicite est visible; les suivantes utilisent les décomptes hypergéométriques équivalents. Le critère bilatéral est l’écart absolu en points de pourcentage, égalités incluses. La p-valeur Monte-Carlo est (k + 1)/(B + 1); la référence exacte utilise le même critère.

L’échangeabilité globale des rapports est une hypothèse pédagogique, sans validation pour ces données administratives. La description du fichier ne nécessite pas de test. Sans nombre de trajets ni distance parcourue, aucune mesure de risque par exposition n’est calculée. Le parcours ne démontre aucune causalité. Voir METHODE.md et DICTIONNAIRE.md.

Code MIT; données SAAQ et contenus originaux CC BY 4.0. Attribution dans DATA_LICENSES.md. Utilisation en classe non documentée.
