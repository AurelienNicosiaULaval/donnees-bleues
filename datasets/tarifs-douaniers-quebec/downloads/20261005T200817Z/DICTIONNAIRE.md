# Dictionnaire

Les CSV sont en UTF-8; NA désigne une information absente, jamais un zéro. Les codes douaniers, vecteurs, coordonnées et identifiants doivent être importés comme du texte.

| Table | Grain, clé et lecture |
|---|---|
| observations_contre_tarifs | Une ligne de tableau récapitulatif dans une capture. Clé collection_id, source_table, code_tarifaire. 2774 lignes, pas 2774 produits distincts. |
| contre_tarifs_20260908 | Panneau du 8 septembre 2026, extrait de la table précédente. 648 codes uniques. Ne pas l'ajouter aux autres panneaux. |
| annexes_2026 | Une ligne d'annexe de DORS/2026-186. 335 codes uniques, annexes 1 à 3. Ce n'est pas l'intégralité des 648 lignes récapitulatives. |
| prix_moyens_quebec | Un produit, conditionnement et mois. Clé mois, vecteur pour cette capture. prix_cad : dollars canadiens par conditionnement indiqué. 110 produits; 115 mois. |
| commerce_quebec | Un mois, sens du commerce, catégorie SCPAN et partenaire. Clé mois, vecteur. valeur_milliers_cad : milliers de dollars courants, non désaisonnalisés, base douanière. |
| sources | Un identifiant documentaire source_id. État d'intégration explicite, y compris les sources uniquement repérées. |
| captures_sources | Une acquisition réussie de document. Heure UTC et empreinte du fichier capturé. Les fichiers bruts ne sont pas tous redistribués. |
| actualite | Un article sélectionné, article_id. Date affichée et date de mise à jour distinctes. Titre reformulé, vérification éditoriale non quantitative. |
| evenements | Un événement documenté, evenement_id. nature distingue annonce, surtaxe, retrait et interdiction. date_annonce manquante signifie non renseignée. |
| couverture | Un volet et son état d'intégration, sans prétention à l'exhaustivité. |
| controles_qualite | Un contrôle exécuté et son résultat. Les contrôles portent sur l'extraction et les rapprochements, pas sur la facture douanière d'une entreprise. |

## Champs des contre-tarifs

code_tarifaire conserve huit chiffres canadiens; code_sh6 est leur préfixe à six chiffres. description_source n'est pas un identifiant de produit vendu au détail. taux_surtaxe_pourcent décrit la surtaxe indiquée avant exemptions et remises. Les périodes des panneaux ne sont pas des dates d'effet automatiquement valables pour chaque ligne. date_application_initiale_source est renseignée quand la source la donne. statut_validation explicite les conditions non résolues.

## Champs de Statistique Canada

Les noms de colonnes des deux tableaux ont été normalisés; les valeurs, vecteurs, coordonnées, unités, facteurs scalaires et indicateurs statut_source, symbole_source, termine_source et decimales_source sont conservés. Un indicateur de statut vide est codé NA. Les produits de prix gardent leur libellé et conditionnement source. Les prix moyens ne sont pas un indice de prix à panier constant; un changement de couverture survient en janvier 2024.

Les 13 catégories du commerce comprennent le total et 12 catégories; les 29 partenaires comprennent des pays et des groupes. Ne pas additionner toutes les lignes. La série distingue Importations et Exportations nationales; elle ne fournit pas ici les réexportations. Les importations peuvent être révisées et le dédouanement au Québec ne prouve pas la consommation finale au Québec.

## Absence et interprétation

Aucune ligne absente n'est imputée à un taux nul. Aucune concordance entre les libellés de prix, les catégories SCPAN et les codes SH n'est inventée. Une interdiction d'importation n'est pas codée comme un tarif de 100 %. Les graphiques sont descriptifs.
