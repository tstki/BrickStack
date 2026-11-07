const catalogState = {
  mode: 'sets',
  cursor: '',
  loading: false,
  requestId: 0
};
let detailRequestId = 0;
const inventoryState = {
  setNumber: '',
  version: 0,
  cursor: '',
  loading: false,
  requestId: 0
};

async function fetchJson(url, options = {}) {
  const response = await fetch(url, { cache: 'no-store', ...options });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || data.error || 'The catalog request failed.');
  }
  return data;
}

function showCatalogError(message) {
  const status = document.getElementById('catalog-status');
  status.className = 'error-message';
  status.textContent = message;
}

async function loadCatalogSummary() {
  const source = document.getElementById('data-source');
  const sourceLabel = document.getElementById('data-source-label');
  try {
    const summary = await fetchJson('/api/catalog/summary');
    document.getElementById('catalog-set-count').textContent = summary.sets.toLocaleString();
    document.getElementById('catalog-part-count').textContent = summary.parts.toLocaleString();
    document.getElementById('catalog-theme-count').textContent = summary.themes.toLocaleString();
    sourceLabel.textContent = 'Verified local catalog';
  } catch (error) {
    source.classList.add('source-badge-offline');
    sourceLabel.textContent = 'Catalog unavailable';
    showCatalogError(`Could not load catalog totals: ${error.message}`);
  }
}

function addLookupOptions(select, items) {
  const options = items.map((item) => {
    const option = document.createElement('option');
    option.value = item.id;
    option.textContent = item.name;
    return option;
  });
  select.append(...options);
}

async function loadCatalogLookups() {
  try {
    const [themes, categories, colors] = await Promise.all([
      fetchJson('/api/catalog/themes'),
      fetchJson('/api/catalog/part-categories'),
      fetchJson('/api/catalog/colors')
    ]);
    addLookupOptions(document.getElementById('set-theme'), themes);
    addLookupOptions(document.getElementById('part-category'), categories);
    addLookupOptions(document.getElementById('part-color'), colors);
  } catch (error) {
    showCatalogError(`Could not load catalog filters: ${error.message}`);
  }
}

async function loadBootstrapStatus() {
  const panel = document.getElementById('admin-bootstrap');
  const status = document.getElementById('bootstrap-status');
  try {
    const result = await fetchJson('/api/auth/bootstrap/status');
    panel.hidden = !result.required;
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    status.textContent = `Could not check first-run setup: ${error.message}`;
  }
}

