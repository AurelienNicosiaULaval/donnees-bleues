# Generate local card thumbnails for the Données bleues gallery.

dir.create("assets/cards", recursive = TRUE, showWarnings = FALSE)

palette <- list(
  blue = "#003DA5",
  blue_mid = "#2F75D6",
  blue_soft = "#E8F1FF",
  ink = "#172033",
  muted = "#5D6B82",
  water = "#00A6D6",
  green = "#2E8B57",
  mint = "#B7E4D8",
  yellow = "#F6C85F",
  coral = "#E46F61",
  violet = "#7E57C2",
  paper = "#FFFFFF"
)

start_card <- function(path, background = c("#E8F1FF", "#FFFFFF")) {
  png(path, width = 1200, height = 675, res = 144, type = "cairo")
  par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i", family = "sans")
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1))
  rect(0, 0, 1, 1, col = background[1], border = NA)
  rect(0, 0, 1, 0.48, col = background[2], border = NA)
}

finish_card <- function() {
  dev.off()
}

circle <- function(x, y, r, col, border = NA, lwd = 1) {
  symbols(x, y, circles = r, inches = FALSE, add = TRUE, bg = col, fg = border, lwd = lwd)
}

line_path <- function(x, y, col = palette$blue, lwd = 8) {
  lines(x, y, col = col, lwd = lwd, lend = "round", ljoin = "round")
}

card_catalogue <- function() {
  start_card("assets/cards/catalogue.png", c("#E8F1FF", "#F8FBFF"))
  for (i in 0:2) {
    for (j in 0:1) {
      x <- 0.16 + i * 0.19
      y <- 0.28 + j * 0.26
      rect(x, y, x + 0.14, y + 0.16, col = palette$paper, border = "#C9D8EA", lwd = 3)
      rect(x + 0.025, y + 0.1, x + 0.115, y + 0.12, col = palette$blue_mid, border = NA)
      rect(x + 0.025, y + 0.065, x + 0.095, y + 0.08, col = palette$mint, border = NA)
      circle(x + 0.04, y + 0.04, 0.015, palette$yellow)
    }
  }
  circle(0.74, 0.52, 0.12, NA, palette$blue, 8)
  line_path(c(0.82, 0.91), c(0.42, 0.31), palette$blue, 10)
  circle(0.74, 0.52, 0.035, palette$water)
  finish_card()
}

card_zero_dechet <- function() {
  start_card("assets/cards/zero-dechet.png", c("#E9F7F2", "#FFFFFF"))
  theta <- seq(0.25, 5.45, length.out = 170)
  x <- 0.5 + 0.23 * cos(theta)
  y <- 0.52 + 0.23 * sin(theta)
  line_path(x, y, palette$green, 10)
  arrows(0.66, 0.72, 0.71, 0.67, col = palette$green, lwd = 5, length = 0.11)
  arrows(0.34, 0.31, 0.29, 0.36, col = palette$green, lwd = 5, length = 0.11)
  rect(0.39, 0.4, 0.61, 0.62, col = palette$paper, border = "#C9D8EA", lwd = 3)
  segments(seq(0.43, 0.57, length.out = 4), 0.43, seq(0.43, 0.57, length.out = 4), 0.59, col = "#D8E2F0", lwd = 2)
  segments(0.42, seq(0.46, 0.56, length.out = 3), 0.58, seq(0.46, 0.56, length.out = 3), col = "#D8E2F0", lwd = 2)
  points(c(0.45, 0.5, 0.55), c(0.48, 0.56, 0.51), pch = 19, cex = 1.8, col = c(palette$blue, palette$water, palette$yellow))
  finish_card()
}

card_activites <- function() {
  start_card("assets/cards/activites.png", c("#FFF6E0", "#FFFFFF"))
  rect(0.18, 0.2, 0.62, 0.72, col = palette$paper, border = "#D6C08B", lwd = 4)
  rect(0.23, 0.56, 0.57, 0.61, col = palette$blue_mid, border = NA)
  rect(0.23, 0.46, 0.48, 0.5, col = palette$mint, border = NA)
  rect(0.23, 0.36, 0.53, 0.4, col = palette$yellow, border = NA)
  segments(c(0.72, 0.82), c(0.22, 0.58), c(0.82, 0.9), c(0.58, 0.5), col = palette$coral, lwd = 16, lend = "round")
  polygon(c(0.9, 0.95, 0.87), c(0.5, 0.46, 0.43), col = palette$ink, border = NA)
  circle(0.73, 0.22, 0.035, palette$yellow, "#D6A62C", 2)
  finish_card()
}

card_bixi <- function() {
  start_card("assets/cards/bixi.png", c("#E8F1FF", "#FFFFFF"))
  circle(0.3, 0.35, 0.12, NA, palette$blue, 6)
  circle(0.68, 0.35, 0.12, NA, palette$blue, 6)
  line_path(c(0.3, 0.45, 0.57, 0.68, 0.52, 0.45, 0.3), c(0.35, 0.55, 0.35, 0.35, 0.35, 0.55, 0.35), palette$blue_mid, 7)
  segments(0.57, 0.35, 0.63, 0.55, col = palette$blue_mid, lwd = 7, lend = "round")
  segments(0.62, 0.55, 0.71, 0.58, col = palette$blue_mid, lwd = 7, lend = "round")
  rect(0.16, 0.67, 0.84, 0.74, col = palette$mint, border = NA)
  points(seq(0.22, 0.78, length.out = 8), rep(0.705, 8), pch = 19, cex = 1.4, col = palette$green)
  finish_card()
}

