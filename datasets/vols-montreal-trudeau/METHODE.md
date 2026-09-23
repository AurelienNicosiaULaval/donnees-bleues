# Méthode de l'instantané YUL

Période : du 1er janvier 2024 à 00 h au 1er juillet 2026 à 00 h exclu, selon `America/Toronto`. Préparation initiale : 23 septembre 2026.

Les dix fichiers trimestriels mondiaux de [MrAirspace](https://github.com/MrAirspace/aircraft-flight-schedules), de 2024 T1 à 2026 T2, ont été parcourus entièrement. Les lignes dont les listes d'aéroports candidats contenaient CYUL à l'une des extrémités ont été extraites. Le [manifeste](source/archives_vols.csv) conserve pour chaque trimestre l'URL, l'empreinte SHA-256, le nombre de lignes mondiales et le nombre de candidates CYUL. Au total, 128 732 662 lignes mondiales ont été examinées et 531 374 candidates CYUL extraites.

Les archives trimestrielles se chevauchent. La règle du trimestre UTC du début de trajectoire, ou de la fin quand le début manque, a écarté 20 931 lignes. Une identité technique fondée sur l'immatriculation, l'indicatif, le début et la fin UTC a ensuite écarté 5 doublons. Un identifiant SHA-256 a été attribué à chaque identité. Les ensembles d'aéroports contradictoires pour une même identité sont exclus.

CYUL doit être l'unique candidat à une extrémité. Les 16 876 identités où CYUL n'apparaît que parmi plusieurs candidats sont exclues de la table principale. Après 1 776 autres exclusions, 491 786 trajectoires sont retenues. L'égalité `531 374 = 20 931 + 5 + 491 786 + 16 876 + 1 776` est vérifiée. Les fichiers d'audit complets sont conservés dans le dépôt privé de préparation, mais ne font pas partie de la trousse publique Données bleues.

Les vues des départs et arrivées nécessitent respectivement une origine ou une destination CYUL unique et une heure dans la période locale. Une trajectoire CYUL vers CYUL contribue aux deux vues. Les 2 566 trajets locaux expliquent pourquoi la somme des 248 842 départs et 245 510 arrivées observés dépasse de 2 566 les 491 786 trajectoires distinctes.

Les trois RDS suivis dans `source/` constituent un instantané fixe : la table complète des trajectoires, la table quotidienne et les liaisons dont les deux aéroports sont identifiés. `preparation.R` vérifie leurs empreintes, leurs dimensions et les totaux, puis produit les trois CSV de classe. Les sources mondiales d'origine demeurent accessibles aux URL du manifeste; la trousse ne régénère pas la reconstruction ADS-B depuis ces fichiers de plusieurs gigaoctets.

La couverture ADS-B n'est pas exhaustive ni constante. Un début ou une fin de trajectoire peut être éloigné de l'aéroport si le signal est perdu. L'attribution à CYUL reste une estimation géographique. Trois journées n'ont aucune observation retenue. Le nombre de candidates ambiguës est particulièrement élevé en 2024 T1. Ces points limitent l'interprétation des tendances; ils ne prouvent ni l'absence de trafic ni un changement réel du nombre de vols. Il n'y a pas d'horaire prévu ou de statut permettant de calculer retards et annulations.

La version publique Données bleues comprend seulement les tables dérivées des trajectoires MrAirspace. Elle ne contient ni météo ECCC ni référentiels OurAirports/OpenFlights. Les conditions de l'[ODbL 1.0](https://github.com/MrAirspace/aircraft-flight-schedules/blob/main/LICENSE-ODbL.txt) et la [notice d'attribution](DATA-LICENSE.md) s'appliquent aux données distribuées.
