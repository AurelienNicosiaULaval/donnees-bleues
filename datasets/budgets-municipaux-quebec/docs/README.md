# Budgets municipaux du Québec

Source officielle : https://www.donneesquebec.ca/recherche/dataset/profil-financier-des-municipalites-locales

Question d'analyse : Les municipalités dépensent-elles différemment selon leur taille?

Variables pédagogiques proposées : `municipalite`, `annee`, `population`, `revenus_totaux`, `depenses_totales`, `dette`, `categorie_depense`.

Notes : Les noms de variables pédagogiques sont harmonisés; ils devront être mappés aux noms officiels du fichier annuel choisi.

Les fichiers bruts ne sont pas redistribués par défaut. Déposer la ressource officielle retenue dans `data_raw/`, puis utiliser `preparation.R` pour produire une version préparée dans `data_processed/`.
