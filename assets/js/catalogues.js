// All catalogues use the same live filters, reset and empty-state behaviour.
document.querySelectorAll('[data-resource-catalogue]').forEach(root => {
  const query = root.querySelector('[data-query]');
  const filters = [...root.querySelectorAll('[data-filter]')];
  const cards = [...root.querySelectorAll('[data-catalogue-card]')];
  const grid = root.querySelector('[data-catalogue-results]');
  const count = root.querySelector('[data-result-count]');
  const empty = root.querySelector('[data-empty-catalogue]');
  const active = root.querySelector('[data-active-filters]');
  const sort = root.querySelector('[data-sort]');
  const panel = root.querySelector('.catalogue-filter-panel');
  const normalize = value => (value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
  const tokens = value => (value || '').split('||');
  function update() {
    const words = normalize(query.value).split(/\s+/).filter(Boolean);
    let visible = 0;
    cards.forEach(card => {
      const matches = words.every(word => normalize(card.dataset.search).includes(word)) &&
        filters.every(field => !field.value || tokens(card.dataset[field.dataset.filter]).includes(field.value));
      card.hidden = !matches;
      visible += Number(matches);
    });
    const labels = {
      donnees: ['jeu de données', 'jeux de données'],
      activite: ['activité', 'activités'],
      document: ['document', 'documents'],
      application: ['application', 'applications']
    };
    const label = labels[root.dataset.resourceCatalogue][visible === 1 ? 0 : 1];
    count.textContent = `${visible} ${label} sur ${cards.length}`;
    empty.hidden = visible !== 0;
    active.replaceChildren();
    filters.filter(field => field.value).forEach(field => {
      const chip = document.createElement('button');
      chip.type = 'button';
      chip.textContent = `${field.value} ×`;
      chip.setAttribute('aria-label', `Retirer le filtre ${field.value}`);
      chip.addEventListener('click', () => { field.value = ''; update(); panel.querySelector('summary').focus(); });
      active.append(chip);
    });
    cards.slice().sort((a, b) => {
      const delta = sort.value === 'duration' ? Number(a.dataset.minutes) - Number(b.dataset.minutes) : 0;
      return delta || a.dataset.title.localeCompare(b.dataset.title, 'fr');
    }).forEach(card => grid.append(card));
  }
  query.addEventListener('input', update);
  filters.forEach(field => field.addEventListener('change', update));
  sort.addEventListener('change', update);
  root.querySelector('[data-reset]').addEventListener('click', () => {
    query.value = '';
    filters.forEach(field => { field.value = ''; });
    sort.value = 'title';
    update();
    query.focus();
  });
  root.querySelector('[data-close-filters]').addEventListener('click', () => {
    panel.open = false;
    panel.querySelector('summary').focus();
  });
  update();
  function openLinkedFilters() {
    if (location.hash === `#${panel.id}`) panel.open = true;
  }
  openLinkedFilters();
  window.addEventListener('hashchange', openLinkedFilters);
});
