# Données bleues

Données bleues rassemble des sources québécoises et canadiennes pour enseigner la statistique, R et la science des données. Le [site public](https://aureliennicosiaulaval.github.io/donnees-bleues/) présente les fiches, les activités et leurs limites d’interprétation.

## Utiliser une activité en classe

1. Choisir une activité dans [Planifier](https://aureliennicosiaulaval.github.io/donnees-bleues/activites.html).
2. Télécharger sa trousse ZIP et l’extraire entièrement.
3. Ouvrir `Donnees-bleues.Rproj` dans RStudio.
4. Avant la séance, ouvrir `installer-packages.R` et cliquer sur Source avec Internet.
5. Ouvrir le script de l’activité dans le dossier `datasets` et cliquer sur Source.

Les fichiers inclus permettent de travailler hors ligne après installation des packages. Deux sources ISQ demandent une acquisition préalable avec le script fourni; leurs données ne sont pas redistribuées. Les trousses GRHQ, STM et ULaval portent sur la documentation et les protocoles : elles ne fournissent respectivement ni géodatabase, ni retards observés, ni données institutionnelles privées.

Chaque archive contient les versions de packages testées, la source, les dates de préparation et d’acquisition, les colonnes retenues et les empreintes SHA-256. Les consignes détaillées, objectifs et critères de réussite restent sur la page de l’activité.

## Réutilisation et citation

Les conditions des producteurs tiers restent applicables. Les liens figurent dans les fiches et dans chaque trousse; conserver l’attribution et mentionner les transformations. Une licence de données ne s’étend pas automatiquement aux textes, au code ou aux images du site. Les images possèdent leurs propres [crédits](https://aureliennicosiaulaval.github.io/donnees-bleues/credits-images.html).

La référence bibliographique figure dans [CITATION.cff](CITATION.cff). Les [livraisons GitHub](https://github.com/AurelienNicosiaULaval/donnees-bleues/releases) permettent de retrouver une version figée. Pour citer un résultat de classe, ajouter la version de la trousse et sa date de préparation.

## Restaurer l’environnement de développement

Le site utilise R 4.5.0 et Quarto 1.9.38. Les packages sont verrouillés dans `renv.lock`, y compris le commit du package UlavalSSD. Installer ces versions de R et Quarto, puis cloner le dépôt par SSH :

```bash
git clone git@github.com:AurelienNicosiaULaval/donnees-bleues.git
cd donnees-bleues
Rscript -e 'renv::restore(prompt = FALSE)'
```

Sur Linux, les packages spatiaux et graphiques demandent les bibliothèques système indiquées dans le workflow `.github/workflows/publish-pages.yml`. La restauration utilise Internet; les analyses des trousses fournies sont ensuite testées sans téléchargement.

## Valider et rendre le site

Depuis la racine du dépôt :

```bash
Rscript -e 'for (f in list.files("tests", pattern = "[.]R$", full.names = TRUE)) source(f)'
Rscript scripts/check_datasets.R
Rscript scripts/check_public_previews.R
Rscript scripts/check_classroom_kits.R
Rscript scripts/render_site.R
Rscript scripts/check_site.R
```

`render_site.R` reconstruit les catalogues, rend les pages et finalise leurs titres. Utiliser ce script pour une livraison complète. Le résultat se trouve dans `docs/`. `check_site.R` vérifie la structure HTML, les liens, les ancres et les téléchargements de cet artefact.

`check_classroom_kits.R` extrait les ZIP dans des dossiers temporaires, vérifie les empreintes et les colonnes, puis exécute séparément les analyses fournies. Pour les quatre analyses ISQ, la commande suivante extrait leurs trousses, exécute le script d’acquisition fourni, puis teste les analyses hors ligne :

```bash
Rscript scripts/check_source_activities.R --acquire
```

Le rendu des pages affiche le code sans exécuter les analyses. Le succès du rendu ne remplace donc pas ces tests. Les journaux et figures de contrôle sont dans `data/validation/`, ignoré par Git.

## Actualiser une source et ses ressources de classe

Les téléchargements et tables complètes restent dans `data/raw/` et `data/processed/`, ignorés par Git. Les imports créent des reçus de provenance; la date d’acquisition, la date de préparation et la période d’observation sont distinctes.

```bash
Rscript scripts/prepare_datasets.R bixi
Rscript scripts/build_public_previews.R
Rscript scripts/build_preview_charts.R
Rscript scripts/build_classroom_kits.R
Rscript scripts/check_classroom_kits.R
```

Les générateurs de ressources parcourent tous les jeux : préparer les autres jeux manquants avec `Rscript scripts/prepare_datasets.R --all` avant une reconstruction complète. Une réexécution avec `DB_OFFLINE=true` réutilise uniquement les fichiers sources dont l’empreinte et l’URL correspondent au reçu enregistré.

Chaque `metadata.yml` déclare explicitement l’autorisation de publication, les fichiers et colonnes de classe, les colonnes d’aperçu et le graphique. Une colonne nouvelle n’entre pas automatiquement dans une archive. Réexaminer les conditions de la source avant de changer ces listes. Les données privées ULaval restent hors du dépôt et des archives publiques.

## Contribuer

Les [modèles](templates/) définissent la structure d’une fiche, d’une activité et de leurs métadonnées. Une contribution doit fournir un script de préparation, deux scripts d’activité exécutables et leurs ressources de lancement. Les concepts et niveaux viennent de `data/metadata/taxonomie.yml`; ajouter un alias à une notion existante plutôt qu’un doublon de casse ou d’accent.

La disponibilité technique d’une trousse n’établit pas son efficacité pédagogique. La [fiche de retour de classe](templates/retour-classe-template.md) permet de documenter les usages et difficultés sans données personnelles étudiantes.

## Publication

Le workflow valide l’environnement, les règles de publication, les trousses et les analyses, puis construit et vérifie un site neuf. Le déploiement sur `main` dépend du succès de cette validation et utilise son artefact exact. Les demandes de fusion produisent un artefact de consultation sans déploiement.

Dans les paramètres Pages du dépôt, la source doit être GitHub Actions. Après une livraison, vérifier le workflow terminé et les pages et téléchargements publics. Un simple changement dans le dossier `docs/` ne constitue pas une preuve de publication validée.
