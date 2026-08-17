/* Recherche globale du site — bouton flottant + overlay, injectés en JS
   pour ne toucher qu'une seule ligne <script> par page HTML.
   Charge data/search-index.json (généré par tools/build-search-index.py)
   et cherche dans les pages, les leçons et les fonctions HOTAS des
   différents avions.

   Quand un même intitulé de leçon ou de fonction existe sur plusieurs
   avions (ex. "Tour du cockpit" sur F-14B(U) et F4U-1D), le résultat
   affiche "<Avion> — <Sujet>" au lieu du seul sujet, pour lever
   l'ambiguïté. */
(function(){
  "use strict";

  var thisScript = document.currentScript;
  var SITE_ROOT = thisScript ? thisScript.src.replace(/js\/site-search\.js(\?.*)?$/, "") : "";

  var TYPE_LABEL = {page:"Page", "leçon":"Leçon", "fonction":"Fonction"};

  var index = null;         // tableau brut chargé depuis search-index.json
  var ambiguous = null;     // Set de "type|titre normalisé" présents sur >1 avion
  var loadPromise = null;

  function normalize(s){
    return String(s||"").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g,"");
  }

  function load(){
    if(loadPromise) return loadPromise;
    loadPromise = fetch(SITE_ROOT + "data/search-index.json")
      .then(function(r){ return r.json(); })
      .then(function(data){
        index = data;
        ambiguous = new Set();
        var seen = new Map();
        data.forEach(function(e){
          var key = e.type + "|" + normalize(e.title);
          var aircrafts = seen.get(key) || new Set();
          if(e.aircraft) aircrafts.add(e.aircraft);
          seen.set(key, aircrafts);
        });
        seen.forEach(function(aircrafts, key){
          if(aircrafts.size > 1) ambiguous.add(key);
        });
        return data;
      })
      .catch(function(err){
        index = [];
        ambiguous = new Set();
        console.error("Recherche globale : impossible de charger l'index —", err);
        return [];
      });
    return loadPromise;
  }

  function score(entry, qNorm){
    var t = normalize(entry.title);
    if(t === qNorm) return 0;
    if(t.indexOf(qNorm) === 0) return 1;
    if(t.indexOf(qNorm) !== -1) return 2;
    if(normalize(entry.aircraft).indexOf(qNorm) !== -1) return 3;
    return -1;
  }

  function search(q){
    var qNorm = normalize(q.trim());
    if(!qNorm || !index) return [];
    var scored = [];
    for(var i=0;i<index.length;i++){
      var s = score(index[i], qNorm);
      if(s >= 0) scored.push({entry:index[i], s:s});
    }
    scored.sort(function(a,b){ return a.s - b.s; });
    return scored.slice(0, 40).map(function(x){ return x.entry; });
  }

  function labelFor(entry){
    var key = entry.type + "|" + normalize(entry.title);
    if(entry.aircraft && ambiguous.has(key)){
      return entry.aircraft + " — " + entry.title;
    }
    return entry.title;
  }

  // ---------- UI ----------
  var btn = document.createElement("button");
  btn.type = "button";
  btn.className = "gsearch-btn";
  btn.setAttribute("aria-label","Recherche globale du site");
  btn.title = "Recherche globale (touche /)";
  btn.innerHTML = '<svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="M20 20 16 16"/></svg>';

  var overlay = document.createElement("div");
  overlay.className = "gsearch-overlay";
  overlay.hidden = true;
  overlay.innerHTML =
    '<div class="gsearch-panel" role="dialog" aria-label="Recherche globale">' +
      '<div class="gsearch-input-row">' +
        '<svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="M20 20 16 16"/></svg>' +
        '<input class="gsearch-input" type="search" placeholder="Rechercher une page, une leçon, une fonction HOTAS…" autocomplete="off">' +
        '<span class="gsearch-esc">Échap</span>' +
      '</div>' +
      '<div class="gsearch-results"></div>' +
    '</div>';

  document.addEventListener("DOMContentLoaded", mount);
  if(document.readyState === "interactive" || document.readyState === "complete") mount();

  function mount(){
    if(document.body.contains(btn)) return;
    document.body.appendChild(btn);
    document.body.appendChild(overlay);
  }

  var input = overlay.querySelector(".gsearch-input");
  var resultsEl = overlay.querySelector(".gsearch-results");
  var selIdx = -1;
  var currentResults = [];
  var debounceTimer = null;

  function openOverlay(){
    overlay.hidden = false;
    load().then(function(){
      input.focus();
      renderResults(search(input.value));
    });
  }
  function closeOverlay(){
    overlay.hidden = true;
    input.value = "";
    resultsEl.innerHTML = "";
    selIdx = -1;
  }

  function renderResults(list){
    currentResults = list;
    selIdx = list.length ? 0 : -1;
    if(!input.value.trim()){
      resultsEl.innerHTML = '<div class="gsearch-hint">Tape au moins deux lettres — pages, leçons et fonctions HOTAS de tous les avions.</div>';
      return;
    }
    if(!list.length){
      resultsEl.innerHTML = '<div class="gsearch-empty">Aucun résultat</div>';
      return;
    }
    resultsEl.innerHTML = "";
    list.forEach(function(entry, i){
      var a = document.createElement("a");
      a.className = "gsearch-item" + (i===0 ? " sel" : "");
      a.href = SITE_ROOT + entry.path;
      a.innerHTML =
        '<span class="gsearch-type">' + (TYPE_LABEL[entry.type]||entry.type) + '</span>' +
        '<span class="gsearch-label"></span>' +
        '<span class="gsearch-aircraft"></span>';
      a.querySelector(".gsearch-label").textContent = labelFor(entry);
      a.querySelector(".gsearch-aircraft").textContent = entry.aircraft || "";
      a.addEventListener("mouseenter", function(){ setSel(i); });
      resultsEl.appendChild(a);
    });
  }

  function setSel(i){
    var items = resultsEl.querySelectorAll(".gsearch-item");
    items.forEach(function(el){ el.classList.remove("sel"); });
    if(items[i]){ items[i].classList.add("sel"); items[i].scrollIntoView({block:"nearest"}); }
    selIdx = i;
  }

  btn.addEventListener("click", openOverlay);
  overlay.addEventListener("click", function(e){ if(e.target === overlay) closeOverlay(); });

  input.addEventListener("input", function(){
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(function(){ renderResults(search(input.value)); }, 100);
  });

  overlay.addEventListener("keydown", function(e){
    if(e.key === "Escape"){ closeOverlay(); return; }
    if(e.key === "ArrowDown"){ e.preventDefault(); if(currentResults.length) setSel(Math.min(selIdx+1, currentResults.length-1)); return; }
    if(e.key === "ArrowUp"){ e.preventDefault(); if(currentResults.length) setSel(Math.max(selIdx-1, 0)); return; }
    if(e.key === "Enter"){
      var items = resultsEl.querySelectorAll(".gsearch-item");
      if(items[selIdx]) items[selIdx].click();
    }
  });

  document.addEventListener("keydown", function(e){
    if(overlay.hidden && e.key === "/" ){
      var tag = (e.target && e.target.tagName || "").toLowerCase();
      var editable = tag === "input" || tag === "textarea" || (e.target && e.target.isContentEditable);
      if(!editable){ e.preventDefault(); openOverlay(); }
    } else if(overlay.hidden && (e.key === "k" || e.key === "K") && (e.ctrlKey || e.metaKey)){
      e.preventDefault(); openOverlay();
    }
  });
})();
