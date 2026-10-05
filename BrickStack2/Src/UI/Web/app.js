async function loadDemoData() {
  const source = document.getElementById('data-source');
  const errorMessage = document.getElementById('error-message');
  try {
    const response = await fetch('/api/demo', { cache: 'no-store' });
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || 'The backend service returned an error.');
    }

    document.getElementById('collection-name').textContent = data.collection.name;
    document.getElementById('sets-count').textContent = data.collection.sets.toLocaleString();
    document.getElementById('pieces-count').textContent = data.collection.pieces.toLocaleString();
    document.getElementById('built-count').textContent = data.collection.built.toLocaleString();
    document.getElementById('set-lists').replaceChildren(
      ...data.setLists.map((list, index) => {
        const item = document.createElement('article');
        item.className = 'list-item';
        const marker = document.createElement('span');
        marker.className = `list-marker marker-${index % 3}`;
        marker.setAttribute('aria-hidden', 'true');
        const details = document.createElement('div');
        details.className = 'list-details';
        const name = document.createElement('strong');
        name.textContent = list.name;
        const count = document.createElement('span');
        count.textContent = `${list.sets} sets`;
        details.append(name, count);
        const arrow = document.createElement('span');
        arrow.className = 'list-arrow';
        arrow.textContent = '›';
        item.append(marker, details, arrow);
        return item;
      })
    );
    source.innerHTML = '<span class="source-dot"></span>Dummy data from backend';
    errorMessage.hidden = true;
  } catch (error) {
    source.innerHTML = '<span class="source-dot offline"></span>Backend unavailable';
    errorMessage.textContent = `Could not load collection data: ${error.message}`;
    errorMessage.hidden = false;
    document.getElementById('set-lists').replaceChildren();
  }
}

loadDemoData();
