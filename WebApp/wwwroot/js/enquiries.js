(function () {
  var rowsBody = document.getElementById('enq-rows');
  var drawer = document.getElementById('enq-drawer');
  if (!rowsBody || !drawer) return;

  var backdrop = document.getElementById('enq-backdrop');
  var els = {
    subject: document.getElementById('d-subject'),
    meta: document.getElementById('d-meta'),
    status: document.getElementById('d-status'),
    resolve: document.getElementById('d-resolve'),
    close: document.getElementById('d-close'),
    error: document.getElementById('d-error'),
    messages: document.getElementById('d-messages'),
    text: document.getElementById('d-text'),
    send: document.getElementById('d-send')
  };
  var tokenInput = document.querySelector('input[name="__RequestVerificationToken"]');
  var search = document.getElementById('enq-search');
  var empty = document.getElementById('enq-empty');
  var pills = document.querySelectorAll('.enq-pill');

  var currentRef = null;
  var currentRow = null;
  var filter = 'all';
  var lastFocus = null;

  // ---------- talking to the server ----------
  function api(url, method, body) {
    var headers = { 'Accept': 'application/json' };
    if (method === 'POST') {
      headers['Content-Type'] = 'application/json';
      headers['RequestVerificationToken'] = tokenInput ? tokenInput.value : '';
    }
    return fetch(url, {
      method: method,
      headers: headers,
      body: body ? JSON.stringify(body) : undefined,
      credentials: 'same-origin'
    }).then(function (res) {
      var type = res.headers.get('content-type') || '';
      if (type.indexOf('application/json') === -1) {
        // Not JSON means the session ended and we were sent to the sign-in page.
        window.location.reload();
        throw new Error('Your session has ended.');
      }
      return res.json().then(function (data) {
        if (!res.ok) throw new Error(data.error || 'Something went wrong. Please try again.');
        return data;
      });
    });
  }

  // ---------- list: filter + search + counts ----------
  function applyFilter() {
    var q = (search.value || '').trim().toLowerCase();
    var shown = 0;
    Array.prototype.forEach.call(rowsBody.querySelectorAll('.enq-row'), function (row) {
      var okStatus = filter === 'all' || row.dataset.status === filter;
      var okText = !q || row.dataset.search.indexOf(q) !== -1;
      row.hidden = !(okStatus && okText);
      if (!row.hidden) shown++;
    });
    if (rowsBody.children.length) empty.textContent = 'No enquiries match.';
    empty.hidden = shown > 0;
  }

  function updateCounts() {
    var c = { all: 0, 'new': 0, in_progress: 0, resolved: 0 };
    Array.prototype.forEach.call(rowsBody.querySelectorAll('.enq-row'), function (row) {
      c.all++;
      c[row.dataset.status] = (c[row.dataset.status] || 0) + 1;
    });
    Object.keys(c).forEach(function (k) {
      var el = document.getElementById('cnt-' + k);
      if (el) el.textContent = c[k];
    });
  }

  pills.forEach(function (p) {
    p.addEventListener('click', function () {
      filter = p.dataset.filter;
      pills.forEach(function (x) { x.classList.toggle('active', x === p); });
      applyFilter();
    });
  });
  search.addEventListener('input', applyFilter);

  function setChip(el, status, label) {
    el.className = 'st st-' + status;
    el.textContent = label;
  }

  // Keep the list row (chip, bold text, counts, filter) in step with the panel.
  function syncRow(t) {
    if (!currentRow) return;
    currentRow.dataset.status = t.status;
    setChip(currentRow.querySelector('.st'), t.status, t.statusLabel);
    updateCounts();
    applyFilter();
  }

  // ---------- slide-in panel ----------
  function showError(msg) {
    els.error.textContent = msg || '';
    els.error.hidden = !msg;
  }

  function render(t) {
    els.subject.textContent = t.subject;
    els.meta.textContent = t.student + (t.email ? ' \u00b7 ' + t.email : '') + ' \u00b7 Ref ' + t.shortRef;
    setChip(els.status, t.status, t.statusLabel);
    els.resolve.hidden = t.status === 'resolved';

    els.messages.textContent = '';
    if (!t.messages.length) {
      var none = document.createElement('div');
      none.className = 'd-loading';
      none.textContent = 'No messages yet.';
      els.messages.appendChild(none);
    }
    t.messages.forEach(function (m) {
      var box = document.createElement('div');
      box.className = 'msg' + (m.fromStaff ? ' staff' : '');
      var who = document.createElement('span');
      who.className = 'who';
      who.textContent = m.sender + ' | ' + m.stamp;
      var body = document.createElement('div');
      body.className = 'body';
      body.textContent = m.text;
      box.appendChild(who);
      box.appendChild(body);
      els.messages.appendChild(box);
    });
    els.messages.scrollTop = els.messages.scrollHeight;
  }

  function openPanel(row) {
    lastFocus = document.activeElement;
    if (currentRow) currentRow.classList.remove('active');
    currentRow = row;
    currentRef = row.dataset.ref;
    row.classList.add('active');

    // Show what the list already knows straight away, then load the messages.
    els.subject.textContent = row.querySelector('.c-subject').textContent;
    els.meta.textContent = row.querySelector('.c-student').textContent;
    setChip(els.status, row.dataset.status, row.querySelector('.st').textContent);
    els.resolve.hidden = row.dataset.status === 'resolved';
    els.messages.textContent = '';
    var loading = document.createElement('div');
    loading.className = 'd-loading';
    loading.textContent = 'Loading messages...';
    els.messages.appendChild(loading);
    els.text.value = '';
    showError('');

    drawer.classList.add('open');
    drawer.setAttribute('aria-hidden', 'false');
    backdrop.hidden = false;
    document.body.classList.add('drawer-open');

    var ref = currentRef;
    api('/Enquiries/Thread/' + ref, 'GET').then(function (t) {
      if (ref !== currentRef) return;
      render(t);
      els.text.focus();
    }).catch(function (e) {
      if (ref !== currentRef) return;
      els.messages.textContent = '';
      showError(e.message);
    });
  }

  function closePanel() {
    drawer.classList.remove('open');
    drawer.setAttribute('aria-hidden', 'true');
    backdrop.hidden = true;
    document.body.classList.remove('drawer-open');
    if (currentRow) currentRow.classList.remove('active');
    currentRow = null;
    currentRef = null;
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }

  function sendReply() {
    var text = els.text.value.trim();
    if (!text || !currentRef) return;
    els.send.disabled = true;
    showError('');
    api('/Enquiries/Reply/' + currentRef, 'POST', { text: text }).then(function (t) {
      els.text.value = '';
      render(t);
      syncRow(t);
    }).catch(function (e) {
      showError(e.message);
    }).then(function () { els.send.disabled = false; });
  }

  function resolveEnquiry() {
    if (!currentRef) return;
    els.resolve.disabled = true;
    showError('');
    api('/Enquiries/Resolve/' + currentRef, 'POST').then(function (t) {
      render(t);
      syncRow(t);
    }).catch(function (e) {
      showError(e.message);
    }).then(function () { els.resolve.disabled = false; });
  }

  rowsBody.addEventListener('click', function (e) {
    var btn = e.target.closest('.enq-open');
    if (btn) openPanel(btn.closest('.enq-row'));
  });
  els.close.addEventListener('click', closePanel);
  backdrop.addEventListener('click', closePanel);
  els.send.addEventListener('click', sendReply);
  els.resolve.addEventListener('click', resolveEnquiry);
  els.text.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); sendReply(); }
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && drawer.classList.contains('open')) closePanel();
  });
})();
