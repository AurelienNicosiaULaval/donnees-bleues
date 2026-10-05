# Le flux est écrit après le rendu : les HTML embarqués de Quarto 1.9.38
# ne distribuent pas le fichier RSS natif associé aux listings.
library(yaml)
library(xml2)

news_metadata <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  borders <- which(trimws(lines) == "---")
  stopifnot(length(borders) >= 2L, borders[1] == 1L)
  metadata <- yaml.load(paste(lines[2:(borders[2] - 1L)], collapse = "\n"))
  metadata$path <- sub("[.]qmd$", ".html", path)
  stopifnot(nzchar(metadata$title), nzchar(metadata$description),
            length(metadata$date) == 1L, !is.na(as.Date(metadata$date)))
  metadata
}

news_rss_date <- function(date) {
  date <- as.Date(date)
  days <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  months <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  sprintf("%s, %02d %s %s 00:00:00 GMT",
          days[as.POSIXlt(date)$wday + 1L], as.integer(format(date, "%d")),
          months[as.integer(format(date, "%m"))], format(date, "%Y"))
}

news_base_url <- read_yaml("_quarto.yml")$website[["site-url"]]
news_posts <- lapply(list.files("resources", pattern = "^billet-.*[.]qmd$", full.names = TRUE), news_metadata)
news_posts <- Filter(function(post) !isTRUE(post$draft), news_posts)
stopifnot(length(news_posts) > 0L)
news_posts <- news_posts[order(vapply(news_posts, function(post) as.character(post$date), character(1)), decreasing = TRUE)]
news_feed <- xml_new_root("rss", version = "2.0")
news_channel <- xml_add_child(news_feed, "channel")
xml_add_child(news_channel, "title", "Actualités de Données bleues")
xml_add_child(news_channel, "link", url_absolute("actualites.html", news_base_url))
xml_add_child(news_channel, "description", "Jeux de données, pistes pédagogiques, publications et annonces de Données bleues.")
xml_add_child(news_channel, "language", "fr-ca")
for (post in news_posts) {
  stopifnot(file.exists(file.path("docs", post$path)))
  item <- xml_add_child(news_channel, "item")
  link <- url_absolute(post$path, news_base_url)
  xml_add_child(item, "title", post$title)
  xml_add_child(item, "link", link)
  xml_add_child(item, "guid", link, isPermaLink = "true")
  xml_add_child(item, "description", post$description)
  xml_add_child(item, "pubDate", news_rss_date(post$date))
  for (category in post$categories) xml_add_child(item, "category", category)
}
write_xml(news_feed, "docs/actualites.xml")
message(length(news_posts), " billet(s) dans le flux RSS.")
