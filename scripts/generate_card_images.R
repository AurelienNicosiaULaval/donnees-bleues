# Generate local dataset card thumbnails for the Donnees bleues catalogue.
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
  ),
  list(
    id = "pyramides-ages",
    label = "Pyramides des âges",
    commons_file = "People dancing in the street of Montreal city in Canada 02.jpg",
    source_title = "People dancing in the street of Montreal city in Canada 02.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:People_dancing_in_the_street_of_Montreal_city_in_Canada_02.jpg",
    author = "Wilfredor",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    gravity = "center"
  ),
  list(
    id = "niveaux-eau-inondation",
    label = "Niveaux d'eau lors d'une inondation",
    commons_file = "2017 Quebec Floods - Montreal (34504962346).jpg",
    source_title = "2017 Quebec Floods - Montreal (34504962346).jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:2017_Quebec_Floods_-_Montreal_(34504962346).jpg",
    author = "Exile on Ontario St",
    license = "CC BY-SA 2.0",
    license_url = "https://creativecommons.org/licenses/by-sa/2.0/",
    gravity = "center"
  ),
  list(
    id = "grhq",
    label = "Géobase du réseau hydrographique du Québec",
    commons_file = "Rivière Jacques-Cartier (Sainte-Catherine-de-la-Jacques-Cartier) - Vue aérienne 1.jpg",
    source_title = "Rivière Jacques-Cartier (Sainte-Catherine-de-la-Jacques-Cartier) - Vue aérienne 1.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Rivi%C3%A8re_Jacques-Cartier_(Sainte-Catherine-de-la-Jacques-Cartier)_-_Vue_a%C3%A9rienne_1.jpg",
    author = "Gabriel Picard",
    license = "CC BY-SA 4.0",
    license_url = "https://creativecommons.org/licenses/by-sa/4.0/",
    gravity = "center"
  ),
  list(
    id = "rapports-accident",
    label = "Rapports d'accident",
    commons_file = "Car Accident - Bellingham Police and Fire (17495152880).jpg",
    source_title = "Car Accident - Bellingham Police and Fire (17495152880).jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Car_Accident_-_Bellingham_Police_and_Fire_(17495152880).jpg",
    author = "Alex Smith",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    gravity = "center"
  ),
  list(
    id = "etablissements-enseignement",
    label = "Localisation des établissements d'enseignement au Québec",
    commons_file = "School bus in Quebec City.jpg",
    source_title = "School bus in Quebec City.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:School_bus_in_Quebec_City.jpg",
    author = "Wilfredor",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    gravity = "center"
  ),
  list(
    id = "requetes-311",
    label = "Demandes de services citoyennes 311 à Montréal",
    commons_file = "Hôtel de Ville de Montréal, juin 2024.jpg",
    source_title = "Hôtel de Ville de Montréal, juin 2024.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:H%C3%B4tel_de_Ville_de_Montr%C3%A9al,_juin_2024.jpg",
    author = "Pierre5018",
    license = "CC BY 4.0",
    license_url = "https://creativecommons.org/licenses/by/4.0/",
    gravity = "center"
  ),
  list(
    id = "arbres-publics-montreal",
    label = "Arbres publics sur le territoire de Montréal",
    commons_file = "Montreal, Canada 017.jpg",
    source_title = "Montreal, Canada 017.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Montreal,_Canada_017.jpg",
    author = "Wilfredor",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    gravity = "center"
  ),
  list(
    id = "actes-criminels-montreal",
    label = "Actes criminels à Montréal",
    commons_file = "Crime Scene Do Not Cross (6874134473).jpg",
    source_title = "Crime Scene Do Not Cross (6874134473).jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Crime_Scene_Do_Not_Cross_(6874134473).jpg",
    author = "Hubert Figuière",
    license = "CC BY-SA 2.0",
    license_url = "https://creativecommons.org/licenses/by-sa/2.0/",
    gravity = "center"
  ),
  list(
    id = "qualite-air-horaire",
    label = "Qualité de l'air au Québec",
    commons_file = "Smog Montréal.jpg",
    source_title = "Smog Montréal.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Smog_Montr%C3%A9al.jpg",
    author = "DubyDub2009",
    license = "CC BY 2.0",
    license_url = "https://creativecommons.org/licenses/by/2.0/",
    gravity = "center"
  ),
  list(
    id = "budgets-municipaux-quebec",
    label = "Budgets municipaux du Québec",
    commons_file = "Hôtel de Ville de Montréal, juin 2024.jpg",
    source_title = "Hôtel de Ville de Montréal, juin 2024.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:H%C3%B4tel_de_Ville_de_Montr%C3%A9al,_juin_2024.jpg",
    author = "Pierre5018",
    license = "CC BY 4.0",
    license_url = "https://creativecommons.org/licenses/by/4.0/",
    gravity = "center"
  ),
  list(
    id = "ecoles-quebec",
    label = "Établissements scolaires du Québec",
    commons_file = "School bus in Quebec City.jpg",
    source_title = "School bus in Quebec City.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:School_bus_in_Quebec_City.jpg",
    author = "Wilfredor",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    gravity = "center"
  ),
  list(
    id = "transport-collectif-gtfs",
    label = "Réseaux de transport collectif GTFS au Québec",
    commons_file = "RTC Bus Québec City 14788128682.jpg",
    source_title = "RTC Bus Québec City 14788128682.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:RTC_Bus_Qu%C3%A9bec_City_14788128682.jpg",
    author = "Tony Webster",
    license = "CC BY-SA 4.0",
    license_url = "https://creativecommons.org/licenses/by-sa/4.0/",
    gravity = "center"
  ),
  list(
    id = "retards-transport-collectif",
    label = "Flux temps réel STM et ponctualité des bus",
    commons_file = "STM Bus back on line 114.jpg",
    source_title = "STM Bus back on line 114.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:STM_Bus_back_on_line_114.jpg",
    author = "JustYou80",
    license = "CC BY 4.0",
    license_url = "https://creativecommons.org/licenses/by/4.0/",
    gravity = "center"
  ),
  list(
    id = "emploi-regional-quebec",
    label = "Emploi régional au Québec",
    commons_file = "News. Men at Work Bleury and St. Catherine.jpg",
    source_title = "News. Men at Work Bleury and St. Catherine.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:News._Men_at_Work_Bleury_and_St._Catherine.jpg",
    author = "Conrad Poirier",
    license = "Domaine public",
    license_url = NA_character_,
    gravity = "center"
  ),
  list(
    id = "ulaval-programmes-cours",
    label = "Programmes et cours institutionnels ULaval",
    commons_file = "ULaval campus.jpg",
    source_title = "ULaval campus.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:ULaval_campus.jpg",
    author = "René Bélanger",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    gravity = "center"
  ),
  list(
    id = "meteo-quebec",
    label = "Météo quotidienne à Québec",
    commons_file = "YQB terminal interior.jpg",
    source_title = "YQB terminal interior.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:YQB_terminal_interior.jpg",
    author = "Quintin Soloviev",
    license = "CC BY 4.0",
    license_url = "https://creativecommons.org/licenses/by/4.0/",
    gravity = "center"
  ),
  list(
    id = "condamnations-alimentaires-quebec",
    label = "Condamnations des établissements alimentaires au Québec",
    commons_file = "Food at WIkimanian 2017 02.jpg",
    source_title = "Food at WIkimanian 2017 02.jpg",
    source_page = "https://commons.wikimedia.org/wiki/File:Food_at_WIkimanian_2017_02.jpg",
    author = "Camelia.boban",
    license = "CC BY-SA 4.0",
    license_url = "https://creativecommons.org/licenses/by-sa/4.0/",
    gravity = "center"
  ),
  list(
    id = "defavorisation-ecoles-primaires",
    label = "Indices de défavorisation des écoles primaires du Québec",
    commons_file = "École primaire Courval - Neuville.JPG",
    source_title = "École primaire Courval - Neuville.JPG",
    source_page = "https://commons.wikimedia.org/wiki/File:%C3%89cole_primaire_Courval_-_Neuville.JPG",
    author = "Sylvainbrousseau",
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
      license <- escape_markdown_table(card$license)
      license_cell <- if (is.null(card$license_url) || is.na(card$license_url) || !nzchar(card$license_url)) {
        license
      } else {
        sprintf("[%s](%s)", license, card$license_url)
      }

      sprintf(
        "| %s | [%s](%s) | %s | %s |",
        escape_markdown_table(card$label),
        escape_markdown_table(card$source_title),
        card$source_page,
        escape_markdown_table(card$author),
        license_cell
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
    "Les vignettes des jeux de données sont des versions recadrées et recompressées en 16:9 de fichiers publiés sur Wikimedia Commons.",
    "",
    "| Carte | Image source | Auteur ou organisme | Licence |",
    "|---|---|---|---|",
    rows
  )

  writeLines(page, "credits-images.qmd", useBytes = TRUE)
}

selected_ids <- commandArgs(trailingOnly = TRUE)

if (length(selected_ids) > 0L) {
  known_ids <- vapply(cards, `[[`, character(1), "id")
  unknown_ids <- setdiff(selected_ids, known_ids)

  if (length(unknown_ids) > 0L) {
    stop(
      "Unknown card id(s): ",
      paste(unknown_ids, collapse = ", "),
      call. = FALSE
    )
  }

  cards_to_write <- cards[known_ids %in% selected_ids]
} else {
  cards_to_write <- cards
}

invisible(lapply(cards_to_write, write_card_image))
write_credits_page(cards)
