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

Les textes, fiches et activités originales sont sous [Creative Commons Attribution 4.0 International](LICENCE-CONTENUS.md). Le code original est sous [licence MIT](LICENSE). Ces licences permettent le partage et l’adaptation dans les conditions indiquées dans les notices, également incluses dans chaque trousse.

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

La plupart des pages affichent le code sans exécuter les analyses ; certaines affichent aussi les résultats recalculés depuis leur trousse. Le succès du rendu ne remplace pas les tests des scripts distribués. Les journaux et figures de contrôle sont dans `data/validation/`, ignoré par Git.

## Actualiser une source et ses ressources de classe

Les téléchargements et tables complètes restent dans `data/raw/` et `data/processed/`, ignorés par Git. Les imports créent des reçus de provenance; la date d’acquisition, la date de préparation et la période d’observation sont distinctes.

```bash
Rscript scripts/prepare_datasets.R bixi
Rscript scripts/build_public_previews.R
Rscript scripts/build_preview_charts.R
Rscript scripts/build_classroom_kits.R
Rscript scripts/check_classroom_kits.R
```

Le générateur d’aperçus accepte un identifiant, par exemple `Rscript scripts/build_public_previews.R arbres-quebec`. Sans cet argument, les générateurs de ressources parcourent tous les jeux : préparer les autres jeux manquants avec `Rscript scripts/prepare_datasets.R --all` avant une reconstruction complète. Une réexécution avec `DB_OFFLINE=true` réutilise uniquement les fichiers sources dont l’empreinte et l’URL correspondent au reçu enregistré.

Chaque `metadata.yml` déclare explicitement l’autorisation de publication, les fichiers et colonnes de classe, les colonnes d’aperçu et le graphique. Une colonne nouvelle n’entre pas automatiquement dans une archive. Réexaminer les conditions de la source avant de changer ces listes. Les données privées ULaval restent hors du dépôt et des archives publiques.

## Contribuer

Les [directives du dépôt](AGENTS.md) s’appliquent à chaque ajout. Tout nouveau jeu de données, y compris un jeu hébergé dans un dépôt externe, doit recevoir une illustration créée avec un outil de génération d’images avant sa publication. Regarder les illustrations de `assets/illustrations/datasets/` pour conserver leur style et leur palette. Un graphique calculé, une photographie ou une capture d’écran ne remplace pas cette illustration.

La vignette évoque le sujet sans représenter des observations ou des résultats. Préparer une image horizontale 16:9 sans texte ni logo, puis enregistrer le WebP de 960 × 540 pixels dans `assets/illustrations/datasets/<id>.webp`. Conserver l’original, compléter `manifest.json`, consigner le prompt exact et l’outil dans `provenance.json`, et ajouter les crédits dans `credits-images.qmd`. Vérifier l’image dans le catalogue avant de publier.

Les démonstrations autonomes sont conservées dans `publication/demonstrations/`. Le rendu du site les recalcule depuis leurs sources Quarto, vérifie les empreintes des données et construit leurs pages de lecture et l’archive téléchargeable. Le contrôle `scripts/check_demonstrations.R` vérifie les fichiers distribués. Les HTML et ZIP générés de ce dossier sont exclus du dépôt source.

Les [modèles](templates/) définissent la structure d’une fiche, d’une activité et de leurs métadonnées. Une contribution doit fournir un script de préparation, au moins une activité déclarée avec sa page Quarto, ses métadonnées, son script exécutable et ses ressources de lancement. Les concepts et niveaux viennent de `data/metadata/taxonomie.yml`; ajouter un alias à une notion existante plutôt qu’un doublon de casse ou d’accent.

Un jeu peut aussi être référencé avec ses fichiers hébergés chez la personne qui le propose, sans créer d’activité locale. Sa fiche et ses métadonnées déclarent alors `publication.classroom.mode: external`, `publication.preview: false`, une liste `files` vide et deux liens HTTPS : `source_url` pour le dépôt et `download_url` pour les données. Ce mode ne produit ni aperçu tabulaire ni trousse. Documenter la version examinée, les limites et les conditions des producteurs; créditer la personne dans `contributor_name` et décrire son rôle dans `contributor_role`. Le score pédagogique peut rester `null` tant qu’aucune activité n’a été préparée. La fiche Hydro-Québec illustre ce cas.

