# Dictionnaire de la base

Tous les fichiers CSV sont encodés en UTF-8, avec des virgules comme séparateurs et un point décimal. Une cellule vide représente une valeur manquante. Les identifiants permettent les jointures sans utiliser le nom de la municipalité comme clé.

## programmes.csv

| Champ | Sens |
|---|---|
| programme_id | Identifiant du programme couvert. |
| municipalite | Municipalité où le programme étudié est offert. |
| edition | Année étudiée, 2026 dans ce pilote. Gatineau est contextualisé dans `qualite.csv`. |
| territoire | Québec, province. |
| type | Programme municipal ou gestionnaire communautaire. Ce champ n'établit pas le statut juridique de l'organisme. |
| libelle, portee | Nom du programme ou gestionnaire et limites de couverture. |

## faits.csv

Une ligne correspond à une variable d'un programme. La clé est `(programme_id, variable)`.

| Champ | Sens |
|---|---|
| variable | Horaire, période, âge, résidence, garde, repas, rabais, aide, accompagnement ou autre condition. |
| valeur | Transcription normalisée; texte pour les conditions, heures `HH:MM-HH:MM`, période `AAAA-MM-JJ/AAAA-MM-JJ`. |
| unite | Unité, lorsqu'une valeur numérique est employée. |
| condition | Restriction ou contextualisation de la transcription. |
| preuve_id | Jointure vers la preuve; vide pour une inconnue. |
| statut | `documente` ou `non_documente`. Une absence de mention ne signifie pas absence de service. |

`horaire_regulier` désigne l'horaire annoncé du camp dans la source; à Lévis et Trois-Rivières, ce créneau comprend la garde. Il ne mesure pas la durée quotidienne des activités dirigées. `horaire_avec_garde` indique la couverture annoncée avec la garde applicable, et non la disponibilité effective d'une place. `periode_forfait` est distinct de `periode_camp`. Les références d'âge sont conservées textuellement, sans les transformer en admissibilité certaine pour un enfant particulier.

## tarifs.csv

| Champ | Sens |
|---|---|
| tarif_id | Clé unique du tarif dans cette version. |
| programme_id, variante | Programme et variante; CCA à la journée, MÉLI-MÉLO, ZIP-ZAP ou excursion datée. |
| composante | Camp, camp avec garde, garde, garde étendue, dossier, activités, autobus, sortie ou pénalité. |
| montant_min, montant_max | Prix ou bornes de la fourchette publiée, en dollars canadiens. Pour un prix fixe les bornes sont égales. |
| montant_source, maximum_source | Tokens monétaires relus dans la source, avant normalisation. |
| devise | `CAD`. |
| periode | `semaine`, `saison`, `jour`, `inscription`, semaine partielle, `sortie`, `tranche_5_minutes`, ou `non_precisee`. |
| base_facturation | `enfant`, `famille`, `enfant_selon_taille_famille` ou `inscription`. |
| residence | `resident`, `non_resident`, `non_precisee`. Les ententes entre municipalités sont dans les conditions. |
| rang_min, rang_max | Rang d'enfant auquel s'applique le prix. Une borne maximale vide signifie « et suivants » uniquement si la borne minimale est renseignée. Deux bornes vides signifient catégorie de rang non spécifiée. |
| famille_min, famille_max | Nombre d'enfants dans la famille pour une tarification familiale ou par taille de famille. Même convention pour la borne maximale. Ne pas confondre avec le rang d'enfant. |
| statut_unite | `explicite`, `contextuelle` ou `a_confirmer`. |
| condition, preuve_id | Restriction d'application et jointure vers la source. |

Le quatrième enfant de Québec est une catégorie exacte dans la fiche retenue; aucune catégorie « cinquième et suivants » n'est créée. À Tingwick, les 300 CAD pour deux enfants sont le prix de la famille, pas un prix par enfant. Au CCA de Victoriaville, 15,50 CAD par jour s'appliquent à chaque enfant d'une famille de deux enfants. Un prix saisonnier ne vaut pas automatiquement le produit d'un prix hebdomadaire par le nombre de semaines.

## preuves.csv et sources.csv

`preuves.csv` relie chaque observation à `source_id`, à l'organisme, à l'URL, à la date de collecte, aux empreintes SHA-256 des fichiers HTML et texte originaux. `ligne_txt` est une ligne du texte normalisé; `ancre` est le fragment vérifié sur cette ligne. Pour une cellule HTML, `localisation` indique le numéro de tableau, de ligne et de colonne, tous à partir de 1. Les cellules fusionnées sont développées par rvest. `methode` distingue une transcription relue et une cellule de tableau.

`sources.csv` décrit les quatorze pages retenues, leur rôle, l'URL demandée et finale, leur statut HTTP et les empreintes des documents originaux. Le statut technique `a_relire` du reçu signifie contenu capturé; les observations effectivement relues sont établies par les preuves. Certaines pages servent de référence complémentaire sans fournir de valeur structurée dans cette version.

## scenario.csv et calculs_scenario.csv

`scenario_id` définit le besoin simulé. `montant_min` et `montant_max` sont des sous-totaux calculés; `tarifs_utilises` conserve les tarifs employés. `statut` distingue somme des tarifs documentés, calcul conditionnel et calcul impossible avec les données retenues. `reserve` donne les limites propres au cas. `calculs_scenario.csv` garde une ligne par composante, son `multiplicateur` et son tarif source. Les scénarios sont des calculs analytiques, pas des observations du montant réellement payé.

## qualite.csv et validation.json

`qualite.csv` conserve les références à confirmer, avec un identifiant, le programme, le niveau et la description. `validation.json` indique les effectifs et le résultat des contrôles de structure et de provenance. Une validation technique réussie ne résout pas les ambiguïtés des sources. `empreintes.csv` permet de vérifier que les fichiers de cette version sont restés identiques.

Les archives HTML et texte ne sont pas incluses dans cette distribution publique. Les références de lignes concernent les instantanés normalisés utilisés lors de la transcription, pas une version actuelle de la page. Les CSV publics omettent les chemins locaux et quelques champs techniques des reçus.
