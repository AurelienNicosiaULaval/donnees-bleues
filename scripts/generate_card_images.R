# Generate local card thumbnails for the Donnees bleues gallery.
#
# The source images are Wikimedia Commons files with reusable licenses.
# This script crops them to a consistent 16:9 format and writes a public
# credits page because several sources require attribution.

required_packages <- c("curl", "magick")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

dir.create("assets/cards", recursive = TRUE, showWarnings = FALSE)

cards <- list(
  list(
    id = "catalogue",
    label = "Explorer les jeux de données",
    commons_file = "Library Of Congress Card Catalog.jpg",
    source_title = "Library Of Congress Card Catalog.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Library_Of_Congress_Card_Catalog.jpg",
    author = "rochelle hartman",
    license = "CC BY 2.0",
    license_url = "https://creativecommons.org/licenses/by/2.0/",
    gravity = "center"
  ),
  list(
    id = "zero-dechet",
    label = "Comprendre le jeu de données zéro déchet",
    commons_file = "Glass recycling bins.jpg",
    source_title = "Glass recycling bins.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Glass_recycling_bins.jpg",
    author = "Digitura",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    gravity = "center"
  ),
  list(
    id = "activites",
    label = "Utiliser les activités en classe",
    commons_file = "Students working on class assignment in computer lab.jpg",
    source_title = "Students working on class assignment in computer lab.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Students_working_on_class_assignment_in_computer_lab.jpg",
    author = "Michael Surran",
    license = "CC BY-SA 2.0",
    license_url = "https://creativecommons.org/licenses/by-sa/2.0/",
    gravity = "center"
  ),
  list(
    id = "bixi",
    label = "État des stations BIXI",
    commons_file = "Bixi bike sharing Montreal.jpg",
    source_title = "Bixi bike sharing Montreal.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Bixi_bike_sharing_Montreal.jpg",
    author = "JasonVogel",
    license = "CC BY-SA 4.0",
    license_url = "https://creativecommons.org/licenses/by-sa/4.0/",
    gravity = "center"
  ),
  list(
    id = "bibliotheques-quebec",
    label = "Bibliothèques publiques du Québec",
    commons_file = "Grande bibliotheque du Quebec-main hall.jpg",
    source_title = "Grande bibliotheque du Quebec-main hall.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Grande_bibliotheque_du_Quebec-main_hall.jpg",
    author = "Montrealais",
    license = "CC BY-SA 3.0",
    license_url = "https://creativecommons.org/licenses/by-sa/3.0/",
    gravity = "center"
  ),
  list(
    id = "qualite-air",
    label = "Stations de qualité de l'air",
    commons_file = "Smog Montréal.jpg",
    source_title = "Smog Montréal.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Smog_Montr%C3%A9al.jpg",
    author = "DubyDub2009",
    license = "CC BY 2.0",
    license_url = "https://creativecommons.org/licenses/by/2.0/",
    gravity = "center"
  ),
  list(
    id = "suivi-rivieres-fleuve",
    label = "Suivi des rivières et du fleuve",
    commons_file = "Le fleuve Saint-Laurent.jpg",
    source_title = "Le fleuve Saint-Laurent.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Le_fleuve_Saint-Laurent.jpg",
    author = "abdallahh",
    license = "CC BY 2.0",
    license_url = "https://creativecommons.org/licenses/by/2.0/",
    gravity = "center"
  ),
  list(
    id = "prelevements-eau-autorises",
    label = "Registre des prélèvements d'eau autorisés",
    commons_file = "The coagulation and filtration processes at a drinking water treatment plant. (14868618507).jpg",
    source_title = "The coagulation and filtration processes at a drinking water treatment plant. (14868618507).jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:The_coagulation_and_filtration_processes_at_a_drinking_water_treatment_plant._(14868618507).jpg",
    author = "United States Environmental Protection Agency",
    license = "Public domain, United States Government Work",
    license_url = "https://commons.wikimedia.org/wiki/Template:PD-USGov",
    gravity = "center"
  ),
  list(
    id = "cohortes-diplomation",
    label = "Cohortes de diplomation",
    commons_file = "Convocation week.jpg",
    source_title = "Convocation week.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Convocation_week.jpg",
    author = "Quan Nguyen",
    license = "CC BY-SA 3.0",
    license_url = "https://creativecommons.org/licenses/by-sa/3.0/",
    gravity = "center"
  )
)

download_commons_file <- function(file_name, destination) {
  source_url <- paste0(
    "https://commons.wikimedia.org/wiki/Special:Redirect/file/",
    utils::URLencode(file_name, reserved = TRUE)
  )

  handle <- curl::new_handle(
    useragent = "DonneesBleues/1.0 (educational website image thumbnail generation)"
  )

  curl::curl_download(
    url = source_url,
    destfile = destination,
    mode = "wb",
    quiet = TRUE,
    handle = handle
  )
}

write_card_image <- function(card) {
  source_file <- tempfile(fileext = ".jpg")
  output_file <- file.path("assets/cards", paste0(card$id, ".jpg"))

  download_ok <- tryCatch(
    {
      download_commons_file(card$commons_file, source_file)
      TRUE
    },
    error = function(error) {
      if (file.exists(output_file)) {
        warning(
          "Could not download ",
          card$commons_file,
          "; keeping existing ",
          output_file,
          ". Error: ",
          conditionMessage(error),
          call. = FALSE
        )
        return(FALSE)
      }

      stop(error)
    }
  )

  if (!download_ok) {
    return(invisible(FALSE))
  }

  image <- magick::image_read(source_file)
  image <- magick::image_orient(image)
  image <- magick::image_resize(image, "1200x675^")
  image <- magick::image_extent(image, "1200x675", gravity = card$gravity)
  image <- magick::image_modulate(image, brightness = 103, saturation = 104)
  image <- magick::image_enhance(image)
  image <- magick::image_strip(image)

  magick::image_write(image, path = output_file, format = "jpeg", quality = 86)
  message("Wrote ", output_file)
  invisible(TRUE)
}

escape_markdown_table <- function(x) {
  x <- gsub("\\n+", " ", x)
  x <- gsub("\\|", "\\\\|", x)
  x
}

write_credits_page <- function(cards) {
  rows <- vapply(
    cards,
    function(card) {
      sprintf(
        "| %s | [%s](%s) | %s | [%s](%s) |",
        escape_markdown_table(card$label),
        escape_markdown_table(card$source_title),
        card$source_page,
        escape_markdown_table(card$author),
        escape_markdown_table(card$license),
        card$license_url
      )
    },
    character(1)
  )

  page <- c(
    "---",
    'title: "Crédits images"',
    "embed-resources: true",
    "---",
    "",
    "# Crédits images",
    "",
    "Les vignettes de la galerie sont des versions recadrées et recompressées en 16:9 de fichiers publiés sur Wikimedia Commons.",
    "",
    "| Carte | Image source | Auteur ou organisme | Licence |",
    "|---|---|---|---|",
    rows,
    ""
  )

  writeLines(page, "credits-images.qmd", useBytes = TRUE)
}

invisible(lapply(cards, write_card_image))
write_credits_page(cards)