La disponibilité technique d’une trousse n’établit pas son efficacité pédagogique. La [fiche de retour de classe](templates/retour-classe-template.md) permet de documenter les usages et difficultés sans données personnelles étudiantes.

## Billets et actualités

La page `actualites.qmd` rassemble les billets `resources/billet-*.qmd`, du plus récent au plus ancien, dans des encadrés distincts avec une recherche par mots-clés. Elle accueille aussi les annonces et les publications particulières du projet; les catégories restent libres. L’accueil affiche automatiquement le dernier billet. Un flux RSS est généré dans `actualites.xml`.

Pour ajouter un billet, créer sa page dans `resources/` avec un nom commençant par `billet-`. Renseigner `title`, `description`, `author`, `date` au format `AAAA-MM-JJ`, `categories`, `image`, `image-alt` et `embed-resources: true` dans le YAML. Reprendre la structure de `resources/billet-elections-quebec-2026.qmd` et référencer l’illustration existante du jeu lorsque le billet lui est consacré.

Ajouter sa notice de type `document` à `data/metadata/ressources.yml` et appeler `render_resource_notice_identity(..., show_record_dates = FALSE)` dans l’en-tête. Le billet apparaît ainsi dans les lectures et dans la recherche commune. Le texte est rédigé dans le contexte de sa date éditoriale, sans notes sur une rédaction ultérieure. Il peut reprendre la date d’ajout d’un jeu ou d’un événement vérifié; pour un lancement, vérifier la première mise en ligne réussie, pas seulement la date du premier commit. Conserver les dates réelles de la notice dans les métadonnées, sans les afficher dans le billet. Citer une version fixe pour les nombres issus d’un fichier évolutif. Une annonce de diffusion ne prouve pas l’intégration de nouveaux résultats au dépôt.

Rendre le site avec `scripts/render_site.R`, puis lancer `scripts/check_site.R`. Vérifier le classement, la carte d’accueil, le billet, le flux RSS et les liens sur une fenêtre étroite avant la publication.

## Publication

Le workflow valide l’environnement, les règles de publication, les trousses et les analyses, puis construit et vérifie un site neuf. Le déploiement sur `main` dépend du succès de cette validation et utilise son artefact exact. Les demandes de fusion produisent un artefact de consultation sans déploiement.

Dans les paramètres Pages du dépôt, la source doit être GitHub Actions. Après une livraison, vérifier le workflow terminé et les pages et téléchargements publics. Un simple changement dans le dossier `docs/` ne constitue pas une preuve de publication validée.

Le rendu final ajoute les descriptions et les URL canoniques, les métadonnées Open Graph et Twitter Card, ainsi que le balisage JSON-LD `Dataset` sur les fiches de données. `R/utils_seo.R` utilise les métadonnées des ressources et conserve les conditions de réutilisation complètes. Les producteurs d’origine ne sont pas attribués comme créateurs des adaptations. Les licences mixtes ou restrictives restent dans `usageInfo`; seules les licences uniques explicitement documentées alimentent `license`. Les trousses d’acquisition sans données ne deviennent pas des distributions de données.

Le sitemap et `robots.txt` sont finalisés après toutes les pages, y compris les démonstrations autonomes, puis après chaque export d’application. Les reçus d’export portent ainsi sur le HTML final. Les pages de redirection vers les éditeurs reçoivent `noindex, follow` et restent hors du sitemap. Les URL utilisent `https://donneesbleues.ca/`, avec une adresse canonique terminée par `/` pour l’accueil et les applications. Aucune date `lastmod` n’est déduite du moment du build. `scripts/check_seo.R`, appelé par le contrôle du site et après les exports en CI, vérifie ces métadonnées et la couverture du sitemap. Ajouter la description d’une nouvelle page générale dans `seo_root_descriptions`; les fiches, activités et notices utilisent leur registre existant.