async function loadAuthStatus() {
  const profileName = document.getElementById('profile-name');
  const avatar = document.getElementById('profile-avatar');
  const currentUser = document.getElementById('profile-current-user');
  const loginForm = document.getElementById('login-form');
  const inviteToggle = document.getElementById('invite-password-toggle');
  const inviteForm = document.getElementById('invite-password-form');
  const logoutButton = document.getElementById('logout-button');
  const heading = document.getElementById('profile-heading');
  const accountAdmin = document.getElementById('account-admin');
  const totpEnrollment = document.getElementById('totp-enrollment');
  const totpEnrollmentCopy = document.getElementById('totp-enrollment-copy');
  const totpEnrollmentStart = document.getElementById('totp-enrollment-start');
  const totpEnrollmentSetup = document.getElementById('totp-enrollment-setup');
  const recoveryCodes = document.getElementById('totp-recovery-codes');
  const recoveryAcknowledge = document.getElementById('totp-recovery-acknowledge');
  const loginTotpFields = document.getElementById('login-totp-fields');
  const loginTotpCode = document.getElementById('login-totp-code');
  loginTotpFields.hidden = true;
  loginTotpCode.required = false;
  loginTotpCode.value = '';
  try {
    const result = await fetchJson('/api/auth/session');
    const authenticated = result.authenticated === true;
    const user = result.user;
    profileName.textContent = authenticated ? user.displayName : 'Sign in';
    avatar.textContent = authenticated
      ? user.displayName.trim().slice(0, 1).toUpperCase()
      : '?';
    currentUser.hidden = !authenticated;
    currentUser.textContent = authenticated
      ? `Signed in as ${user.displayName} (${user.username})`
      : '';
    loginForm.hidden = authenticated;
    inviteToggle.hidden = authenticated;
    inviteForm.hidden = true;
    logoutButton.hidden = !authenticated;
    heading.textContent = authenticated ? 'Your account' : 'Sign in';
    const needsTotpSetup = authenticated && user.totpEnabled !== true;
    const isGlobalAdmin = authenticated && user.role === 0;
    const canManageAccounts = isGlobalAdmin && user.totpEnabled === true;
    accountAdmin.hidden = !canManageAccounts;
    totpEnrollment.hidden = !needsTotpSetup;
    totpEnrollmentCopy.textContent = isGlobalAdmin
      ? 'Two-factor authentication is required before administrator tools can be used.'
      : 'Two-factor authentication is optional for your account.';
    totpEnrollmentStart.hidden = !needsTotpSetup;
    if (needsTotpSetup && totpEnrollmentSetup.hidden) {
      totpEnrollmentStart.textContent = 'Set up authenticator';
    }
    if (!needsTotpSetup) {
      totpEnrollmentSetup.hidden = true;
      recoveryCodes.hidden = true;
      recoveryAcknowledge.hidden = true;
    }
    if (canManageAccounts) await loadManagedAccounts();
  } catch (error) {
    const status = document.getElementById('login-status');
    status.className = 'error-message bootstrap-status';
    status.textContent = `Could not check sign-in status: ${error.message}`;
  }
}

async function loadManagedAccounts() {
  const list = document.getElementById('managed-account-list');
  const status = document.getElementById('account-admin-status');
  try {
    const result = await fetchJson('/api/admin/users');
    const items = result.users.map((user) => {
      const item = document.createElement('div');
      item.className = 'managed-account';
      const identity = document.createElement('span');
      identity.className = 'managed-account-identity';
      const name = document.createElement('strong');
      name.textContent = user.displayName;
      const username = document.createElement('span');
      username.textContent = user.username;
      identity.append(name, username);
      const role = document.createElement('span');
      role.className = 'managed-account-role';
      role.textContent = user.role === 0 ? 'Global Admin' : 'User';
      item.append(identity, role);
      return item;
    });
    list.replaceChildren(...items);
    status.textContent = `${result.total} account${result.total === 1 ? '' : 's'}`;
    status.className = 'loading-message bootstrap-status';
  } catch (error) {
    status.textContent = `Could not load accounts: ${error.message}`;
    status.className = 'error-message bootstrap-status';
  }
}

document.getElementById('profile-button').addEventListener('click', async () => {
  await loadAuthStatus();
  document.getElementById('profile-dialog').showModal();
});

document.getElementById('invite-password-toggle').addEventListener('click', () => {
  const form = document.getElementById('invite-password-form');
  const opening = form.hidden;
  form.hidden = !opening;
  document.getElementById('login-form').hidden = opening;
});

document.getElementById('invite-password-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const username = document.getElementById('invite-username').value;
  const temporaryPassword = document.getElementById('invite-temporary-password').value;
  const newPassword = document.getElementById('invite-new-password').value;
  const status = document.getElementById('login-status');
  const submit = form.querySelector('button[type="submit"]');
  if (newPassword !== document.getElementById('invite-confirm-password').value) {
    status.className = 'error-message bootstrap-status';
    status.textContent = 'The new passwords do not match.';
    return;
  }

  submit.disabled = true;
  status.className = 'loading-message bootstrap-status';
  status.textContent = 'Setting your password...';
  try {
    await fetchJson('/api/auth/password', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-BrickStack-Request': '1'
      },
      body: JSON.stringify({
        username,
        currentPassword: temporaryPassword,
        newPassword
      })
    });
    form.reset();
    form.hidden = true;
    document.getElementById('login-form').hidden = false;
    document.getElementById('login-username').value = username;
    status.className = 'loading-message bootstrap-status';
    status.textContent = 'Password set. You can now sign in.';
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    status.textContent = error.message === 'invalid_credentials'
      ? 'The invitation username or temporary password was not accepted.'
      : `Could not set the password: ${error.message}`;
  } finally {
    submit.disabled = false;
  }
});

