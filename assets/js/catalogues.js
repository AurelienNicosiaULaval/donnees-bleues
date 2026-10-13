// Les mêmes filtres et tris servent aux catalogues et à la recherche commune.
document.querySelectorAll('[data-resource-catalogue]').forEach(root => {
  const query = root.querySelector('[data-query]');
  const filters = [...root.querySelectorAll('[data-filter]')];
  const cards = [...root.querySelectorAll('[data-catalogue-card]')];
  const grid = root.querySelector('[data-catalogue-results]');
  const count = root.querySelector('[data-result-count]');
  const empty = root.querySelector('[data-empty-catalogue]');
  const active = root.querySelector('[data-active-filters]');
  const sort = root.querySelector('[data-sort]');
  const normalize = value => (value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
  const tokens = value => (value || '').split(/\|\||;/).map(term => term.trim()).filter(Boolean);
  const labels = {
    donnees: ['jeu de données', 'jeux de données'], activite: ['activité', 'activités'],
    document: ['document', 'documents'], application: ['outil ou tutoriel', 'outils et tutoriels'],
    ressource: ['ressource', 'ressources']
  };
  // Les anciens liens par auteur ou cours restent utilisables et réinitialisables.
  const legacy = {};
  if (root.dataset.resourceCatalogue === 'ressource') {
    const params = new URLSearchParams(location.search);
    for (const key of ['author', 'course']) if (params.get(key)) legacy[key] = params.get(key);
  }
  function restore() {
    const params = new URLSearchParams(location.search);
    query.value = params.get('query') || '';
    for (const field of filters) {
      const value = params.get(field.dataset.filter) || '';
      field.value = [...field.options].some(option => option.value === value) ? value : '';
    }
    sort.value = [...sort.options].some(option => option.value === params.get('sort')) ? params.get('sort') : 'added';
  }
  function remember() {
    const params = new URLSearchParams(location.search);
    params.delete('query');
    if (query.value.trim()) params.set('query', query.value.trim());
    for (const field of filters) {
      params.delete(field.dataset.filter);
      if (field.value) params.set(field.dataset.filter, field.value);
    }
    params.delete('sort');
    if (sort.value !== 'added') params.set('sort', sort.value);
    for (const key of ['author', 'course']) {
      if (legacy[key]) params.set(key, legacy[key]);
      else if (root.dataset.resourceCatalogue === 'ressource') params.delete(key);
    }
    history.replaceState(null, '', location.pathname + (params.size ? '?' + params : '') + location.hash);
  }
  function addChip(label, remove) {
    const chip = document.createElement('button');
    chip.type = 'button';
    chip.textContent = `${label} ×`;
    chip.setAttribute('aria-label', `Retirer le filtre ${label}`);
    chip.addEventListener('click', remove);
    active.append(chip);
  }
  function update() {
    const words = normalize(query.value).split(/\s+/).filter(Boolean);
    let visible = 0;
    for (const card of cards) {
      const matches = words.every(word => normalize(card.dataset.search).includes(word)) &&
        filters.every(field => !field.value || tokens(card.dataset[field.dataset.filter]).includes(field.value)) &&
        Object.entries(legacy).every(([key, value]) => tokens(card.dataset[key]).includes(value));
      card.hidden = !matches;
      visible += Number(matches);
    }
    count.textContent = `${visible} ${labels[root.dataset.resourceCatalogue][visible === 1 ? 0 : 1]} sur ${cards.length}`;
    empty.hidden = visible !== 0;
    active.replaceChildren();
    filters.filter(field => field.value).forEach(field => {
      const label = field.selectedOptions[0].textContent;
      addChip(label, () => { field.value = ''; update(); field.focus(); });
    });
    Object.entries(legacy).forEach(([key, value]) => {
      addChip(value, () => { delete legacy[key]; update(); query.focus(); });
    });
    const byTitle = (a, b) => a.dataset.title.localeCompare(b.dataset.title, 'fr', { numeric: true });
    function compare(a, b) {
      if (sort.value === 'title-desc') return byTitle(b, a);
      if (sort.value === 'title') return byTitle(a, b);
      const key = sort.value === 'updated' ? 'dateUpdated' : sort.value.startsWith('duration') ? 'minutes' : 'dateAdded';
      const first = key === 'minutes' ? Number(a.dataset[key]) : Date.parse(a.dataset[key]);
      const second = key === 'minutes' ? Number(b.dataset[key]) : Date.parse(b.dataset[key]);
      // Une valeur manquante reste en fin de liste quel que soit le sens du tri.
      if (!Number.isFinite(first)) return Number.isFinite(second) ? 1 : byTitle(a, b);
      if (!Number.isFinite(second)) return -1;
      const delta = sort.value === 'duration' ? first - second : second - first;
      return delta || byTitle(a, b);
    }
    cards.slice().sort(compare).forEach(card => grid.append(card));
    remember();
  }
  query.addEventListener('input', update);
  filters.forEach(field => field.addEventListener('change', update));
  sort.addEventListener('change', update);
  root.querySelector('[data-reset]').addEventListener('click', () => {
    query.value = '';
    filters.forEach(field => { field.value = ''; });
    Object.keys(legacy).forEach(key => { delete legacy[key]; });
    sort.value = 'added';
    update();
    query.focus();
  });
  if (window.matchMedia('(max-width: 650px)').matches) root.querySelector('.catalogue-filter-panel').open = false;
  restore();
  update();
});
