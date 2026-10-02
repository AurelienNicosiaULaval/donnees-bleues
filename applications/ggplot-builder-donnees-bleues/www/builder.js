document.addEventListener('click', async function(event) {
  const button = event.target.closest('#copy-code');
  if (!button) return;
  const code = document.getElementById('code');
  if (!code) return;
  try {
    await navigator.clipboard.writeText(code.textContent);
    button.textContent = 'Code copié';
    window.setTimeout(() => { button.textContent = 'Copier le code'; }, 1800);
  } catch (_) {
    const range = document.createRange();
    range.selectNodeContents(code);
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    button.textContent = 'Sélectionné : copiez avec Ctrl/Cmd+C';
  }
});

// Fetch first so Shinylive's virtual HTTP response also works for downloads.
// Browsers can otherwise bypass the service worker for a native download link.
document.addEventListener('click', async function(event) {
  const link = event.target.closest('a.shiny-download-link');
  if (!link || !link.href || link.classList.contains('disabled')) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  if (link.getAttribute('aria-busy') === 'true') return;
  link.setAttribute('aria-busy', 'true');
  let notice = document.getElementById('download-status');
  if (!notice) {
    notice = document.createElement('p');
    notice.id = 'download-status';
    notice.setAttribute('role', 'status');
    notice.className = 'download-status';
    link.closest('.export-row').after(notice);
  }
  notice.textContent = 'Préparation du fichier…';
  try {
    const response = await fetch(link.href);
    if (!response.ok) throw new Error('Download failed');
    const disposition = response.headers.get('content-disposition') || '';
    const filename = disposition.match(/filename="([^"]+)"/)?.[1];
    if (!filename) throw new Error('Missing filename');
    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    const download = document.createElement('a');
    download.href = url;
    download.download = filename;
    document.body.append(download);
    download.click();
    download.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 10000);
    notice.textContent = 'Fichier prêt : ' + filename;
  } catch (_) {
    notice.textContent = 'Le téléchargement a échoué. Réessayez dans un moment.';
  } finally {
    link.removeAttribute('aria-busy');
  }
}, true);
