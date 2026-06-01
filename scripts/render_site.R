status <- system2("quarto", c("render"), stdout = TRUE, stderr = TRUE)
cat(paste(status, collapse = "\n"), "\n")

exit_code <- attr(status, "status")
if (!is.null(exit_code) && exit_code != 0) {
  stop("Le rendu Quarto a échoué.", call. = FALSE)
}

