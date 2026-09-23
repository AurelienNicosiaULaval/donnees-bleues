# Instantané des trajectoires YUL

Ces trois RDS sont des tables dérivées des [archives trimestrielles MrAirspace](https://github.com/MrAirspace/aircraft-flight-schedules) de 2024 T1 à 2026 T2, préparées le 23 septembre 2026. Le projet source attribue les transmissions ADS-B à ADSB.lol et signale aussi des données de validation d'itinéraires et de types d'appareils. Les données et leurs dérivés sont fournis sous [ODbL 1.0](LICENSE-ODbL.txt). Conserver cette attribution et le lien de licence lors de toute redistribution.

- `vols.rds` : 491 786 trajectoires retenues, 48 variables; SHA-256 `31b416c7a3607d94bb14a8e80d9dfe556f364c23862ec3946ef5855e18337ff0`.
- `trafic_quotidien.rds` : 912 jours du calendrier; SHA-256 `5ddb1b4bf9c03f8c6aa4ad8a2cecccdedb48a44efb909bb741a2c3068b81db09`.
- `liaisons.rds` : 1 460 paires d'aéroports identifiés; SHA-256 `415da71eeda18ae53330559fd4f8890b61cc4d94f3daf13ee4842f159df4a9ff`.

La [méthode](../METHODE.md) décrit la sélection des observations et les limites. Le [manifeste des archives](archives_vols.csv) conserve les URL et empreintes sources. Aucun de ces trois fichiers ne contient les observations météo ECCC ni les référentiels OurAirports ou OpenFlights ajoutés dans la préparation privée.

Depuis la racine du dépôt :

```r
vols_yul <- readRDS("datasets/vols-montreal-trudeau/source/vols.rds")
nrow(vols_yul)
```