document.getElementById('login-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const submit = form.querySelector('button[type="submit"]');
  const status = document.getElementById('login-status');
  submit.disabled = true;
  status.className = 'loading-message bootstrap-status';
  status.textContent = 'Signing in...';
  try {
    const totpInput = document.getElementById('login-totp-code');
    const payload = {
      username: document.getElementById('login-username').value,
      password: document.getElementById('login-password').value
    };
    if (!document.getElementById('login-totp-fields').hidden) {
      const code = totpInput.value.trim();
      if (/^[0-9]{6}$/.test(code)) payload.totpCode = code;
      else payload.recoveryCode = code;
    }
    const result = await fetchJson('/api/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-BrickStack-Request': '1'
      },
      body: JSON.stringify(payload)
    });
    if (result.totpRequired === true) {
      document.getElementById('login-totp-fields').hidden = false;
      document.getElementById('login-totp-code').required = true;
      status.className = 'loading-message bootstrap-status';
      status.textContent = 'Enter an authenticator code or an unused recovery code.';
      totpInput.focus();
      return;
    }
    document.getElementById('login-password').value = '';
    totpInput.value = '';
    totpInput.required = false;
    document.getElementById('login-totp-fields').hidden = true;
    status.textContent = '';
    document.getElementById('profile-dialog').close();
    await loadAuthStatus();
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    status.textContent = error.message === 'invalid_credentials'
      ? 'Sign-in failed. Check the username and password, or try again later.'
      : `Could not sign in: ${error.message}`;
    if (!document.getElementById('login-totp-fields').hidden) {
      document.getElementById('login-totp-code').value = '';
    }
  } finally {
    submit.disabled = false;
  }
});

document.getElementById('totp-enrollment-start').addEventListener('click', async () => {
  const button = document.getElementById('totp-enrollment-start');
  const status = document.getElementById('totp-enrollment-status');
  button.disabled = true;
  status.className = 'loading-message bootstrap-status';
  status.textContent = 'Preparing authenticator setup...';
  try {
    const result = await fetchJson('/api/auth/totp/enroll/start', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-BrickStack-Request': '1'
      },
      body: '{}'
    });
    document.getElementById('totp-secret').value = result.secret;
    document.getElementById('totp-enrollment-setup').hidden = false;
    button.textContent = 'Generate a new setup key';
    document.getElementById('totp-enrollment-code').value = '';
    status.textContent = 'Setup key created. Verify a current code to enable it.';
    document.getElementById('totp-enrollment-code').focus();
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    status.textContent = `Could not start authenticator setup: ${error.message}`;
    button.disabled = false;
  }
});

document.getElementById('totp-enrollment-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const submit = form.querySelector('button[type="submit"]');
  const status = document.getElementById('totp-enrollment-status');
  submit.disabled = true;
  status.className = 'loading-message bootstrap-status';
  status.textContent = 'Verifying authenticator...';
  try {
    const result = await fetchJson('/api/auth/totp/enroll/confirm', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-BrickStack-Request': '1'
      },
      body: JSON.stringify({
        code: document.getElementById('totp-enrollment-code').value.trim()
      })
    });
    document.getElementById('totp-enrollment-setup').hidden = true;
    document.getElementById('totp-enrollment-start').hidden = true;
    document.getElementById('totp-enrollment-code').value = '';
    const recoveryCodes = document.getElementById('totp-recovery-codes');
    recoveryCodes.textContent =
      `Save these one-time recovery codes now. Each can be used once.\n\n${result.recoveryCodes.join('\n')}`;
    recoveryCodes.hidden = false;
    document.getElementById('totp-recovery-acknowledge').hidden = false;
    status.className = 'loading-message bootstrap-status';
    status.textContent = 'Authenticator enabled. Recovery codes will not be shown again.';
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    status.textContent = `Could not enable authenticator: ${error.message}`;
    document.getElementById('totp-enrollment-code').value = '';
  } finally {
    submit.disabled = false;
  }
});

