/* Moteur des planches HOTAS interactives (gabarits SVG annotés).
   Extrait de F14BU/mapping-hotas.html le 21/08/2026 pour être réutilisé par
   F4U-1D et F-4E — même matériel physique (manche Alpha Prime, WinWing PTO2),
   donc mêmes gabarits SVG ; seules les données (hotas.json/bindings.json)
   changent d'un avion à l'autre. F14BU garde sa propre copie inline : elle a
   des besoins que celui-ci n'a pas (throttle en planche photo paginée,
   édition/export, onglet clavier) — voir js/mapping-table.js pour l'autre
   variante, plus simple (tableaux seuls, sans gabarit).

   La page appelante fournit tout via window.BOARD_CONFIG avant de charger ce
   script — voir F4U1D/mapping-hotas.html ou F4E/mapping-hotas.html pour un
   exemple. */
(function () {
const CFG = window.BOARD_CONFIG;
if (!CFG) { console.error('svg-board.js: window.BOARD_CONFIG manquant'); return; }

const CAT_COLOR   = {arm:'#b3382c', vol:'#1f5fa8', sens:'#2e7d46', comm:'#8a5a00', misc:'#5c5f66'};
const CAT_COLOR_L = {arm:'#e0705f', vol:'#6aa6e0', sens:'#6fd08c', comm:'#f2a93b', misc:'#8b9aa3'};
const DEV_NAMES   = {stick:'Manche', pto2:'PTO2', throttle:'Manette'};

/* ---------- Étiquettes → placeholders du gabarit ---------- */
function svgExpandKeys(n) {
  if (/^\d+$/.test(n)) return [{key: 'button_' + n, num: n}];
  const range = n.match(/^(\d+)-(\d+)$/);
  if (range) {
    const a = +range[1], b = +range[2], out = [];
    for (let i = a; i <= b; i++) out.push({key: 'button_' + i, num: String(i)});
    return out;
  }
  const axis = {X:'axis_x', Y:'axis_y', rX:'axis_rx', rY:'axis_ry', Z:'axis_z', SLDR:'axis_slider_1'}[n];
  return axis ? [{key: axis, num: null}] : [];
}
const SVG_PH = /^(button_\d+|axis_[a-z0-9_]+|template_name|current_date)$/;

function lessonHref(lesson) { return lesson || null; }

/* ---------- Montage d'un gabarit SVG (manche, PTO2) ---------- */
async function mountSvgDevice(cfg, hotas) {
  const dev = hotas.device.find(d => d.id === cfg.id);
  const labels = dev ? dev.labels : [];
  const byKey = new Map();
  labels.forEach((l, li) => {
    const i = cfg.id + '-' + li;
    svgExpandKeys(l.n).forEach(({key, num}) => {
      byKey.set(key, {...l, i, boardNum: num || l.n});
    });
  });

  const svgText = await fetch(cfg.svg).then(r => { if (!r.ok) throw new Error(cfg.svg + ': ' + r.status); return r.text(); });
  const svg = new DOMParser().parseFromString(svgText, 'image/svg+xml').documentElement;
  const board = document.getElementById('board-' + cfg.id);
  board.textContent = '';
  board.appendChild(document.importNode(svg, true));
  const live = board.querySelector('svg');
  live.removeAttribute('width'); live.removeAttribute('height'); live.removeAttribute('content');

  const META = {template_name: cfg.templateName, current_date: new Date().toLocaleDateString('fr-FR')};
  const walker = document.createTreeWalker(live, NodeFilter.SHOW_TEXT);
  const hits = []; let node;
  while ((node = walker.nextNode())) {
    const k = node.nodeValue.trim().toLowerCase();
    if (SVG_PH.test(k)) hits.push({node, k});
  }
  for (const {node, k} of hits) {
    const el = node.parentElement;
    if (k in META) { el.textContent = META[k]; continue; }
    const lbl = byKey.get(k);
    if (!lbl) { el.textContent = '—'; el.style.opacity = '.35'; continue; }
    if (el.namespaceURI === 'http://www.w3.org/1999/xhtml') {
      el.classList.add('jd-lbl');
      el.dataset.dev = cfg.id; el.dataset.i = lbl.i; el.dataset.cat = lbl.cat;
      const isFree = lbl.text === 'Libre' || lbl.verify === false;
      const bg = isFree ? '#8b9aa3' : CAT_COLOR[lbl.cat];
      el.style.cssText += ';background:' + bg + ';color:#fff;font-family:var(--mono);position:relative;' +
        'font-weight:600;font-size:10px;line-height:1.15;padding:1px 3px;' +
        'border:0.5px solid rgba(255,255,255,.55);' +
        (isFree ? 'font-style:italic;opacity:.75;' : '') +
        'box-shadow:0 0.5px 1.5px rgba(0,0,0,.4);pointer-events:all';
      el.innerHTML = '';
      const row = document.createElement('div');
      row.style.cssText = cfg.wrapWidth
        ? ('white-space:normal;max-width:' + cfg.wrapWidth + 'px;text-align:center')
        : 'white-space:nowrap';
      row.append(lbl.text + ' ');
      const small = document.createElement('small');
      small.style.cssText = 'display:inline-block;font-weight:700;font-size:.82em;background:rgba(0,0,0,.45);border-radius:2px;padding:0 3px;white-space:nowrap';
      small.textContent = lbl.boardNum;
      row.append(small);
      el.append(row);
    } else {
      el.textContent = lbl.text;
    }
  }

  const tbody = document.querySelector('#dtbl-' + cfg.id + ' tbody');
  for (const [, l] of byKey) {
    const c = CAT_COLOR_L[l.cat];
    const tr = document.createElement('tr'); tr.dataset.cat = l.cat;
    tr.dataset.dev = cfg.id; tr.dataset.i = l.i; tr.dataset.n = l.n; tr.style.setProperty('--c', c);
    const href = lessonHref(l.lesson);
    tr.innerHTML = `<td class="c1"><span class="num-badge" style="--c:${c}">${l.boardNum}</span></td>
      <td class="c2"><b>${l.text}</b><span>${l.boardNum}</span></td>
      <td class="c3">${l.detail || '—'}</td>
      <td>${href ? `<a class="lec-link" href="${href}">Leçon</a>` : '—'}</td>`;
    tbody.appendChild(tr);
  }
  fitBoards();
}

/* ---------- Manette : tableau simple, pas de gabarit (peu de contacts) ---------- */
function renderThrottleTable(bindings) {
  const tbody = document.querySelector('#dtbl-throttle tbody');
  if (!tbody) return;
  const rows = (bindings.bindings || []).filter(b => b.device === 'throttle');
  rows.forEach((b, i) => {
    const tr = document.createElement('tr');
    tr.dataset.dev = 'throttle'; tr.dataset.i = 'throttle-' + i; tr.dataset.n = b.n;
    tr.style.setProperty('--c', '#8b9aa3');
    const cmd = (b.commands || []).join(', ') || 'non assigné';
    const key = /^\d+$/.test(b.n) ? 'B' + b.n : b.n;
    tr.innerHTML = `<td class="c1"><span class="num-badge" style="--c:#8b9aa3">${key}</span></td>
      <td class="c2"><b>${cmd}</b><span>${key}</span></td>
      <td class="c3">${b.axis ? 'Axe' : 'Bouton'}${b.status === 'check' ? ' — à valider' : ''}</td>
      <td>—</td>`;
    tbody.appendChild(tr);
  });
  const count = document.getElementById('throttle-count');
  if (count) count.textContent = rows.length + (rows.length > 1 ? ' contacts' : ' contact');
}

/* ---------- Épinglage : voir F14BU/mapping-hotas.html pour l'explication
   complète (container-type:inline-size interdit un dimensionnement en
   fit-content, donc la largeur est calculée ici en JS à partir du ratio
   du gabarit, pas en CSS). .board-pin s'ancre sous .toolbar, pas à top:0
   comme elle, sans quoi les deux se disputent la même bande de l'écran. */
const MAX_VH = .8, MIN_BOARD_W = 340;
function toolbarH() {
  const t = document.querySelector('.toolbar');
  return t ? Math.ceil(t.getBoundingClientRect().height) : 0;
}
function boardRatio(b) {
  const svg = b.querySelector('svg');
  if (svg) {
    const vb = (svg.getAttribute('viewBox') || '').trim().split(/\s+/).map(Number);
    return (vb.length === 4 && vb[2] > 0 && vb[3] > 0) ? vb[2] / vb[3] : null;
  }
  return null;
}
function fitBoards() {
  const th = toolbarH();
  const hMax = Math.round((innerHeight - th) * MAX_VH);
  document.querySelectorAll('.board').forEach(b => {
    const pin = b.parentElement;
    if (!pin.classList.contains('board-pin')) return;
    pin.style.top = th + 'px';
    b.style.width = '';
    pin.classList.remove('nopin');
    const ratio = boardRatio(b);
    if (!ratio) { if (b.getBoundingClientRect().height > hMax) pin.classList.add('nopin'); return; }
    const naturalH = b.getBoundingClientRect().width / ratio;
    if (naturalH <= hMax) return;
    const fitW = Math.round(hMax * ratio);
    if (fitW < MIN_BOARD_W) { pin.classList.add('nopin'); return; }
    b.style.width = fitW + 'px';
  });
}
document.querySelectorAll('.board').forEach(b => {
  const w = document.createElement('div');
  w.className = 'board-pin';
  b.parentNode.insertBefore(w, b);
  w.appendChild(b);
});
addEventListener('resize', fitBoards);

/* ---------- Survol : étiquette ↔ ligne de tableau ---------- */
let hov = null;
function mark(dev, i, on) {
  document.querySelectorAll('#board-' + dev + ' .jd-lbl[data-i="' + i + '"]').forEach(l => l.classList.toggle('hl', on));
  document.querySelectorAll('#dtbl-' + dev + ' tbody tr[data-i="' + i + '"]').forEach(r => r.classList.toggle('hl', on));
}
function setHov(dev, i) {
  const k = dev == null ? null : dev + '|' + i;
  if (k === hov) return;
  if (hov) { const p = hov.split('|'); mark(p[0], p[1], false); }
  hov = k;
  if (k) mark(dev, i, true);
}
function targetOf(e) {
  return e.target instanceof Element ? e.target.closest('tr[data-i],.jd-lbl[data-i]') : null;
}
document.addEventListener('mouseover', e => {
  const t = targetOf(e);
  if (!t) { setHov(null); return; }
  setHov(t.dataset.dev, t.dataset.i);
});
document.addEventListener('click', e => {
  const t = targetOf(e);
  if (!t) { setHov(null); return; }
  if (hov === t.dataset.dev + '|' + t.dataset.i) setHov(null); else setHov(t.dataset.dev, t.dataset.i);
});

/* ---------- Onglets ---------- */
document.querySelectorAll('.tab').forEach(t => t.addEventListener('click', () => {
  document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
  t.classList.add('active');
  document.querySelectorAll('section.device').forEach(s => s.classList.remove('visible'));
  document.getElementById('dev-' + t.dataset.dev).classList.add('visible');
  fitBoards();
}));

/* ---------- Filtres ---------- */
const act = new Set(Object.keys(CAT_COLOR));
document.querySelectorAll('.chip').forEach(ch => ch.addEventListener('click', () => {
  const c = ch.dataset.cat;
  if (act.has(c)) { act.delete(c); ch.classList.add('off'); } else { act.add(c); ch.classList.remove('off'); }
  document.querySelectorAll('.jd-lbl').forEach(l => l.classList.toggle('dim', !act.has(l.dataset.cat)));
  document.querySelectorAll('.dtable tr[data-cat]').forEach(tr => tr.classList.toggle('hidden', !act.has(tr.dataset.cat)));
}));

/* ---------- Recherche globale ---------- */
let searchIndex = [];
let bindingsIndex = new Map();
function loadBindingsIndex() {
  return fetch(CFG.bindingsUrl).then(r => r.ok ? r.json() : null).then(data => {
    if (!data) return null;
    (data.bindings || []).forEach(b => bindingsIndex.set(b.device + '|' + b.n, (b.commands || []).join(' ')));
    return data;
  }).catch(() => null);
}
function refreshSearchIndex() {
  searchIndex = [...document.querySelectorAll('.dtable tbody tr[data-dev]')].map(tr => {
    const c1 = tr.querySelector('.c1'), c2 = tr.querySelector('.c2'), c3 = tr.querySelector('.c3');
    const cmds = bindingsIndex.get(tr.dataset.dev + '|' + (tr.dataset.n || '')) || '';
    return {
      dev: tr.dataset.dev, i: tr.dataset.i,
      num: c1 ? c1.textContent.trim() : '', name: c2 ? c2.textContent.trim() : '',
      detail: c3 ? c3.textContent.trim() : '', commands: cmds,
    };
  });
}
function normSearch(s) { return s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, ''); }

const searchInput = document.getElementById('cmd-search');
const searchResultsEl = document.getElementById('search-results');

function renderSearchResults(matches) {
  searchResultsEl.innerHTML = '';
  if (!matches.length) {
    searchResultsEl.innerHTML = '<div class="sr-empty">Aucune commande trouvée</div>';
    searchResultsEl.classList.add('open');
    return;
  }
  matches.slice(0, 30).forEach((m, idx) => {
    const el = document.createElement('div');
    el.className = 'sr-item' + (idx === 0 ? ' sel' : '');
    el.innerHTML = `<span class="sr-dev">${DEV_NAMES[m.dev] || m.dev}</span><span class="sr-name">${m.name}</span><span class="sr-num">${m.num}</span>`;
    el.addEventListener('click', () => goToSearchResult(m));
    searchResultsEl.appendChild(el);
  });
  searchResultsEl.classList.add('open');
}
function doSearch() {
  const q = normSearch(searchInput.value.trim());
  if (!q) { searchResultsEl.classList.remove('open'); return; }
  const matches = searchIndex.filter(m =>
    normSearch(m.name).includes(q) || normSearch(m.detail).includes(q) || normSearch(m.commands).includes(q));
  renderSearchResults(matches);
}
searchInput.addEventListener('input', doSearch);
searchInput.addEventListener('focus', () => { if (searchInput.value.trim()) doSearch(); });

function goToSearchResult(m) {
  searchResultsEl.classList.remove('open');
  searchInput.value = '';
  document.querySelector('.tab[data-dev="' + m.dev + '"]')?.click();
  setTimeout(() => {
    document.querySelectorAll('.search-hit').forEach(e => e.classList.remove('search-hit'));
    const tr = document.querySelector('#dtbl-' + m.dev + ' tbody tr[data-i="' + m.i + '"]');
    const lbls = document.querySelectorAll('#board-' + m.dev + ' .jd-lbl[data-i="' + m.i + '"]');
    (tr || lbls[0])?.scrollIntoView({behavior: 'smooth', block: 'center'});
    if (tr) tr.classList.add('search-hit');
    lbls.forEach(l => l.classList.add('search-hit'));
    setTimeout(() => {
      if (tr) tr.classList.remove('search-hit');
      lbls.forEach(l => l.classList.remove('search-hit'));
    }, 3000);
  }, 80);
}
document.addEventListener('keydown', e => {
  if (!searchResultsEl.classList.contains('open')) return;
  if (e.key === 'Escape') { searchResultsEl.classList.remove('open'); searchInput.blur(); }
  else if (e.key === 'Enter') { e.preventDefault(); searchResultsEl.querySelector('.sr-item')?.click(); }
});
document.addEventListener('click', e => { if (!e.target.closest('.search-wrap')) searchResultsEl.classList.remove('open'); });

/* ---------- Lien profond ?dev=pto2&n=38 ---------- */
function findBindRow(dev, n) {
  const rows = [...document.querySelectorAll('#dtbl-' + dev + ' tbody tr[data-n]')];
  let tr = rows.find(r => r.dataset.n === String(n));
  if (tr) return tr;
  const num = parseInt(n, 10);
  if (!isNaN(num)) {
    tr = rows.find(r => { const m = r.dataset.n.match(/^(\d+)-(\d+)$/); return m && num >= +m[1] && num <= +m[2]; });
  }
  return tr;
}
function gotoDevNum(dev, n) {
  document.querySelector('.tab[data-dev="' + dev + '"]')?.click();
  setTimeout(() => {
    const tr = findBindRow(dev, n);
    const i = tr ? tr.dataset.i : null;
    const lbls = i != null ? document.querySelectorAll('#board-' + dev + ' .jd-lbl[data-i="' + i + '"]') : [];
    (tr || lbls[0])?.scrollIntoView({behavior: 'smooth', block: 'center'});
    if (tr) tr.classList.add('search-hit');
    lbls.forEach(l => l.classList.add('search-hit'));
    setTimeout(() => {
      if (tr) tr.classList.remove('search-hit');
      lbls.forEach(l => l.classList.remove('search-hit'));
    }, 3000);
  }, 80);
}
function handleDeepLink() {
  const p = new URLSearchParams(location.search);
  const dev = p.get('dev'), n = p.get('n');
  if (dev && n != null) gotoDevNum(dev, n);
}

/* ---------- Chargement ---------- */
const pBind = loadBindingsIndex().then(data => { if (data) renderThrottleTable(data); return data; });
const pHotas = fetch(CFG.hotasUrl).then(r => { if (!r.ok) throw new Error(CFG.hotasUrl + ': ' + r.status); return r.json(); })
  .then(hotas => Promise.all(CFG.svgDevices.map(cfg => mountSvgDevice(cfg, hotas).catch(err => {
    const b = document.getElementById('board-' + cfg.id);
    if (b) b.innerHTML = '<div class="board-loading" style="color:#c0392b">Erreur de chargement : ' + err.message +
      ' — cette page doit être servie en HTTP (voir tools/serve.ps1 ou Lancer le site.bat), pas ouverte en file://.</div>';
  }))))
  .catch(err => {
    document.querySelectorAll('.board').forEach(b => {
      b.innerHTML = '<div class="board-loading" style="color:#c0392b">Erreur de chargement des données : ' + err.message + '</div>';
    });
  });

Promise.all([pBind, pHotas]).then(() => { refreshSearchIndex(); handleDeepLink(); });
})();
