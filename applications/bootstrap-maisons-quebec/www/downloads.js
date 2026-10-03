// Récupérer la réponse Shiny avant de déclencher le téléchargement du Blob.
// Les navigations de téléchargement direct peuvent contourner le service
// worker qui fournit les fichiers de la session dans Shinylive.
document.addEventListener("click", async function (event) {
  const link = event.target.closest("a.shiny-download-link");
  if (!link || !link.getAttribute("href") || link.classList.contains("disabled")) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  if (link.getAttribute("aria-disabled") === "true") return;
  const status = document.getElementById("download-status");
  const filenames = {
    plot_download: "bootstrap-graphique.png",
    summary_download: "bootstrap-resume.csv",
    replicates_download: "bootstrap-repetitions.csv",
    code_download: "bootstrap-maisons.R"
  };
  link.setAttribute("aria-disabled", "true");
  if (status) status.textContent = "Préparation du fichier…";
  try {
    const response = await fetch(link.href, { credentials: "same-origin" });
    if (!response.ok) throw new Error("Réponse " + response.status);
    const blob = await response.blob();
    if (!blob.size) throw new Error("Fichier vide");
    const url = URL.createObjectURL(blob);
    const download = document.createElement("a");
    download.href = url;
    download.download = filenames[link.id] || "bootstrap-export";
    document.body.appendChild(download);
    download.click();
    download.remove();
    setTimeout(() => URL.revokeObjectURL(url), 60000);
    if (status) status.textContent = "Fichier prêt : " + download.download;
  } catch (error) {
    if (status) status.textContent = "Le téléchargement a échoué. Réessayer après le chargement de l’application.";
    console.error("Export bootstrap :", error.message);
  } finally {
    link.removeAttribute("aria-disabled");
  }
}, true);