La vérification de propriété et la soumission du sitemap dans Google Search Console nécessitent le compte du propriétaire du site. Après vérification, soumettre `https://donneesbleues.ca/sitemap.xml`, inspecter l’accueil, le catalogue et quelques fiches, puis suivre les rapports d’indexation. Si Google fournit une balise HTML de vérification, la conserver dans un fichier inclus avec `include-in-header` dans `_quarto.yml`. Un fichier HTML de vérification doit être ajouté aux ressources Quarto pour survivre aux reconstructions. Ces démarches ne garantissent ni l’indexation ni un classement.

Références : Google Search Central, [balisage Dataset](https://developers.google.com/search/docs/appearance/structured-data/dataset), [sitemaps](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap) et [vérification de propriété](https://support.google.com/webmasters/answer/9008080).

## Documents, outils, tutoriels et recherche commune

`ressources.qmd` rassemble les données, activités et notices de `data/metadata/ressources.yml`. Les documents (articles, billets, journaux, notes, PDF) et outils ou tutoriels (Shiny, learnr, applets) utilisent le modèle `templates/ressource-template.yml`. Ils doivent présenter un lien vérifiable avec l’enseignement de la science des données au Québec.

Chaque notice sépare auteur ou organisme source, contribution au répertoire et cours d’utilisation. Un cours est une utilisation documentée, pas une suggestion : renseigner `courses` et conserver sa preuve dans `course_evidence`. Les fiches et activités existantes acceptent aussi une liste `courses` dans leur fichier YAML. Sans preuve, la page indique « usage non documenté ».

Les quatre types de ressources partagent des badges avec icône, couleur et libellé. Les dates `date_added` et `date_updated`, au format `AAAA-MM-JJ`, désignent la fiche dans le répertoire. Elles sont distinctes de la période d’observation, de `access_date` et de la date de publication d’un article externe. Conserver la date d’ajout, puis actualiser la date de mise à jour lors d’une modification du contenu, des données associées ou des métadonnées propres à la ressource. Un rendu ou une modification de la présentation générale du site ne change pas ces dates.

Les dates initiales ont été reconstituées à partir des premières additions et des derniers changements enregistrés dans Git. Elles ne prétendent pas dater la première mise en ligne publique. Le tableau `data/metadata/resource_dates_initialization.csv` conserve cette initialisation ; `scripts/initialize_resource_dates.R` documente la méthode et ne remplace pas les dates déjà renseignées. Pour les documents, outils et tutoriels, seuls les changements de l’entrée concernée dans le registre sont retenus.

Utiliser les modèles Quarto du dossier `templates/` : les fiches de données appellent `render_dataset_detail_header()`, les activités `render_activity_header()`, et les notices de documents, d’outils ou de tutoriels `render_resource_notice_identity()`. Les styles communs sont dans `assets/css/resource-identity.css`. Les tests vérifient les dates et les en-têtes de chaque fiche rendue, ainsi que leur présence dans les résultats de recherche.

Les liens externes n’accordent aucun droit supplémentaire de redistribution. Les ressources restent hébergées à leur source. Pour une nouvelle notice, copier le modèle de document, d’outil ou de tutoriel dans `resources/` ; le rendu complet l’inclut dans la recherche générale. Lancer `Rscript tests/test_resources.R`, puis `Rscript scripts/render_site.R` et `Rscript scripts/check_site.R`.

Le formulaire de contribution fonctionne avec un brouillon courriel sans compte GitHub. L’envoi direct est préparé dans `server/`, avec activation distincte de l’hébergement et du SMTP. Voir `server/README.md`.

## Rédiger une ressource

La [charte éditoriale](charte-editoriale.qmd) précise le contenu des fiches et des activités. Les résumés, périodes, limites essentielles et producteurs sont renseignés dans `metadata.yml`. Les composants communs affichent les accès et les crédits; ne pas les recopier dans les textes.
