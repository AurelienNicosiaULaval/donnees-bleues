// Contrôle du moteur WebAssembly via son API Node, sans navigateur.
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";

const destination = path.resolve(process.argv[2] ?? "docs/outils/maisons-quebec");
const engine = path.join(destination, "shinylive/webr");
const { WebR } = await import(pathToFileURL(path.join(engine, "webr.mjs")));
const webR = new WebR({ baseUrl: engine + "/" });
try {
  await webR.init();
  await webR.FS.mkdir("/published");
  await webR.FS.mount("NODEFS", { root: destination }, "/published");
  await webR.evalRVoid('webr::mount("/shinylive/library", ' +
    JSON.stringify(path.join(engine, "library.data.gz")) + ')');
  await webR.evalRVoid(`
    lib <- "/home/web_user/library"
    dir.create(lib, showWarnings = FALSE)
    packages <- list.files("/published/shinylive/webr/packages",
      pattern = "[.]tgz$", recursive = TRUE, full.names = TRUE)
    for (package in packages) utils::untar(package, exdir = lib, tar = "internal")
    .libPaths(c(lib, "/shinylive/library", .libPaths()))
    dir.create("/home/web_user/app", showWarnings = FALSE)
    setwd("/home/web_user/app")
  `);
  const app = JSON.parse(fs.readFileSync(path.join(destination, "app.json"), "utf8"));
  for (const file of app) {
    const target = "/home/web_user/app/" + file.name;
    const directory = JSON.stringify(path.posix.dirname(target));
    await webR.evalRVoid("dir.create(" + directory +
      ", recursive = TRUE, showWarnings = FALSE)");
    await webR.FS.writeFile(target,
      Buffer.from(file.content, file.type === "binary" ? "base64" : "utf8"));
  }
  await webR.evalRVoid(`
    source("app.R", encoding = "UTF-8")
    stopifnot(nrow(houses) == 600L,
      house_summary(houses)$value == 366000,
      house_summary(houses)$area == 107.65)
    for (graph in c("scatter", "histogram", "boxplot")) {
      for (log_axes in c(FALSE, TRUE)) {
        settings <- explorer_settings(types = c("Détaché", "Jumelé"),
          years = c(1950, 2000), graph = graph, log_axes = log_axes, bins = 17L)
        selected <- filter_houses(houses, settings)
        stopifnot(nrow(selected) == 403L)
        built <- ggplot_build(make_house_plot(selected, settings))
        stopifnot(length(built$data) >= 1L, nrow(built$data[[1]]) > 0L)
        code <- export_house_code(settings)
        stopifnot(length(parse(text = code)) > 1L)
      }
    }
    stopifnot(nrow(filter_houses(houses, explorer_settings(types = "Jumelé"))) == 94L)
    stopifnot(nrow(filter_houses(houses, explorer_settings(types = character()))) == 0L)
  `);
  assert.equal(await webR.evalRNumber("nrow(houses)"), 600);
  console.log(await webR.evalRString("R.version.string"));
  console.log("WebAssembly : chargement de l’application, données, filtres et six graphiques OK.");
} finally {
  await webR.close();
}
