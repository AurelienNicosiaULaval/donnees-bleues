## Ce que les données permettent de dire aujourd'hui

Les annonces tarifaires, les textes juridiques et les statistiques décrivent trois objets différents. Au 5 octobre 2026, cette édition documente les nouveaux contre-tarifs canadiens, mais ses dernières observations de prix et de commerce concernent juillet. Elles précèdent donc les mesures de septembre. Il est possible de montrer des trajectoires historiques; il n'est pas possible, avec cette édition, d'estimer l'effet de ces nouvelles mesures sur les prix au Québec. [Statistique Canada, tableaux 18-10-0245-01 et 12-10-0175-01, diffusions des 2 et 3 septembre 2026](https://doi.org/10.25318/1810024501-fra), [tableau du commerce](https://doi.org/10.25318/1210017501-fra).

L'analyse distingue les faits documentés, les calculs descriptifs et les questions ouvertes. Les quatre articles examinés constituent une sélection datée, sans prétention à représenter tous les médias. La période couverte par une statistique reste différente de la date à laquelle sa page a été modifiée.

```{r}
#| label: preparation-analyse-tarifs
#| include: false
racine <- if (file.exists("datasets/tarifs-douaniers-quebec/activite-lire-tarifs.R")) "." else ".."
ancien <- getwd()
setwd(racine)
invisible(capture.output(source("datasets/tarifs-douaniers-quebec/activite-lire-tarifs.R", local = knitr::knit_global())))
setwd(ancien)
```

## Quels taux, sur quelles marchandises?

