// Exécuter le paquet exporté dans son moteur R WebAssembly.
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
const destination = path.resolve(process.argv[2] ?? "docs/outils/bootstrap-maisons");
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
    await webR.evalRVoid("dir.create(" + JSON.stringify(path.posix.dirname(target)) +
      ", recursive = TRUE, showWarnings = FALSE)");
    await webR.FS.writeFile(target,
      Buffer.from(file.content, file.type === "binary" ? "base64" : "utf8"));
  }
  await webR.evalRVoid(`
    source("app.R", encoding = "UTF-8")
    stopifnot(nrow(houses) == 600L)
    result <- bootstrap_houses(houses, bootstrap_settings(B = 500L))
    stopifnot(result$observed["mean"] == 410580,
      result$observed["median"] == 366000,
      result$replicates$mean[1L] == 415890,
      result$replicates$median[1L] == 369000,
      anyDuplicated(result$first_indices) > 0L)
    for (variable in names(bootstrap_labels)) {
      settings <- bootstrap_settings(variable, B = 500L, confidence = 0.99, seed = 17L)
      reference <- bootstrap_houses(houses, settings)
      for (statistic in names(bootstrap_statistics)) {
        built <- ggplot_build(bootstrap_plot(reference, statistic))
        stopifnot(sum(built$data[[1L]]$count) == 500L,
          nrow(built$data[[3L]]) == 2L,
          isTRUE(all.equal(built$data[[3L]]$xintercept,
            as.numeric(quantile(reference$replicates[[statistic]], c(0.005, 0.995), type = 7)))))
        # Le CSV local évite toute acquisition dans le test du script exporté.
        file.copy("data/maisons-quebec.csv", "maisons-quebec.csv", overwrite = TRUE)
        code <- export_bootstrap_code(settings, statistic)
        env <- new.env(parent = globalenv())
        eval(parse(text = code), envir = env)
        stopifnot(identical(env$resultats$replicates, reference$replicates),
          file.exists("bootstrap-graphique.png"))
      }
    }
  `);
  assert.equal(await webR.evalRNumber("nrow(houses)"), 600);
  console.log(await webR.evalRString("R.version.string"));
  console.log("WebAssembly : bootstrap reproductible, quatre graphiques et quatre exports exécutés OK.");
} finally {
  await webR.close();
}