card_bibliotheques <- function() {
  start_card("assets/cards/bibliotheques-quebec.png", c("#F2EDFF", "#FFFFFF"))
  rect(0.18, 0.23, 0.82, 0.32, col = "#A887D8", border = NA)
  rect(0.18, 0.48, 0.82, 0.57, col = "#A887D8", border = NA)
  cols <- c(palette$blue, palette$water, palette$yellow, palette$coral, palette$green, palette$violet)
  xs <- seq(0.22, 0.74, length.out = 9)
  for (i in seq_along(xs)) {
    rect(xs[i], 0.32, xs[i] + 0.035, 0.56, col = cols[(i - 1) %% length(cols) + 1], border = NA)
    rect(xs[i] + 0.005, 0.36, xs[i] + 0.03, 0.39, col = palette$paper, border = NA)
  }
  rect(0.28, 0.57, 0.38, 0.74, col = palette$paper, border = palette$blue, lwd = 3)
  rect(0.39, 0.57, 0.49, 0.74, col = palette$paper, border = palette$blue, lwd = 3)
  finish_card()
}

card_qualite_air <- function() {
  start_card("assets/cards/qualite-air.png", c("#E9F7F2", "#FFFFFF"))
  rect(0.42, 0.22, 0.48, 0.62, col = palette$blue, border = NA)
  rect(0.36, 0.62, 0.54, 0.68, col = palette$blue_mid, border = NA)
  segments(c(0.44, 0.46), c(0.22, 0.22), c(0.36, 0.18), col = palette$blue, lwd = 5)
  segments(c(0.44, 0.46), c(0.22, 0.22), c(0.54, 0.18), col = palette$blue, lwd = 5)
  wave_x <- seq(0.14, 0.86, length.out = 200)
  for (base_y in c(0.42, 0.54, 0.7)) {
    line_path(wave_x, base_y + 0.025 * sin(18 * wave_x), adjustcolor(palette$water, 0.75), 5)
  }
  points(c(0.22, 0.72, 0.78), c(0.34, 0.5, 0.66), pch = 19, cex = c(1.8, 1.3, 2.1), col = c(palette$green, palette$yellow, palette$coral))
  finish_card()
}

card_suivi_rivieres <- function() {
  start_card("assets/cards/suivi-rivieres-fleuve.png", c("#E8F7FF", "#FFFFFF"))
  river_x <- seq(0.02, 0.98, length.out = 200)
  river_y <- 0.42 + 0.11 * sin(2.6 * pi * river_x)
  polygon(c(river_x, rev(river_x)), c(river_y + 0.08, rev(river_y - 0.08)), col = palette$water, border = NA)
  line_path(river_x, river_y, "#D7F3FF", 5)
  points(c(0.25, 0.5, 0.73), c(0.61, 0.42, 0.31), pch = 21, bg = palette$yellow, col = palette$blue, lwd = 3, cex = 2)
  line_path(c(0.18, 0.34, 0.5, 0.66, 0.82), c(0.17, 0.24, 0.21, 0.33, 0.46), palette$green, 5)
  finish_card()
}

card_prelevements <- function() {
  start_card("assets/cards/prelevements-eau-autorises.png", c("#E8F1FF", "#FFFFFF"))
  polygon(c(0.5, 0.37, 0.42, 0.58, 0.63), c(0.78, 0.48, 0.27, 0.27, 0.48), col = palette$water, border = NA)
  circle(0.5, 0.39, 0.12, palette$water)
  rect(0.15, 0.22, 0.3, 0.46, col = palette$ink, border = NA)
  rect(0.18, 0.46, 0.23, 0.62, col = palette$coral, border = NA)
  rect(0.27, 0.46, 0.32, 0.56, col = palette$yellow, border = NA)
  rect(0.68, 0.22, 0.78, 0.42, col = palette$green, border = NA)
  rect(0.8, 0.22, 0.9, 0.58, col = palette$blue_mid, border = NA)
  finish_card()
}

card_diplomation <- function() {
  start_card("assets/cards/cohortes-diplomation.png", c("#FFF6E0", "#FFFFFF"))
  polygon(c(0.5, 0.22, 0.5, 0.78), c(0.72, 0.58, 0.44, 0.58), col = palette$blue, border = NA)
  rect(0.38, 0.38, 0.62, 0.48, col = palette$blue_mid, border = NA)
  segments(0.73, 0.57, 0.73, 0.36, col = palette$yellow, lwd = 6)
  circle(0.73, 0.34, 0.025, palette$yellow)
  line_path(c(0.2, 0.34, 0.5, 0.66, 0.82), c(0.2, 0.25, 0.31, 0.43, 0.56), palette$green, 6)
  points(c(0.2, 0.34, 0.5, 0.66, 0.82), c(0.2, 0.25, 0.31, 0.43, 0.56), pch = 19, cex = 1.6, col = palette$coral)
  finish_card()
}

card_catalogue()
card_zero_dechet()
card_activites()
card_bixi()
card_bibliotheques()
card_qualite_air()
card_suivi_rivieres()
card_prelevements()
card_diplomation()
