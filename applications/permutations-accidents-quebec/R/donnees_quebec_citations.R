# Références générées depuis le registre Données Québec.
dq_app_citations <- function(ui) {
  htmltools::tagAppendChild(ui, htmltools::tags$details(
    style = "overflow-wrap:anywhere; margin:1rem; padding:1rem;",
    htmltools::tags$summary("Citer les données"),
    htmltools::HTML("<section class=\"dq-references\"><h3>Citer les données</h3><p>Références des fiches officielles consultées. Les fichiers utilisés restent les instantanés décrits dans la provenance; cette vérification documentaire ne les actualise pas.</p><ul><li><p>SOCIÉTÉ DE L'ASSURANCE AUTOMOBILE DU QUÉBEC (SAAQ). Rapports d'accident, [Jeu de données], dans Données Québec, 2017, mis à jour le 18 décembre 2023. [https://www.donneesquebec.ca/recherche/dataset/rapports-d-accident], (consulté le 10 novembre 2026).</p><p><a href=\"https://www.donneesquebec.ca/recherche/dataset/rapports-d-accident\">Fiche officielle</a> · Attribution (CC-BY 4.0)</p></li></ul><p><a href=\"https://donneesbleues.ca/guide.html#acquerir-par-api\">Acquérir les données par API et conserver un instantané</a></p></section>")
  ))
}
