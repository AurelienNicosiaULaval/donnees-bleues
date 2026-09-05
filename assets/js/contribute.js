(() => {
  const form = document.getElementById('contribution-form');
  if (!form) return;
  const status = document.getElementById('contribution-status');
  const output = document.getElementById('contribution-output');
  const emailLink = document.getElementById('contribution-email');
  const endpoint = form.dataset.endpoint;
  const submit = form.querySelector('[type=submit]');
  if (endpoint) {
    submit.textContent = 'Envoyer la proposition';
    status.textContent = 'Votre proposition sera envoyée à info@donneesbleues.ca lorsque vous cliquerez sur Envoyer.';
  }
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (!form.reportValidity()) return;
    const values = Object.fromEntries(new FormData(form));
    const labels = {name:'Nom', email:'Courriel', type:'Type', title:'Titre', url:'Lien', author:'Auteur ou organisme', themes:'Thèmes', courses:'Cours et établissement', message:'Description'};
    const body = Object.entries(labels).map(([key,label]) => `${label} : ${values[key] || 'Non renseigné'}`).join('\n\n');
    output.value = body;
    document.getElementById('contribution-draft').hidden = false;
    if (!endpoint) {
      emailLink.href = `mailto:${form.dataset.recipient}?subject=${encodeURIComponent('Données bleues : ' + values.title)}&body=${encodeURIComponent(body)}`;
      emailLink.hidden = false;
      status.textContent = 'Votre proposition est préparée. Ouvrez votre messagerie ou copiez le texte pour l’envoyer. Aucun message n’a encore été envoyé.';
      return;
    }
    submit.disabled = true;
    status.textContent = 'Envoi en cours…';
    try {
      const response = await fetch(endpoint, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(values), signal:AbortSignal.timeout(20000)});
      if (!response.ok) throw new Error('delivery');
      status.textContent = 'Votre proposition a été transmise. Merci! Elle sera examinée avant publication.';
    } catch (_) {
      status.textContent = 'L’envoi n’a pas pu être confirmé. Votre texte reste disponible ci-dessous; conservez-le avant de réessayer.';
    } finally { submit.disabled = false; }
  });
  document.getElementById('contribution-copy').addEventListener('click', async () => {
    try { await navigator.clipboard.writeText(output.value); status.textContent = 'Proposition copiée. Aucun message envoyé par cette action.'; }
    catch (_) { output.focus(); output.select(); status.textContent = 'Sélectionnez et copiez le texte ci-dessous.'; }
  });
})();
