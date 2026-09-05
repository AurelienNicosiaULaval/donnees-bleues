# Prevent local data and build outputs from re-entering the source repository.
files <- system2('git', c('ls-files', '--cached'), stdout = TRUE)
if (!is.null(attr(files, 'status'))) stop('Impossible de vérifier les fichiers suivis par Git.')
forbidden <- grepl('^(docs/|data/(raw|processed|private|validation)/|[.]private/|[.]codex/|output/)', files)
forbidden <- forbidden & !grepl('/[.]gitkeep$', files)
if (any(forbidden)) stop('Fichiers de travail suivis par Git : ', paste(files[forbidden], collapse = ', '), call. = FALSE)
cat('Le dépôt source ne contient ni données de travail ni artefact HTML généré.\n')
