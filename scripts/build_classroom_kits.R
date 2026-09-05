source('R/utils_classroom.R')
paths <- sort(list.files('datasets', pattern = '^metadata[.]yml$', recursive = TRUE, full.names = TRUE))
for (path in paths) {
 metadata <- yaml::read_yaml(path)
 receipt <- build_classroom_kit(metadata)
 cat(metadata$id, ':', receipt$mode, '-', receipt$archive_bytes, 'octets\n')
}
