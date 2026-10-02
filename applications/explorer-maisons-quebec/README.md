# Explorer les maisons à Québec

Application Shiny descriptive, version 1.0.0, par Aurélien Nicosia.

Depuis ce dossier, installer les dépendances une première fois :

    install.packages(c("shiny", "readr", "dplyr", "ggplot2", "scales"))
    library(shiny)
    runApp(".")

Le CSV figé de 600 maisons et l'illustration sont inclus. L'application ne récupère aucune donnée pendant une session. Elle propose des filtres par type et année de construction, un nuage de points, un histogramme et des boîtes à moustaches, les échelles brute et logarithmique, un aperçu des données et trois exports (PNG, CSV et script R autonome).

Les résumés utilisent les maisons retenues dans les unités originales. Le graphique indique ses exclusions supplémentaires, notamment les valeurs non positives en échelle logarithmique. Les histogrammes et les boîtes sont calculés dans l'échelle choisie; les points des boîtes utilisent un décalage aléatoire reproductible.

Les valeurs au rôle ne sont pas des prix de vente. Les associations restent descriptives. Sources et conditions : DATA_LICENSES.md et [fiche de données](https://donneesbleues.ca/datasets/maisons-quebec/fiche.html).

Contrôles :

    # Depuis ce dossier
    source("check-server.R")

    # Depuis la racine du dépôt Données bleues
    source("scripts/check_house_explorer.R")

Le code original est sous MIT et les contenus pédagogiques sous CC BY 4.0. Les données MAMH sont sous CC BY 4.0. Le fichier de données est identique au CSV public de la version 1.0.0.

Publication gratuite : Shinylive sur le GitHub Pages de Données bleues. Depuis la racine du dépôt, après le rendu du site :

    library(shinylive)
    source("scripts/export_house_app.R")
    source("scripts/check_house_static.R")

Le moteur Shinylive est fixé à la version 0.10.12; les bibliothèques R du processus de construction sont décrites dans renv.lock. Les bibliothèques WebAssembly sont celles résolues par Shinylive lors de l’export, avec cache local dans le site et empreintes dans publication.json. Le premier chargement nécessite une connexion et télécharge le moteur R. Les interactions dans le navigateur doivent faire l’objet d’une vérification visuelle distincte des contrôles R.
