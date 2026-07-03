card_image_extensions <- function() {
  c("webp", "jpg", "jpeg", "png")
}

card_image_path <- function(id, cards_dir = "assets/cards") {
  candidates <- file.path(cards_dir, paste0(id, ".", card_image_extensions()))
  existing <- candidates[file.exists(candidates)]

  if (length(existing) == 0L) {
    return(NA_character_)
  }

  existing[[1]]
}

validate_card_images <- function(catalogue, cards_dir = "assets/cards") {
  if (!is.data.frame(catalogue) || nrow(catalogue) == 0L) {
    return(invisible(character()))
  }

  missing <- vapply(
    catalogue$id,
    function(id) is.na(card_image_path(id, cards_dir)),
    logical(1)
  )

  if (any(missing)) {
    stop(
      "Image de carte manquante pour : ",
      paste(catalogue$id[missing], collapse = ", "),
      ". Ajouter une image dans assets/cards/ avant de rendre le site.",
      call. = FALSE
    )
  }

  invisible(catalogue$id)
}
