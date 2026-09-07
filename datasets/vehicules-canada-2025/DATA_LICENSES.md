# Sources, transformations et conditions

Aurélien Nicosia (2026), [Véhicules : données canadiennes et parc québécois, version 1.0.0](https://github.com/AurelienNicosiaULaval/vehicules-quebec/releases/tag/v1.0.0). Le jeu principal est une sélection pédagogique de cotes RNCan, et le tableau québécois est une agrégation SAAQ distincte. Il ne s’agit pas d’une nouvelle collecte.

## Données RNCan

Ressources naturelles Canada (2026), [Cotes de consommation de carburant](https://open.canada.ca/data/en/dataset/98f1a129-f628-4ce4-b24d-6f16bf24dd64), ressource 2025 recueillie le 2 juillet 2026. Contient de l’information visée par la [Licence du gouvernement ouvert – Canada](https://ouvert.canada.ca/fr/licence-du-gouvernement-ouvert-canada).

Adaptations de la version source : sélection déterministe de 64 configurations de 2025, une par marque et modèle nommé, diversité des classes et transmissions, noms de colonnes normalisés, catégories décodées et conversion explicite en mpg américain. Aucune consommation publiée n’est imputée ou corrigée. Un écart mineur entre cotes ville-route et combinée est conservé pour le Ford Maverick Hybrid. Les configurations ne sont ni des ventes ni des véhicules immatriculés au Québec.

## Données SAAQ

Société de l’assurance automobile du Québec (2023), [Véhicules en circulation](https://www.donneesquebec.ca/recherche/dataset/vehicules-en-circulation), portrait au 31 décembre 2022, documentation du 30 novembre 2023. Licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr).

Adaptations : sélection du type AU et des classes PAU, CAU ou RAU, regroupement par région administrative et carburant déclaré. Les 152 cellules totalisent 5 507 330 véhicules dans ce périmètre. Les régions manquantes et les codes inhabituels restent ceux de la source. Aucune correspondance avec les configurations RNCan n’est prétendue.

## Adaptation à Données bleues

Les deux tables gardent leurs lignes, leurs colonnes et leurs valeurs de la version 1.0.0. Le conditionnement de la trousse réécrit les CSV et peut modifier leur présentation textuelle; les valeurs sources et les identifiants sont conservés. Les scripts lisent des chemins locaux. Les dictionnaires sont réunis dans DICTIONNAIRE.md. Les empreintes de la trousse et des fichiers préparés figurent dans provenance.json et SHA256SUMS.

Le code et l’activité d’origine sont sous MIT, avec la notice LICENCE-SOURCE.md. Le code de l’adaptation est sous MIT; les textes propres à Données bleues sont sous CC BY 4.0, selon les notices générales incluses dans la trousse. Les données conservent les licences de leurs producteurs. Conserver les attributions et signaler les modifications lors d’une réutilisation. Aucun producteur n’endosse ce projet.

La [provenance des 64 configurations](https://raw.githubusercontent.com/AurelienNicosiaULaval/vehicules-quebec/v1.0.0/data_clean/vehicules_canada_2025_provenance.csv), les sources figées et le rapport de validation sont disponibles dans la publication d’origine. Les contrôles de l’adaptation ne constituent pas un essai pédagogique en classe.
