# Optional installation. Run once if the required packages are absent.
packages <- c("shiny", "bslib", "ggplot2", "dplyr", "readr")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
cat("Packages disponibles :", paste(packages, collapse = ", "), "\n")