document.getElementById('totp-recovery-acknowledge').addEventListener('click', async () => {
  document.getElementById('totp-recovery-codes').textContent = '';
  document.getElementById('totp-recovery-codes').hidden = true;
  document.getElementById('totp-recovery-acknowledge').hidden = true;
  document.getElementById('totp-enrollment').hidden = true;
  await loadAuthStatus();
});

document.getElementById('logout-button').addEventListener('click', async () => {
  const status = document.getElementById('login-status');
  const button = document.getElementById('logout-button');
  button.disabled = true;
  try {
    await fetchJson('/api/auth/logout', {
      method: 'POST',
      headers: { 'X-BrickStack-Request': '1' }
    });
    await loadAuthStatus();
    status.className = 'loading-message bootstrap-status';
    status.textContent = 'Signed out. Sign in with another account to switch users.';
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    status.textContent = `Could not sign out: ${error.message}`;
  } finally {
    button.disabled = false;
  }
});

document.getElementById('create-user-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const submit = form.querySelector('button[type="submit"]');
  const status = document.getElementById('account-admin-status');
  const credential = document.getElementById('account-temporary-password');
  submit.disabled = true;
  credential.hidden = true;
  status.className = 'loading-message bootstrap-status';
  status.textContent = 'Creating user...';
  try {
    const result = await fetchJson('/api/admin/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-BrickStack-Request': '1'
      },
      body: JSON.stringify({
        username: document.getElementById('new-username').value,
        displayName: document.getElementById('new-display-name').value
      })
    });
    form.reset();
    credential.textContent =
      `Temporary password for ${result.user.username} (shown once): ${result.temporaryPassword}`;
    credential.hidden = false;
    status.className = 'loading-message bootstrap-status';
    status.textContent = 'Account created. Share the temporary password securely.';
    await loadManagedAccounts();
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    status.textContent = error.message === 'username_unavailable'
      ? 'That username is already in use.'
      : `Could not create the account: ${error.message}`;
  } finally {
    submit.disabled = false;
  }
});

document.getElementById('bootstrap-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const currentPassword = document.getElementById('bootstrap-current-password').value;
  const newPassword = document.getElementById('bootstrap-new-password').value;
  const confirmPassword = document.getElementById('bootstrap-confirm-password').value;
  const status = document.getElementById('bootstrap-status');
  const submit = event.currentTarget.querySelector('button[type="submit"]');
  if (newPassword !== confirmPassword) {
    status.className = 'error-message bootstrap-status';
    status.textContent = 'The new passwords do not match.';
    return;
  }

  submit.disabled = true;
  status.className = 'loading-message bootstrap-status';
  status.textContent = 'Replacing the initial password...';
  try {
    await fetchJson('/api/auth/bootstrap/password', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-BrickStack-Request': '1'
      },
      body: JSON.stringify({
        username: 'Admin',
        currentPassword,
        newPassword
      })
    });
    document.getElementById('admin-bootstrap').hidden = true;
    status.textContent = '';
    await loadAuthStatus();
    document.getElementById('profile-dialog').showModal();
  } catch (error) {
    status.className = 'error-message bootstrap-status';
    if (error.message === 'invalid_bootstrap_credentials') {
      status.textContent =
        'The current password was not accepted. If this is the first setup, enter Admin (capital A) as the current password.';
    } else if (error.message === 'loopback_only') {
      status.textContent =
        'Initial password replacement is only available from this computer.';
    } else {
      status.textContent =
        `Could not replace the initial password: ${error.message}`;
    }
  } finally {
    submit.disabled = false;
  }
});