Le décret DORS/2026-186 est enregistré le 4 septembre et publié le 23 septembre, avec une entrée en vigueur le 8 septembre. Ses annexes 1, 2 et 3 indiquent respectivement des surtaxes de 15 %, 25 % et 50 % sur les marchandises américaines concernées, sous les conditions du texte. Les exemptions et remises exigent une lecture distincte. [Gazette du Canada, 23 septembre 2026](https://gazette.gc.ca/rp-pr/p2/2026/2026-09-23/html/sor-dors186-fra.html).

L'extraction compte 335 codes dans ces trois annexes et retrouve leurs taux dans la liste récapitulative de Finances Canada. Cette dernière compte 648 lignes pour le panneau du 8 septembre : les 313 autres codes correspondent au panneau antérieur consacré à l'acier et à l'aluminium. Ces nombres sont des résultats de comptage de la compilation, sans pondération commerciale. [Ministère des Finances, liste complète, consultation du 5 octobre 2026](https://www.canada.ca/fr/ministere-finances/programmes/politiques-finances-echanges-internationaux/reponse-canada-droits-douane-americains/liste-complete-produits-americains-assujettis-contre-mesures-tarifaires.html).

```{r}
#| echo: false
#| fig-alt: "Nombre de codes tarifaires dans le panneau du 8 septembre 2026, selon la surtaxe de 15, 25 ou 50 pour cent. Les codes ne sont pas pondérés par les importations."
plot_codes
```

Compter des codes n'indique ni leur poids économique, ni le nombre de biens vendus, ni le montant payé. Le taux affiché est une surtaxe nominale. La base ne résout pas intégralement les traitements préférentiels, les exemptions, les remises et les règles de cumul nécessaires à une facture douanière.

Pour les lingots de fer et d'aciers non alliés d'origine américaine, code canadien 7206.10.00, les sources indiquent 25 % du 13 mars 2025 au 7 septembre 2026, puis 50 % à partir du 8 septembre. La trajectoire ci-dessous est reconstituée pour ce seul code. Elle n'impute aucun taux aux périodes non documentées. [Finances Canada, acier et aluminium, consultation du 5 octobre 2026](https://www.canada.ca/fr/ministere-finances/programmes/politiques-finances-echanges-internationaux/droits-douane-canada-en-reponse/droits-douane-canada-acier-et-aluminium.html).

```{r}
#| echo: false
#| fig-alt: "Surtaxe canadienne sur les lingots américains : 25 pour cent depuis le 13 mars 2025, puis 50 pour cent depuis le 8 septembre 2026, avant exemptions et remises."
plot_tarifs
```

## Quatre nouvelles, quatre vérifications

| Nouvelle consultée | Ce qu'il faut vérifier dans les sources |
|---|---|
| [Agence QMI, TVA Nouvelles, 8 septembre 2026 : coût et justification des contre-tarifs](https://www.tvanouvelles.ca/2026/09/08/contre-tarifs-le-canada-a-pris-la-bonne-decision-en-quittant-les-negos-repete-mark-carney) | La valeur d'importations visées n'est pas le coût des droits, une dépense des ménages ou une perte de PIB. La justification du gouvernement demeure une position attribuée. |
| [CP24, description publique de la vidéo du 27 août 2026 : retrait des poissons et fruits de mer](https://www.youtube.com/watch?v=fg7R8YP8Pbw) | Une liste annoncée peut être révisée avant son application. Le résumé d'étude d'impact du décret confirme le retrait après consultation; la date exacte du retrait n'y est pas précisée. |
| [Eliott Dumoulin, Le Monde, 14 septembre 2026 : diversification commerciale](https://www.lemonde.fr/economie/article/2026/09/14/le-canada-multiplie-les-initiatives-pour-attenuer-sa-dependance-economique-aux-etats-unis_6773786_3234.html) | Une initiative politique et une réorientation observée des échanges restent distinctes. Les données québécoises permettent une description, sans attribuer une cause ou prédire la durée du changement. |
| [Kelly Geraldine Malone, La Presse canadienne, CityNews, mise à jour du 29 septembre 2026 : interdictions américaines](https://toronto.citynews.ca/2026/09/28/trump-says-he-expects-canada-trade-deal-within-weeks-as-import-ban-looms/) | L'article rapporte des interdictions touchant certains produits. Une interdiction est un autre type de restriction; elle ne doit pas être enregistrée comme un taux de 100 %. |

L'annonce fédérale du 25 août décrit des mesures visant une valeur de 27,6 milliards de dollars d'importations en provenance des États-Unis. Ce montant ne doit pas être présenté comme une recette fiscale ou une facture québécoise. Les poissons et fruits de mer montrent pourquoi la liste initiale et le texte adopté doivent être conservés séparément. [Finances Canada, annonce du 25 août 2026](https://www.canada.ca/fr/ministere-finances/nouvelles/2026/08/le-canada-annonce-des-contre-mesures-ciblees-ainsi-que-des-mesures-importantes-pour-soutenir-les-travailleurs-et-les-entreprises-en-reponse-aux-dro.html), [Gazette du Canada, résumé d'étude d'impact, 23 septembre 2026](https://gazette.gc.ca/rp-pr/p2/2026/2026-09-23/html/sor-dors186-fra.html).

Dans l'exemple des boissons alcoolisées, la proclamation américaine du 8 septembre prévoit l'exclusion de certaines marchandises canadiennes à compter du 29 septembre, avec une annexe et des dispositions transitoires. Sa portée ne se résume pas à l'ensemble des boissons canadiennes. La chronologie de la base conserve cet événement comme une interdiction et ne prétend pas intégrer tous les codes américains concernés. [Maison-Blanche, proclamation du 8 septembre 2026](https://www.whitehouse.gov/presidential-actions/2026/09/excluding-certain-canadian-alcoholic-beverages-from-importation-into-the-united-states-in-response-to-continued-discrimination-against-the-commerce-of-the-united-states-with-respect-to-alcoholic-bever/).

## Pourquoi le taux douanier ne prédit pas directement le prix en magasin

Un taux s'applique à une valeur en douane selon une règle juridique; un prix de détail inclut d'autres coûts et marges. Les séries de prix de cette édition ne renseignent ni l'origine douanière, ni l'importateur, ni le tarif effectivement acquitté. Le nom d'un produit ne suffit pas à le relier à un code douanier. [Statistique Canada, présentation des prix moyens, 2 septembre 2026](https://www150.statcan.gc.ca/n1/daily-quotidien/260902/dq260902a-fra.htm).

Le document de travail de Cavallo, Kostyshyna, Kryvtsov et Vieyra (2026) étudie les contre-tarifs de 2025 à partir des prix en ligne de sept grands détaillants canadiens. Les auteurs trouvent une hausse relative d'environ 6 % après trois mois pour les produits exposés, face à une surtaxe de 25 %. Il s'agit d'un résultat de recherche sur ce contexte, pas d'une règle applicable à tous les produits ni d'une estimation du Québec en septembre 2026. [Banque du Canada, document de travail du personnel 2026-22](https://doi.org/10.34989/swp-2026-22).

La distinction entre taux nominal et moyenne pondérée est également essentielle. Les hypothèses de projection de la Banque du Canada en juillet 2026 retiennent des taux moyens de 5,0 % pour les droits américains sur le Canada et de 1,5 % dans l'autre sens, selon l'information disponible le 10 juillet. Ces hypothèses datées ne sont ni les taux de chaque code ni une mesure actualisée après septembre. [Banque du Canada, hypothèses tarifaires du 15 juillet 2026](https://www.banqueducanada.ca/publication/rpm/rpm-2026-07-15/hypotheses-tarifaires/).

```{r}
#| echo: false
#| fig-alt: "Indices calculés des prix moyens du lait, du café et des œufs au Québec. Chaque série vaut 100 en janvier 2025; les observations s'arrêtent en juillet 2026."
plot_prix
```

L'indice est calculé séparément : prix du mois divisé par prix de janvier 2025, multiplié par 100. Il permet de comparer des évolutions relatives, sans rendre les conditionnements équivalents. Ce sont des indices descriptifs calculés ici, pas des composantes officielles de l'IPC. Les prix moyens peuvent aussi refléter la composition des achats; Statistique Canada signale un élargissement de couverture en janvier 2024. Le graphique commence en 2025 et ne constitue pas une analyse de l'effet des tarifs. [Statistique Canada, tableau 18-10-0245-01, notes](https://www150.statcan.gc.ca/t1/tbl1/fr/tv.action?pid=1810024501).

## Que montrent les échanges québécois?

Le tableau 12-10-0175-01 fournit des valeurs mensuelles sur base douanière, en dollars courants et sans désaisonnalisation. Cette édition retient le Québec, 13 catégories et 29 partenaires, avec leurs indicateurs de statut. Le total et sa composante américaine sont montrés ensemble, mais ne doivent jamais être additionnés. Les courbes présentent des exportations nationales, distinctes des exportations totales incluant les réexportations. [Statistique Canada, tableau 12-10-0175-01, 3 septembre 2026](https://doi.org/10.25318/1210017501-fra).

```{r}
#| echo: false
#| fig-height: 7.5
#| fig-alt: "Importations et exportations nationales mensuelles du Québec vers tous les pays et les États-Unis, de janvier 2017 à juillet 2026, en milliards de dollars courants non désaisonnalisés."
plot_commerce
```

Le bilan de l'ISQ du premier semestre 2026 indique que les États-Unis représentent 68,2 % des exportations québécoises. Leur valeur baisse de 7,2 % sur un an, contre 2,6 % pour l'ensemble des exportations. Ces données en dollars courants décrivent un poids commercial et une évolution, sans isoler un effet tarifaire. Les agrégats de l'ISQ cités ici ne sont pas distribués comme une nouvelle table. [ISQ, Bruno Verreault, 22 septembre 2026](https://statistique.quebec.ca/fr/produit/publication/commerce-international-marchandises-balance-commerciale).

Un autre communiqué indique une hausse mensuelle de 7,2 % des exportations réelles désaisonnalisées en juillet, mais une baisse de 4,2 % pour janvier à juillet comparativement à 2025. Ces constats ne se contredisent pas : leurs périodes diffèrent. Il faut également distinguer dollars courants et constants. L'ISQ rappelle que les importations demeurent partielles et révisables en raison des retards de traitement liés à la GCRA. [ISQ, 18 septembre 2026](https://statistique.quebec.ca/fr/communique/hausse-7-virgule-2-pourcent-exportations-internationales-marchandises-juillet-2026).

## Ce qu'il reste à mesurer

Un suivi descriptif est déjà reproductible avec cette édition. Une estimation des effets des mesures de septembre nécessitera des observations après leur entrée en vigueur, une exposition documentée par produit, des règles douanières résolues et une comparaison pertinente. Un protocole pourrait comparer les changements de prix de produits exposés et non exposés, après examen des tendances antérieures et des autres chocs. Aucun tel modèle n'est ajusté ici.

La couverture actuelle reste partielle : les tarifs ordinaires, tous les régimes étrangers, les exemptions et remises, ainsi que les flux détaillés par code SH ne sont pas intégrés exhaustivement. Une nouvelle édition devra conserver la précédente, ajouter ses dates et distinguer les données provisoires des données révisées. Les taux, les nouvelles et les observations économiques pourront alors être suivis dans le temps sans transformer une annonce en résultat mesuré.
