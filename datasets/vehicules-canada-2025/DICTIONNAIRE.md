# Dictionnaire des deux tables

Source : Aurélien Nicosia (2026), [version 1.0.0](https://github.com/AurelienNicosiaULaval/vehicules-quebec/releases/tag/v1.0.0), dérivée de RNCan et de la SAAQ. Les deux tables ont des unités d’observation différentes et ne sont pas jointes.


## Configurations canadiennes de 2025

| Variable | Type | Unité | Description |
|:--|:--|:--|:--|
| vehicle_id | character |  | Identifiant de la ligne RNCan dans la version figée; aucune immatriculation individuelle. |
| make | character |  | Marque publiée par RNCan. |
| model | character |  | Modèle et version tels que publiés; une configuration par couple marque-modèle nommé. |
| model_year | integer | année | Année modèle, constante à 2025; ce n'est pas l'année d'immatriculation. |
| vehicle_class | character |  | Classe RNCan publiée dans le fichier source. |
| vehicle_class_group | character |  | Regroupement documenté : passenger_car, suv, pickup, van ou wagon. |
| engine_size_l | double | L | Cylindrée du moteur thermique; ce n'est pas une puissance. |
| cylinders | integer | cylindres | Nombre de cylindres du moteur thermique. |
| transmission | character |  | Code RNCan complet conservé, par exemple AS8 ou AV. |
| transmission_type | character |  | Décodage du préfixe A, AM, AS, AV ou M; AM n'est pas une boîte manuelle conventionnelle. |
| fuel_type | character |  | Essence ordinaire (regular_gasoline) ou super (premium_gasoline); ne suffit pas à distinguer tous les hybrides. |
| city_l_per_100km | double | L/100 km | Cote de consommation urbaine publiée; conditions d'essai normalisées. |
| highway_l_per_100km | double | L/100 km | Cote routière publiée; conditions d'essai normalisées. |
| combined_l_per_100km | double | L/100 km | Cote combinée publiée, fondée sur 55 % de parcours urbain et 45 % routier avant arrondi. |
| combined_mpg_imperial | double | milles/gallon impérial | Valeur entière publiée par RNCan; gallon impérial, différent de mtcars. |
| combined_mpg_us | double | milles/gallon américain | Conversion de combined_l_per_100km avec 235,214583333333; arrondie à quatre décimales, sans information nouvelle. |
| co2_g_per_km | double | g/km | CO2 à l'échappement publié; pas une analyse de cycle de vie; fortement lié à la consommation et au carburant. |
| co2_rating | double | cote 1 à 10 | Cote ordinale CO2 publiée, 10 étant la meilleure cote. |
| smog_rating | double | cote 1 à 10 | Cote ordinale des polluants contribuant au smog, 10 étant la meilleure cote. |

## Parc québécois de 2022 dans le périmètre retenu

| Variable | Type | Unité | Description |
|:--|:--|:--|:--|
| saaq_snapshot_year | integer |  | Année du portrait au 31 décembre, constante à 2022. |
| region_qc | character |  | Libellé et code de région administrative tels que publiés, lus comme texte. Une région manquante reste manquante. |
| saaq_fuel_code | character |  | Code SAAQ original du carburant; consulter references/saaq_fuel_codes.csv. |
| saaq_fuel_type | character |  | Libellé du code de carburant issu de la documentation SAAQ; code manquant indiqué Non précisé. |
| number_registered_qc | integer |  | Nombre de véhicules autorisés à circuler : type AU et classes PAU, CAU ou RAU. Ne couvre pas tous les usages de véhicules légers. |