function selectedQuery() {
  const queryId = catalogState.mode === 'sets' ? 'sets-query' : 'parts-query';
  return document.getElementById(queryId).value.trim();
}

async function loadCatalog(reset) {
  const status = document.getElementById('catalog-status');
  const results = document.getElementById('catalog-results');
  const loadMore = document.getElementById('catalog-load-more');

  if (catalogState.loading && !reset) return;
  if (reset) {
    catalogState.requestId += 1;
    catalogState.cursor = '';
    results.replaceChildren();
    loadMore.hidden = true;
    status.className = 'loading-message';
    status.textContent = 'Loading catalog...';
  }

  const requestId = catalogState.requestId;
  const mode = catalogState.mode;
  const params = new URLSearchParams({ q: selectedQuery(), pageSize: '25' });
  if (mode === 'sets') {
    const themeId = document.getElementById('set-theme').value;
    const year = document.getElementById('set-year').value.trim();
    if (themeId) params.set('themeId', themeId);
    if (year) params.set('year', year);
  } else {
    const categoryId = document.getElementById('part-category').value;
    const colorId = document.getElementById('part-color').value;
    if (categoryId) params.set('categoryId', categoryId);
    if (colorId) params.set('colorId', colorId);
  }
  if (!reset && catalogState.cursor) params.set('cursor', catalogState.cursor);

  catalogState.loading = true;
  loadMore.disabled = true;
  try {
    const data = await fetchJson(`/api/catalog/${mode}?${params}`);
    if (requestId !== catalogState.requestId) return;
    if (!data || !Array.isArray(data.items) || typeof data.hasMore !== 'boolean') {
      throw new Error('The catalog returned an invalid response.');
    }

    const cards = data.items.map((item, index) =>
      makeCatalogCard(mode, item, index + results.childElementCount));
    results.append(...cards);
    catalogState.cursor = data.nextCursor || '';
    loadMore.hidden = !data.hasMore;
    status.className = 'loading-message';
    status.textContent = results.childElementCount
      ? `${results.childElementCount.toLocaleString()} ${mode} shown${data.hasMore ? ' · more available' : ''}`
      : `No ${mode} matched your search.`;
  } catch (error) {
    if (requestId !== catalogState.requestId) return;
    showCatalogError(`Could not load ${mode}: ${error.message}`);
  } finally {
    if (requestId === catalogState.requestId) {
      catalogState.loading = false;
      loadMore.disabled = false;
    }
  }
}

function makeCatalogCard(mode, item, index) {
  const button = document.createElement('button');
  button.className = 'catalog-result';
  button.type = 'button';
  button.addEventListener('click', () => showCatalogDetail(mode, item));

  const marker = document.createElement('span');
  marker.className = 'catalog-result-marker';
  marker.style.backgroundColor = ['#6c8ce4', '#54b98a', '#efae43'][index % 3];
  marker.setAttribute('aria-hidden', 'true');

  const details = document.createElement('span');
  details.className = 'catalog-result-details';
  const name = document.createElement('strong');
  const summary = document.createElement('span');
  if (mode === 'sets') {
    name.textContent = `${item.name} (${item.setNumber})`;
    summary.textContent = `${item.year} · ${item.themeName} · ${item.partCount.toLocaleString()} parts`;
  } else {
    name.textContent = `${item.name} (${item.partNumber})`;
    summary.textContent = `${item.categoryName} · ${item.material || 'Material not specified'}`;
  }
  details.append(name, summary);
  const arrow = document.createElement('span');
  arrow.className = 'list-arrow';
  arrow.setAttribute('aria-hidden', 'true');
  arrow.textContent = '›';
  button.append(marker, details, arrow);
  return button;
}

