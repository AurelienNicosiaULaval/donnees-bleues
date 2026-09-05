(() => {
  const form = document.getElementById('resource-filters');
  if (!form) return;
  const cards = [...document.querySelectorAll('.resource-card')];
  const fields = Object.fromEntries(['query', 'type', 'theme', 'author', 'course'].map(k => [k, document.getElementById(`resource-${k}`)]));
  const normalize = text => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
  const tokens = value => value.split(';').map(x => x.trim()).filter(Boolean);
  for (const key of ['theme', 'author', 'course']) {
    const values = [...new Set(cards.flatMap(card => tokens(card.dataset[key])))].sort((a,b) => a.localeCompare(b, 'fr'));
    for (const value of values) fields[key].add(new Option(value, value));
  }
  function update() {
    const words = normalize(fields.query.value).split(/\s+/).filter(Boolean);
    let count = 0;
    for (const card of cards) {
      const matched = words.every(word => normalize(card.dataset.search).includes(word)) &&
        (!fields.type.value || card.dataset.type === fields.type.value) &&
        ['theme','author','course'].every(key => !fields[key].value || tokens(card.dataset[key]).includes(fields[key].value));
      card.hidden = !matched;
      count += Number(matched);
    }
    document.getElementById('resource-count').textContent = `${count} ressource${count === 1 ? '' : 's'} sur ${cards.length}`;
    document.getElementById('resource-empty').hidden = count !== 0;
    const params = new URLSearchParams();
    for (const [key, field] of Object.entries(fields)) if (field.value) params.set(key, field.value);
    history.replaceState(null, '', location.pathname + (params.size ? '?' + params : '') + location.hash);
  }
  const params = new URLSearchParams(location.search);
  for (const [key, field] of Object.entries(fields)) if (params.has(key)) field.value = params.get(key);
  form.addEventListener('submit', event => event.preventDefault());
  form.addEventListener('input', update);
  form.addEventListener('change', update);
  form.addEventListener('reset', () => { setTimeout(update, 0); });
  update();
})();
