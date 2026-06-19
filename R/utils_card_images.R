`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

card_image_extensions <- function() {
  c("jpg", "png", "svg")
}

card_image_path <- function(id, cards_dir = "assets/cards") {
  candidates <- file.path(cards_dir, paste0(id, ".", card_image_extensions()))
  existing <- candidates[file.exists(candidates)]

  if (length(existing) == 0L) {
    return(NA_character_)
  }

  existing[[1]]
}

xml_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

wrap_card_text <- function(text, width = 34L, max_lines = 3L) {
  wrapped <- strwrap(as.character(text), width = width)
  wrapped <- wrapped[seq_len(min(length(wrapped), max_lines))]

  if (length(wrapped) == 0L) {
    wrapped <- ""
  }

  wrapped
}

card_palette <- function(id) {
  palettes <- list(
    c("#325EA8", "#4F7CC9", "#B7D8FF"),
    c("#1B6B5A", "#5CA88A", "#D9F2E8"),
    c("#7A4E9E", "#C07CCF", "#F0D7F7"),
    c("#8A4F2A", "#D08A4E", "#FFE3C2"),
    c("#34495E", "#5DADE2", "#EAF4FF")
  )

  index <- (sum(utf8ToInt(id)) %% length(palettes)) + 1L
  palettes[[index]]
}

write_fallback_card_image <- function(metadata, cards_dir = "assets/cards") {
  id <- metadata$id
  title <- metadata$title %||% id
  theme <- metadata$theme %||% "Jeu de donnees"
  source_name <- metadata$source_name %||% "Source documentee"
  output_file <- file.path(cards_dir, paste0(id, ".svg"))

  dir.create(cards_dir, recursive = TRUE, showWarnings = FALSE)

  palette <- card_palette(id)
  title_lines <- wrap_card_text(title, width = 32L, max_lines = 3L)
  source_lines <- wrap_card_text(source_name, width = 54L, max_lines = 2L)

  title_svg <- paste0(
    sprintf(
      '<text x="78" y="%d" class="title">%s</text>',
      250 + seq_along(title_lines) * 58,
      xml_escape(title_lines)
    ),
    collapse = "\n"
  )

  source_svg <- paste0(
    sprintf(
      '<text x="80" y="%d" class="source">%s</text>',
      546 + seq_along(source_lines) * 34,
      xml_escape(source_lines)
    ),
    collapse = "\n"
  )

  svg <- c(
    '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="675" viewBox="0 0 1200 675" role="img">',
    paste0("<title>", xml_escape(title), "</title>"),
    paste0("<desc>Carte automatique Donnees bleues pour le theme ", xml_escape(theme), ".</desc>"),
    "<defs>",
    paste0(
      '<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">',
      '<stop offset="0" stop-color="', palette[[1]], '"/>',
      '<stop offset="0.55" stop-color="', palette[[2]], '"/>',
      '<stop offset="1" stop-color="', palette[[3]], '"/>',
      "</linearGradient>"
    ),
    "</defs>",
    '<rect width="1200" height="675" fill="url(#bg)"/>',
    '<g opacity="0.18" stroke="#ffffff" stroke-width="2">',
    '<path d="M0 515 C170 440 265 520 410 456 S686 310 872 376 1045 508 1200 436" fill="none"/>',
    '<path d="M0 575 C175 500 285 585 428 512 S670 398 835 452 1015 598 1200 520" fill="none"/>',
    "</g>",
    '<g opacity="0.26" fill="#ffffff">',
    '<circle cx="880" cy="164" r="16"/>',
    '<circle cx="940" cy="228" r="16"/>',
    '<circle cx="1008" cy="188" r="16"/>',
    '<circle cx="1058" cy="282" r="16"/>',
    '<circle cx="1126" cy="240" r="16"/>',
    '<path d="M880 164 L940 228 L1008 188 L1058 282 L1126 240" stroke="#ffffff" stroke-width="10" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    "</g>",
    '<rect x="64" y="64" width="1072" height="547" rx="28" fill="#101827" opacity="0.24"/>',
    '<text x="80" y="130" class="eyebrow">DONNEES BLEUES</text>',
    paste0('<text x="80" y="198" class="theme">', xml_escape(theme), "</text>"),
    title_svg,
    source_svg,
    '<style>',
    "text { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; fill: #ffffff; }",
    ".eyebrow { font-size: 28px; font-weight: 700; letter-spacing: 3px; opacity: 0.78; }",
    ".theme { font-size: 40px; font-weight: 650; opacity: 0.92; }",
    ".title { font-size: 52px; font-weight: 750; }",
    ".source { font-size: 24px; opacity: 0.82; }",
    "</style>",
    "</svg>"
  )

  writeLines(svg, output_file, useBytes = TRUE)
  output_file
}

ensure_card_images <- function(catalogue, cards_dir = "assets/cards") {
  if (!is.data.frame(catalogue) || nrow(catalogue) == 0L) {
    return(character())
  }

  created <- character()

  for (i in seq_len(nrow(catalogue))) {
    row <- as.list(catalogue[i, , drop = FALSE])
    id <- row$id

    if (is.na(card_image_path(id, cards_dir))) {
      created <- c(created, write_fallback_card_image(row, cards_dir))
    }
  }

  if (length(created) > 0L) {
    message("Images de cartes automatiques : ", paste(created, collapse = ", "))
  }

  invisible(created)
}
