# Directives du dépôt Données bleues

Lire le guide de contribution dans `README.md` et la charte `charte-editoriale.qmd` avant de modifier une ressource.

## Vignette obligatoire pour chaque nouveau jeu de données

Chaque ajout au catalogue doit être accompagné d’une illustration créée avec un outil de génération d’images. Cette règle s’applique aussi aux jeux dont les données sont hébergées dans un dépôt externe. L’illustration doit être intégrée et vérifiée avant la publication.

- Regarder plusieurs illustrations existantes dans `assets/illustrations/datasets/` avant de générer la nouvelle image. Conserver leur style éditorial peint, leur texture de papier et leur palette bleu, turquoise et ivoire.
- Générer une scène qui évoque le sujet du jeu. Ne pas utiliser un graphique calculé, une photographie, une capture d’écran ou un assemblage d’icônes comme vignette d’un nouveau jeu. Les graphiques d’analyse peuvent figurer dans la fiche ou les activités.
- Prévoir une composition horizontale 16:9, lisible en petit format, sans texte, chiffres, logo, filigrane ni résultat statistique inventé. L’illustration ne constitue pas une observation réelle ou un document de la source.
- Enregistrer la version destinée au site dans `assets/illustrations/datasets/<id>.webp`, au format 960 × 540 pixels, sans recadrage, avec la qualité de compression utilisée par `scripts/prepare_dataset_illustrations.R`. Conserver l’original généré.
- Ajouter l’entrée dans `manifest.json` et la date, l’outil et le prompt exact dans `provenance.json`, dans ce même dossier. Compléter `credits-images.qmd` sans supprimer les déclarations existantes.
- Vérifier la sélection de l’illustration avec `tests/test-card-images.R`, puis inspecter son rendu dans le catalogue et à l’accueil lorsqu’elle y apparaît, y compris sur une fenêtre étroite. Après une publication autorisée, vérifier le déploiement terminé et l’image servie sur le site public.

Les anciens fichiers photographiques ou graphiques conservés dans `assets/cards/` sont des archives et des solutions de repli historiques. Leur présence ne permet pas de contourner la règle pour un nouveau jeu.
