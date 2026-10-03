# Méthode du parcours de permutation

Version 1.0.0, préparée le 3 octobre 2026 à partir du CSV officiel SAAQ des rapports 2022. Aucun tirage ni retrait de lignes n’est effectué. Le fichier contient 108 186 rapports, dont 82 168 en semaine et 26 018 la fin de semaine. Les décomptes d’accidents avec victimes sont respectivement 16 740 et 5 758.

La statistique est la proportion de fin de semaine moins celle de semaine, multipliée par 100 : l’unité est le point de pourcentage. Le test est bilatéral, avec le critère de valeur absolue et les égalités incluses.

Le modèle nul suppose que, conditionnellement aux effectifs de groupes et au nombre total d’accidents avec victimes, les statuts de victime sont échangeables entre tous les rapports. On conserve les groupes et permute ces statuts sans remise. Une première permutation explicite permet d’examiner les lignes; les suivantes simulent directement le nombre de statuts avec victimes affectés à la fin de semaine, par la loi hypergéométrique. Les deux calculs ont la même distribution conditionnelle.

Avec k permutations au moins aussi extrêmes parmi B, la p-valeur Monte-Carlo est (k + 1)/(B + 1). Une référence sans simulation somme les probabilités hypergéométriques pour le même critère. La convention bilatérale peut différer de celle de `fisher.test()`, qui ordonne les tableaux par leur probabilité.

Une graine et les trois algorithmes aléatoires de R sont fixés. L’état aléatoire de l’appelant est restauré. Les scripts exportés utilisent le même moteur que l’application et l’activité. Augmenter B ne change ni les observations ni l’écart observé.

Ces rapports administratifs ne proviennent pas d’une affectation aléatoire de jours. La météo, les heures, les régions et les regroupements d’événements peuvent rendre le mélange global inadéquat. Le calcul illustre un test sous ce modèle; sa validité pour une généralisation n’est pas établie. Décrire l’écart dans le fichier n’exige pas de test. Sans nombre de trajets ou distance parcourue, aucune probabilité d’accident par exposition n’est estimée et aucune cause n’est identifiée.

Références : SAAQ, [données et documentation officielles](https://www.donneesquebec.ca/recherche/dataset/rapports-d-accident); Phipson et Smyth (2010), [Permutation P-values Should Never Be Zero](https://doi.org/10.2202/1544-6115.1585); R Core Team, [loi hypergéométrique](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/Hypergeometric.html), consultée le 3 octobre 2026.
