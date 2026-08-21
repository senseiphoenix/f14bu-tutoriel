/* Moteur des pages « Mapping HOTAS » tabulaires (F4U-1D, F-4E).

   Le F-14B(U) a sa propre page, bâtie sur des gabarits SVG annotés : chaque
   étiquette y est positionnée à la main sur une planche. Tant que ces
   coordonnées n'existent pas pour les deux autres avions, cette page rend la
   même donnée — data/<avion>-bindings.json, la seule source — sous forme de
   tableaux cherchables. Le contenu est donc déjà juste ; seule la mise en
   planche reste à faire, et se greffera sur le même fichier de données.

   La page appelante fournit tout par attributs sur <body> :
     data-bindings : chemin du JSON
     data-devices  : JSON [{id, label, sub}] — ordre et libellés des onglets */

(function () {
  const BINDINGS_URL = document.body.dataset.bindings || '';
  const DEVICES = JSON.parse(document.body.dataset.devices || '[]');

  const STATUS_LABEL = { ok: 'confirmé', check: 'à valider', none: 'libre' };

  const root = document.getElementById('mapping-root');
  const search = document.getElementById('cmd-search');
  if (!root) return;

  /* Un axe se désigne par sa lettre (X, Y, Z, SLDR…), un bouton par son
     numéro ou une plage « 5-7 ». On affiche la clé DCS réelle plutôt que le
     repère brut : c'est ce que le joueur relit dans l'écran Contrôles. */
  const AXIS_KEYS = { X: 'JOY_X', Y: 'JOY_Y', Z: 'JOY_Z', RX: 'JOY_RX', RY: 'JOY_RY', RZ: 'JOY_RZ' };
  function dcsKey(n) {
    const up = String(n).toUpperCase();
    if (AXIS_KEYS[up]) return AXIS_KEYS[up];
    if (up === 'SLDR') return 'JOY_SLIDER1';
    if (/^\d+$/.test(n)) return 'JOY_BTN' + n;
    const range = String(n).match(/^(\d+)-(\d+)$/);
    if (range) return 'JOY_BTN' + range[1] + '…' + range[2];
    return '';
  }

  function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  function renderDevice(device, rows) {
    const section = el('section', 'dev-block');
    section.dataset.dev = device.id;

    const head = el('div', 'dev-head');
    head.appendChild(el('span', 'dev-name', device.label));
    head.appendChild(el('span', 'dev-sub', device.sub || ''));
    head.appendChild(el('span', 'dev-count', rows.length + (rows.length > 1 ? ' contacts' : ' contact')));
    section.appendChild(head);

    if (!rows.length) {
      section.appendChild(el('p', 'dev-empty', 'Aucune assignation relevée sur ce périphérique.'));
      return section;
    }

    const table = el('table', 'maptbl');
    table.innerHTML =
      '<thead><tr><th>Repère</th><th>Touche DCS</th><th>Commande</th><th>État</th></tr></thead>';
    const tbody = el('tbody');

    rows.forEach(function (b) {
      const tr = el('tr');
      tr.dataset.status = b.status || 'none';
      /* Sert au filtre de recherche : tout le texte utile en minuscules. */
      tr.dataset.hay = [b.n, dcsKey(b.n), (b.commands || []).join(' '), b.note || '']
        .join(' ').toLowerCase();

      tr.appendChild(el('td', 'c-n', b.n));
      tr.appendChild(el('td', 'c-key', dcsKey(b.n)));

      const cmd = el('td', 'c-cmd');
      if ((b.commands || []).length) {
        b.commands.forEach(function (name) { cmd.appendChild(el('b', null, name)); });
      } else {
        cmd.appendChild(el('i', null, 'non assigné'));
      }
      if (b.note) cmd.appendChild(el('small', null, b.note));
      tr.appendChild(cmd);

      const st = el('td', 'c-st');
      st.appendChild(el('span', 'badge st-' + (b.status || 'none'),
        STATUS_LABEL[b.status] || b.status || '—'));
      if (b.axis) st.appendChild(el('span', 'badge st-axis', 'axe'));
      tr.appendChild(st);

      tbody.appendChild(tr);
    });

    table.appendChild(tbody);
    section.appendChild(table);
    return section;
  }

  /* Les repères sont des chaînes (« 5 », « 17-22 », « SLDR », « rX ») : un tri
     alphabétique mettrait « 10 » avant « 5 » et noierait les axes principaux
     entre le mini-stick et la gâchette. On trie donc les boutons par numéro,
     puis les axes dans l'ordre où on les manipule : les trois axes de vol,
     la gâchette de frein, enfin le mini-stick. */
  const AXIS_ORDER = ['X', 'Y', 'Z', 'SLDR', 'RX', 'RY', 'RZ'];
  function axisRank(n) {
    const i = AXIS_ORDER.indexOf(String(n).toUpperCase());
    return i < 0 ? AXIS_ORDER.length : i;
  }
  function sortRows(a, b) {
    const na = parseInt(a.n, 10), nb = parseInt(b.n, 10);
    const aNum = !isNaN(na), bNum = !isNaN(nb);
    if (aNum && bNum) return na - nb;
    if (aNum) return -1;          // les boutons d'abord
    if (bNum) return 1;
    const ra = axisRank(a.n), rb = axisRank(b.n);
    if (ra !== rb) return ra - rb;
    return String(a.n).localeCompare(String(b.n));
  }

  function applyFilter() {
    const q = (search && search.value || '').trim().toLowerCase();
    let shown = 0;
    root.querySelectorAll('tbody tr').forEach(function (tr) {
      const hit = !q || tr.dataset.hay.indexOf(q) >= 0;
      tr.hidden = !hit;
      if (hit) shown++;
    });
    root.querySelectorAll('.dev-block').forEach(function (sec) {
      const any = sec.querySelector('tbody tr:not([hidden])');
      sec.hidden = !any;
    });
    const empty = document.getElementById('no-hit');
    if (empty) empty.hidden = shown > 0;
  }

  fetch(BINDINGS_URL)
    .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
    .then(function (data) {
      root.textContent = '';
      const all = data.bindings || [];
      DEVICES.forEach(function (device) {
        const rows = all.filter(function (b) { return b.device === device.id; }).sort(sortRows);
        root.appendChild(renderDevice(device, rows));
      });
      const total = all.length;
      const counter = document.getElementById('bind-count');
      if (counter) {
        counter.textContent = total + ' contacts documentés · ' +
          all.filter(function (b) { return b.status === 'ok'; }).length + ' confirmés en jeu';
      }
      if (search) search.addEventListener('input', applyFilter);
    })
    .catch(function (err) {
      root.textContent = '';
      const box = el('div', 'note warn');
      box.appendChild(el('b', null, 'Données non chargées'));
      box.appendChild(document.createTextNode(
        'Impossible de lire ' + BINDINGS_URL + ' (' + err.message + '). ' +
        'Cette page lit un fichier JSON : ouverte directement depuis le disque ' +
        '(file://), le navigateur bloque la lecture. Passer par le serveur local ' +
        '(tools/serve.ps1) ou par le site publié.'));
      root.appendChild(box);
    });
})();
