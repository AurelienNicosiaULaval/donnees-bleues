// Contrôle du moteur WebAssembly via son API Node, sans navigateur.
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";

const destination = path.resolve(process.argv[2] ?? "docs/outils/ggplot-builder");
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
    stopifnot(nrow(trees) == 200L, sum(is.na(trees$age_years)) == 52L)
    for (mode in names(mode_labels)) {
      for (stage in 1:5) {
        settings <- default_config()
        settings$mode <- mode
        settings$stage <- stage
        settings$facet <- TRUE
        settings$smooth <- TRUE
        view <- build_view(settings, trees)
        stopifnot(nrow(view$data) == 200L, length(ggplot_build(view$plot)$data) >= 1L)
        stopifnot(length(parse(text = export_script(settings))) > 1L)
      }
    }
    settings <- default_config()
    settings$y <- "age_ans"
    view <- build_view(settings, trees)
    stopifnot(nrow(view$data) == 148L, view$excluded == 52L,
              !any(view$data$espece == "Érable rouge"))
    settings$species <- character()
    stopifnot(nrow(build_view(settings, trees)$data) == 0L)
  `);
  assert.equal(await webR.evalRNumber("nrow(trees)"), 200);
  console.log(await webR.evalRString("R.version.string"));
  console.log("WebAssembly : ggplot builder, données, 25 configurations et âges manquants OK.");
} finally {
  await webR.close();
}