function appendDetailLine(container, label, value) {
  const row = document.createElement('div');
  row.className = 'detail-row';
  const term = document.createElement('span');
  term.className = 'detail-label';
  term.textContent = label;
  const detail = document.createElement('strong');
  detail.textContent = value || '—';
  row.append(term, detail);
  container.append(row);
}

async function showCatalogDetail(mode, item) {
  detailRequestId += 1;
  inventoryState.requestId += 1;
  inventoryState.loading = false;
  const requestId = detailRequestId;
  const dialog = document.getElementById('catalog-detail');
  const content = document.getElementById('catalog-detail-content');
  const identifier = mode === 'sets' ? item.setNumber : item.partNumber;
  const route = mode === 'sets' ? 'sets' : 'parts';
  content.replaceChildren();
  const loading = document.createElement('p');
  loading.className = 'loading-message';
  loading.textContent = 'Loading details...';
  content.append(loading);
  dialog.showModal();

  try {
    const detail = await fetchJson(
      `/api/catalog/${route}/${encodeURIComponent(identifier)}`
    );
    if (requestId !== detailRequestId) return;
    const heading = document.createElement('p');
    heading.className = 'eyebrow';
    heading.textContent = mode === 'sets' ? 'SET DETAILS' : 'PART DETAILS';
    const title = document.createElement('h2');
    title.textContent = detail.name;
    const number = document.createElement('p');
    number.className = 'detail-number';
    number.textContent = identifier;
    const rows = document.createElement('div');
    rows.className = 'detail-rows';
    if (mode === 'sets') {
      appendDetailLine(rows, 'Year', String(detail.year));
      appendDetailLine(rows, 'Theme', detail.themeName);
      appendDetailLine(rows, 'Parts', detail.partCount.toLocaleString());
    } else {
      appendDetailLine(rows, 'Category', detail.categoryName);
      appendDetailLine(rows, 'Material', detail.material);
    }
    content.replaceChildren(heading, title, number, rows);
    if (mode === 'sets') {
      const inventorySection = document.createElement('section');
      inventorySection.className = 'inventory-section';
      inventorySection.innerHTML =
        '<h3>Set inventory</h3>' +
        '<button class="inventory-load-button" type="button">Load set inventory</button>' +
        '<p class="inventory-status" role="status"></p>' +
        '<div class="inventory-results"></div>' +
        '<button class="load-more inventory-load-more" type="button" hidden>Load more parts</button>';
      content.append(inventorySection);
      inventorySection.querySelector('.inventory-load-button')
        .addEventListener('click', () => loadSetInventory(identifier, true));
      inventorySection.querySelector('.inventory-load-more')
        .addEventListener('click', () => loadSetInventory(identifier, false));
    }
  } catch (error) {
    if (requestId !== detailRequestId) return;
    const message = document.createElement('p');
    message.className = 'error-message';
    message.textContent = `Could not load details: ${error.message}`;
    content.replaceChildren(message);
  }
}

