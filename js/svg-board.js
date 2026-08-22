/* Moteur des planches HOTAS interactives, partagé par F4U-1D et F-4E.

   Extrait de F14BU/mapping-hotas.html : c'est le même matériel physique sur
   les trois avions, donc les mêmes gabarits (manche et PTO2 en SVG annoté,
   throttle en photo + coordonnées x/y) — seules les données changent, dans
   data/<avion>-hotas.json. Le F14BU garde sa propre copie inline parce qu'il
   a des besoins que ces deux-là n'ont pas : rotacteur MODE paginé sur le
   throttle, mode édition/export des étiquettes, onglet clavier.

   La page appelante fournit tout via window.BOARD_CONFIG avant de charger ce
   script — voir F4U1D/mapping-hotas.html ou F4E/mapping-hotas.html. */
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
      <td class="c4">${l.cmd || '—'}</td>
      <td>${href ? `<a class="lec-link" href="${href}">Leçon</a>` : '—'}</td>`;
    tbody.appendChild(tr);
  }
  fitBoards();
}

/* ---------- Manette : planche PHOTO + étiquettes positionnées en % ----------
   Contrairement au manche et au PTO2 (gabarits SVG qui portent eux-mêmes la
   position de chaque bouton), la manette est une photo : les coordonnées x/y
   viennent donc des données, comme sur le F-14B(U) dont elles sont reprises —
   c'est le même matériel, les repères sont aux mêmes endroits. */
/* Rotacteur de pages Virpil : les six boutons B1-B6 (repères 38-43 sur la
   planche) émettent une plage de numéros DirectInput différente selon la
   position du dial — c'est le firmware qui le fait, pas DCS. Les cinq pages
   sont donc affichées EN PERMANENCE dans chaque boîte : une boîte qui
   grandirait au clic chevaucherait ses voisines sur une planche aussi dense.
   Cliquer une position met juste la page en évidence. */
const PAGE_ORDER = ['OFF', 'M1', 'M2', 'M3', 'M4'];
const PAGE_COLOR = {OFF:'#9aa4ab', M1:'#3b6fd1', M2:'#2f8f57', M3:'#c0392b', M4:'#d1a92e'};
const PAGE_NAME  = {OFF:'Blanc', M1:'Bleu', M2:'Vert', M3:'Rouge', M4:'Jaune'};
let activePage = 'OFF';

function setPage(dev, page, pages) {
  activePage = page;
  const board = document.getElementById('board-' + dev);
  board.querySelectorAll('.pgrow').forEach(r => r.classList.toggle('active', r.dataset.pg === page));
  document.querySelectorAll('#dtbl-' + dev + ' tbody tr[data-pg]').forEach(tr =>
    tr.classList.toggle('pgsel-row', tr.dataset.pg === page));
  PAGE_ORDER.forEach(p => {
    const sel = board.querySelector('.lbl[data-n="' + p + '"]');
    if (sel) sel.classList.toggle('active', p === page);
  });
  const note = document.getElementById('pgnote-' + dev);
  if (note && pages) {
    note.style.setProperty('--pgc', PAGE_COLOR[page]);
    const reals = Object.values(pages[page] || {}).map(f => f.real).filter(Number.isFinite);
    const range = reals.length ? ' (boutons ' + Math.min(...reals) + '-' + Math.max(...reals) + ')' : '';
    note.innerHTML = '<b>Rotacteur MODE — page ' + PAGE_NAME[page] + range + '.</b> ' +
      (pages[page] && pages[page].theme || '') +
      ' Les cinq pages restent affichées dans chaque boîte B1-B6 : cliquer une pastille met celle-ci en évidence. ' +
      'Ce sont les six mêmes boutons physiques, mais chaque page leur fait émettre une autre plage de numéros.';
  }
}

function mountPhotoDevice(cfg, hotas) {
  const dev = hotas.device.find(d => d.id === cfg.id);
  if (!dev) return;
  const board = document.getElementById('board-' + cfg.id);
  if (!board) return;
  const pages = dev.pages || null;
  board.textContent = '';
  const img = document.createElement('img');
  img.src = cfg.img;
  img.alt = cfg.templateName;
  img.addEventListener('load', fitBoards, {once: true});
  board.appendChild(img);

  const tbody = document.querySelector('#dtbl-' + cfg.id + ' tbody');
  dev.labels.forEach((l, li) => {
    const i = cfg.id + '-' + li;
    const paged = pages && pages.OFF && pages.OFF[l.n];   // B1-B6
    const isSel = pages && PAGE_ORDER.includes(l.n);      // la position du dial
    const isFree = !l.cmd && !paged;
    const c = CAT_COLOR[l.cat];

    const el = document.createElement('div');
    el.className = 'lbl' + (l.sm ? ' sm' : '') + (paged ? ' pgstack' : '') + (isSel ? ' pgsel' : '');
    el.style.setProperty('--c', isFree ? '#8b9aa3' : c);
    if (isSel) el.style.setProperty('--pgc', PAGE_COLOR[l.n]);
    el.style.left = l.x + '%'; el.style.top = l.y + '%';
    if (l.bw && !paged) { el.style.width = l.bw + '%'; el.style.maxWidth = 'none'; }
    if (isFree) el.style.fontStyle = 'italic';
    el.dataset.cat = l.cat; el.dataset.dev = cfg.id; el.dataset.i = i; el.dataset.n = l.n;

    if (paged) {
      el.innerHTML = PAGE_ORDER.map(p => {
        const f = pages[p][l.n] || {};
        return '<div class="pgrow" data-pg="' + p + '" style="--pc:' + PAGE_COLOR[p] + '" title="' + PAGE_NAME[p] + '">' +
          '<span class="dot"></span><span class="rtxt">' + (f.s || '—') + '</span>' +
          '<span class="rnum">' + (f.real != null ? f.real : '') + '</span></div>';
      }).join('');
    } else {
      el.innerHTML = l.text + '<small>' + l.n + '</small>';
    }
    if (isSel) el.addEventListener('click', ev => { ev.stopPropagation(); setPage(cfg.id, l.n, pages); });
    board.appendChild(el);

    if (!tbody) return;
    const cl = CAT_COLOR_L[l.cat];
    const href = lessonHref(l.lesson);
    if (paged) {
      // une ligne par page : le tableau dit ce que fait B1-B6 dans chaque position
      PAGE_ORDER.forEach(p => {
        const f = pages[p][l.n] || {};
        const tr = document.createElement('tr');
        tr.dataset.cat = l.cat; tr.dataset.dev = cfg.id; tr.dataset.i = i;
        tr.dataset.n = String(f.real != null ? f.real : l.n); tr.dataset.pg = p;
        tr.style.setProperty('--c', PAGE_COLOR[p]);
        tr.innerHTML = '<td class="c1"><span class="num-badge" style="--c:' + PAGE_COLOR[p] + '">' +
            (f.real != null ? f.real : l.n) + '</span></td>' +
          '<td class="c2"><b>' + (f.s || '—') + '</b><span>Repère ' + l.n + ' · Page ' + PAGE_NAME[p] + '</span></td>' +
          '<td class="c3">' + (f.f || '—') + '</td>' +
          '<td class="c4">' + (f.cmd || '—') + '</td>' +
          '<td>' + (f.lesson ? '<a class="lec-link" href="' + f.lesson + '">Leçon</a>' : '—') + '</td>';
        tbody.appendChild(tr);
      });
      return;
    }
    const tr = document.createElement('tr');
    tr.dataset.cat = l.cat; tr.dataset.dev = cfg.id; tr.dataset.i = i; tr.dataset.n = l.n;
    tr.style.setProperty('--c', cl);
    tr.innerHTML = `<td class="c1"><span class="num-badge" style="--c:${cl}">${l.n}</span></td>
      <td class="c2"><b>${l.text}</b><span>${l.n}</span></td>
      <td class="c3">${l.detail || '—'}</td>
      <td class="c4">${l.cmd || '—'}</td>
      <td>${href ? `<a class="lec-link" href="${href}">Leçon</a>` : '—'}</td>`;
    tbody.appendChild(tr);
  });
  if (pages) setPage(cfg.id, 'OFF', pages);
  fitBoards();
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
  const img = b.querySelector('img');
  return (img && img.naturalWidth && img.naturalHeight) ? img.naturalWidth / img.naturalHeight : null;
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
  const btn = document.createElement('button');
  btn.className = 'board-toggle';
  btn.textContent = 'Masquer la planche';
  btn.addEventListener('click', () => {
    const hidden = w.classList.toggle('collapsed');
    btn.textContent = hidden ? 'Afficher la planche' : 'Masquer la planche';
  });
  w.parentNode.insertBefore(btn, w);
});
addEventListener('resize', fitBoards);

/* ---------- Survol : étiquette ↔ ligne de tableau ---------- */
let hov = null;
function mark(dev, i, on) {
  document.querySelectorAll('#board-' + dev + ' .jd-lbl[data-i="' + i + '"], #board-' + dev + ' .lbl[data-i="' + i + '"]')
    .forEach(l => l.classList.toggle('hl', on));
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
  return e.target instanceof Element ? e.target.closest('tr[data-i],.jd-lbl[data-i],.lbl[data-i]') : null;
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
  document.querySelectorAll('.jd-lbl,.lbl').forEach(l => l.classList.toggle('dim', !act.has(l.dataset.cat)));
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
    const lbls = document.querySelectorAll('#board-' + m.dev + ' .jd-lbl[data-i="' + m.i + '"], #board-' + m.dev + ' .lbl[data-i="' + m.i + '"]');
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
    const lbls = i != null ? document.querySelectorAll('#board-' + dev + ' .jd-lbl[data-i="' + i + '"], #board-' + dev + ' .lbl[data-i="' + i + '"]') : [];
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
const pBind = loadBindingsIndex();
const pHotas = fetch(CFG.hotasUrl).then(r => { if (!r.ok) throw new Error(CFG.hotasUrl + ': ' + r.status); return r.json(); })
  .then(hotas => {
    (CFG.photoDevices || []).forEach(cfg => mountPhotoDevice(cfg, hotas));
    return Promise.all(CFG.svgDevices.map(cfg => mountSvgDevice(cfg, hotas).catch(err => {
      const b = document.getElementById('board-' + cfg.id);
      if (b) b.innerHTML = '<div class="board-loading" style="color:#c0392b">Erreur de chargement : ' + err.message +
        ' — cette page doit être servie en HTTP (voir tools/serve.ps1 ou Lancer le site.bat), pas ouverte en file://.</div>';
    })));
  })
  .catch(err => {
    document.querySelectorAll('.board').forEach(b => {
      b.innerHTML = '<div class="board-loading" style="color:#c0392b">Erreur de chargement des données : ' + err.message + '</div>';
    });
  });

Promise.all([pBind, pHotas]).then(() => { refreshSearchIndex(); handleDeepLink(); });
})();
