# Dossier de préparation pour le Bulletin AMQ

Ce dossier accompagne l'article « Données bleues : enseigner avec le Québec » et la version 0.1.0 de la plateforme.

## Fichiers de soumission

- `article-amq-auteur.tex` et `article-amq-auteur.pdf` : version avec identité et coordonnées;
- `article-amq-anonyme.tex` et `article-amq-anonyme.pdf` : version sans identité ni coordonnées;
- `article-corps.tex` : corps commun aux deux versions;
- `preambule-amq.tex` : préambule effectif repris du gabarit officiel;
- `gabarit-original/GabaritAMQ101.tex` : copie intacte du gabarit téléchargé;
- `figures/` : source reproductible et fichiers PDF et JPG de la figure;
- `sources-verifiees.md` : provenance et contrôle des références;
- `frontiere-amq-ritpu.md` : délimitation éditoriale;
- `rapport-preparation.md` : contrôles techniques et éditoriaux;
- `courriel-soumission-brouillon.md` : brouillon non envoyé;
- `SHA256SUMS` : sommes de contrôle des principaux fichiers livrés.

## Compilation

Depuis ce dossier, avec une installation TeX Live complète :

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error article-amq-auteur.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error article-amq-anonyme.tex
```

La bibliographie est écrite manuellement dans `article-corps.tex`. Aucun fichier BibTeX n'est utilisé.

## Statut

Le dossier est préparé et compilé. La version 0.1.0 de Données bleues est publiée en ligne. L'article n'a pas été soumis à l'AMQ et le brouillon de courriel n'a pas été envoyé.
