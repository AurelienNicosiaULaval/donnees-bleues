// Exécuter le paquet exporté dans son moteur R WebAssembly.
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import { pathToFileURL } from "node:url";
const destination = path.resolve(process.argv[2] ?? "docs/outils/permutations-accidents");
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
    stopifnot(nrow(accidents) == 108186L)
    result <- permutation_accidents(accidents, permutation_settings(B = 5000L))
    summary <- permutation_summary(result)
    stopifnot(summary$n_weekday == 82168L, summary$n_weekend == 26018L,
      summary$victims_weekday == 16740L, summary$victims_weekend == 5758L,
      all(result$replicates$victims_weekend[1:6] == c(5421, 5377, 5424, 5314, 5301, 5340)),
      summary$extreme == 0L, summary$p_mc == 1/5001,
      summary$p_exact > 0, summary$p_exact < 1e-8,
      sum(result$first$permuted_victim) == 22498L)
    for (settings in list(permutation_settings(B = 500L, seed = 17L),
                          permutation_settings(B = 5000L))) {
      reference <- permutation_accidents(accidents, settings)
      built <- ggplot_build(permutation_plot(reference))
      stopifnot(sum(built$data[[1L]]$count) == settings$B,
        built$data[[3L]]$xintercept == reference$observed_pp,
        built$data[[4L]]$xintercept == -reference$observed_pp)
      file.copy("data/accidents-quebec-2022.csv", "accidents-quebec-2022.csv", overwrite = TRUE)
      code <- export_permutation_code(settings)
      env <- new.env(parent = globalenv())
      eval(parse(text = code), envir = env)
      actual <- read_csv("permutations-resume.csv", show_col_types = FALSE)
      stopifnot(identical(env$resultats$replicates, reference$replicates),
        isTRUE(all.equal(actual, permutation_summary(reference), check.attributes = FALSE)),
        file.exists("permutations-graphique.png"))
    }
  `);
  assert.equal(await webR.evalRNumber("nrow(accidents)"), 108186);
  console.log(await webR.evalRString("R.version.string"));
  console.log("WebAssembly : marges, permutations identiques au moteur natif et deux scripts exportés OK.");
} finally {
  await webR.close();
}
