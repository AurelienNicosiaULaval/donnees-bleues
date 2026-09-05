# Dictionnaire du jeu Arbres du Québec, version 1.0.0

Source : Aurélien Nicosia (2026), MRNF / PET5 et VASCAN. Voir DATA_LICENSES.md. Transcription des définitions du dictionnaire CSV publié ; 21 variables.

| Variable | Définition | Unité | Notes |
|:--|:--|:--|:--|
| species | Cible de la petite version |  | Seulement dans arbres_quebec_small.csv |
| species_code | Code d'essence MRNF |  | Ne pas confondre avec un nom scientifique |
| species_fr | Nom français source |  | NA si code absent/inconnu |
| species_latin | Nom scientifique accepté |  | VASCAN recommandé |
| genus | Genre taxonomique |  | NA tant que non apparié |
| family | Famille taxonomique |  | NA tant que non apparié |
| diameter_cm | DHP harmonisé | cm | Aucune imputation |
| height_m | Hauteur analytique avec provenance | m | Aucune hauteur estimée dans la version pédagogique |
| age_years | Âge mesuré | années | Âge publié par le MRNF au niveau de lecture de la carotte; pas nécessairement âge total. Voir SOURCE_AGE et NIVLECTAGE dans la provenance. Aucune imputation par le pipeline. |
| basal_area_m2 | Surface terrière de la tige | m² | Déterministe à partir du DHP |
| canopy_stratum | Étage relatif de l'arbre |  | NA si code absent/inconnu |
| ecological_region | Nom de région écologique |  | NA si code absent/inconnu |
| survey_year | Année de mesure | année | Ne pas inférer d'une autre date |
| plot_id | Identifiant de placette |  | Utiliser comme groupe de validation |
| tree_id | Identifiant stable de l'arbre |  | Permet le suivi longitudinal PEP |
| record_id | Identifiant unique de la ligne arbre-campagne |  | Clé primaire analytique |
| data_quality_flag | Indicateurs de qualité |  | Un drapeau n'entraîne pas suppression automatique |
| observation_quality | Classe synthétique d'observation |  | Classe documentaire, pas score scientifique validé |
| small_sampling_seed | Graine de l'échantillonnage |  | Jamais manquant dans small |
| small_n_per_species | Effectif visé et obtenu par espèce | observations | Jamais manquant dans small |
| small_sampling_rule | Règle d'échantillonnage |  | Jamais manquant dans small |