async function loadSetInventory(setNumber, reset) {
  const section = document.querySelector('.inventory-section');
  if (!section || (inventoryState.loading && !reset)) return;
  if (reset) {
    inventoryState.requestId += 1;
    inventoryState.setNumber = setNumber;
    inventoryState.version = 0;
    inventoryState.cursor = '';
    section.querySelector('.inventory-results').replaceChildren();
    section.querySelector('.inventory-status').className = 'loading-message inventory-status';
    section.querySelector('.inventory-status').textContent = 'Loading inventory...';
    section.querySelector('.inventory-load-more').hidden = true;
  }

  const requestId = inventoryState.requestId;
  const params = new URLSearchParams({ pageSize: '50' });
  if (!reset && inventoryState.version > 0) {
    params.set('version', String(inventoryState.version));
  }
  if (!reset && inventoryState.cursor) params.set('cursor', inventoryState.cursor);
  const moreButton = section.querySelector('.inventory-load-more');
  inventoryState.loading = true;
  moreButton.disabled = true;

  try {
    const data = await fetchJson(
      `/api/catalog/sets/${encodeURIComponent(setNumber)}/inventory?${params}`
    );
    if (requestId !== inventoryState.requestId) return;
    if (!data || !Array.isArray(data.items) || !Number.isInteger(data.version)) {
      throw new Error('The inventory returned an invalid response.');
    }

    const results = section.querySelector('.inventory-results');
    data.items.forEach((part) => {
      const row = document.createElement('div');
      row.className = 'inventory-item';
      const color = document.createElement('span');
      color.className = 'inventory-color';
      color.setAttribute('aria-hidden', 'true');
      color.style.backgroundColor = /^[0-9a-f]{6}$/i.test(part.rgb)
        ? `#${part.rgb}`
        : '#e1e5ed';
      const description = document.createElement('span');
      description.className = 'inventory-part';
      description.textContent = `${part.name} (${part.partNumber}) · ${part.colorName}`;
      const quantity = document.createElement('strong');
      quantity.textContent = `${part.quantity}${part.isSpare ? ' spare' : ''}`;
      row.append(color, description, quantity);
      results.append(row);
    });

    inventoryState.version = data.version;
    inventoryState.cursor = data.nextCursor || '';
    moreButton.hidden = !data.hasMore;
    const status = section.querySelector('.inventory-status');
    status.className = 'loading-message inventory-status';
    status.textContent = results.childElementCount
      ? `Inventory version ${data.version} · ${results.childElementCount.toLocaleString()} entries shown`
      : `Inventory version ${data.version} has no part entries.`;
  } catch (error) {
    if (requestId !== inventoryState.requestId) return;
    const status = section.querySelector('.inventory-status');
    status.className = 'error-message inventory-status';
    status.textContent = `Could not load set inventory: ${error.message}`;
  } finally {
    if (requestId === inventoryState.requestId) {
      inventoryState.loading = false;
      moreButton.disabled = false;
    }
  }
}

let currentPage = 'overview';

function showPage(page) {
  if (!['overview', 'sets', 'parts'].includes(page)) {
    page = 'overview';
  }
  const changed = currentPage !== page ||
    (page !== 'overview' && catalogState.mode !== page);
  currentPage = page;
  document.getElementById('overview-page').hidden = page !== 'overview';
  document.getElementById('catalog-page').hidden = page === 'overview';
  document.getElementById('page-heading').textContent =
    page[0].toUpperCase() + page.slice(1);
  document.querySelectorAll('.nav-link').forEach((link) => {
    const active = link.dataset.page === page;
    link.classList.toggle('active', active);
    if (active) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
  });
  if (page === 'overview') return;

  catalogState.mode = page;
  const isSets = page === 'sets';
  document.getElementById('sets-search-form').hidden = !isSets;
  document.getElementById('parts-search-form').hidden = isSets;
  document.getElementById('catalog-heading').textContent =
    isSets ? 'Browse sets' : 'Browse parts';
  document.getElementById('catalog-load-more').textContent =
    isSets ? 'Load more sets' : 'Load more parts';
  if (changed) loadCatalog(true);
}

document.getElementById('sets-search-form').addEventListener('submit', (event) => {
  event.preventDefault();
  loadCatalog(true);
});
document.getElementById('parts-search-form').addEventListener('submit', (event) => {
  event.preventDefault();
  loadCatalog(true);
});
document.getElementById('catalog-load-more').addEventListener('click', () => {
  loadCatalog(false);
});

document.querySelectorAll('.nav-link').forEach((link) => {
  link.addEventListener('click', (event) => {
    event.preventDefault();
    if (location.hash !== link.hash) location.hash = link.hash;
    else showPage(link.dataset.page);
  });
});

window.addEventListener('hashchange', () => {
  showPage(location.hash.slice(1));
});

loadCatalogSummary();
loadCatalogLookups();
loadBootstrapStatus();
loadAuthStatus();
showPage(location.hash.slice(1) || 'overview');
