/* Moteur commun des pages « Pas à pas » / « Perfectionnement ».

   Reprend la logique écrite en ligne dans chaque page du F14BU, mais
   paramétrée par des attributs sur <body> au lieu d'être recopiée :

     <body data-progress-key="f4u1d-demarrage-progress"
           data-bindings="data/f4u1d-bindings.json"
           data-bind-store="f4u1d-export-bindings-v1">

   - data-progress-key : clé localStorage de la checklist (obligatoire pour
     que la progression soit sauvegardée ; sans elle, la page marche quand
     même mais n'enregistre rien).
   - data-bindings     : chemin du JSON de binds, relatif à la page. Absent
     ou introuvable → tous les badges tombent proprement sur « non affecté »
     et pointent vers le mapping, jamais sur un lien mort.
   - data-bind-store   : clé localStorage écrite par export-bindings.html,
     qui prend le pas sur le JSON livré.

   Aucun numéro de bouton n'est jamais écrit en dur dans le texte d'une
   leçon : le badge est résolu ici, à l'affichage. */
(function(){
'use strict';

/* ---------- Checklist + barre de progression ---------- */
var boxes = [].slice.call(document.querySelectorAll('.step input[type=checkbox]'));
var KEY = document.body.dataset.progressKey || '';
var fill = document.getElementById('pfill');
var txt  = document.getElementById('ptxt');

function load(){
  if(!KEY) return {};
  try{ return JSON.parse(localStorage.getItem(KEY) || '{}'); }catch(e){ return {}; }
}
function save(state){
  if(!KEY) return;
  try{ localStorage.setItem(KEY, JSON.stringify(state)); }catch(e){}
}
function updateProgress(){
  var done = boxes.filter(function(b){ return b.checked; }).length;
  if(txt)  txt.textContent = done + ' / ' + boxes.length + ' étapes cochées';
  if(fill) fill.style.width = (boxes.length ? (done / boxes.length * 100) : 0) + '%';
}
var state = load();
boxes.forEach(function(b){
  var id = b.dataset.id;
  if(state[id]){ b.checked = true; b.closest('.step').classList.add('done'); }
  b.addEventListener('change', function(){
    state[id] = b.checked;
    save(state);
    b.closest('.step').classList.toggle('done', b.checked);
    updateProgress();
  });
});
updateProgress();

/* ---------- Visionneuse d'image ---------- */
var lb = document.getElementById('lb'), lbimg = document.getElementById('lbimg');
if(lb && lbimg){
  document.addEventListener('click', function(e){
    var img = e.target.closest('figure img');
    if(img){ lbimg.src = img.src; lbimg.alt = img.alt || ''; lb.classList.add('on'); return; }
    if(e.target.closest('.lb')) lb.classList.remove('on');
  });
  document.addEventListener('keydown', function(e){ if(e.key === 'Escape') lb.classList.remove('on'); });
}
/* une planche absente laisse un message, pas une image cassée */
document.querySelectorAll('figure img').forEach(function(img){
  img.addEventListener('error', function(){ img.closest('figure').classList.add('failed'); });
});

/* ---------- Badges de bind ---------- */
var BINDINGS_URL = document.body.dataset.bindings || '';
var BIND_STORE_KEY = document.body.dataset.bindStore || '';
var AXIS_KEYS = {X:'JOY_X', Y:'JOY_Y', Z:'JOY_Z', RX:'JOY_RX', RY:'JOY_RY', RZ:'JOY_RZ'};
var DEV_LABEL = {stick:'Manche', throttle:'Manette', pto2:'PTO2', pedals:'Pédales'};
var BINDINGS = null;

function deriveKeys(n, count){
  var upper = String(n).toUpperCase(), slots = Math.max(count, 1);
  if(AXIS_KEYS[upper]) return new Array(slots).fill(AXIS_KEYS[upper]);
  if(upper === 'SLDR') return new Array(slots).fill('JOY_SLIDER1');
  if(/^\d+$/.test(n)) return new Array(slots).fill('JOY_BTN' + n);
  var range = String(n).match(/^(\d+)-(\d+)$/);
  if(range){
    var keys = [];
    for(var b = +range[1]; b <= +range[2] && keys.length < slots; b++) keys.push('JOY_BTN' + b);
    return keys;
  }
  return new Array(slots).fill('');
}
function bindingsFor(cmdName){
  if(!BINDINGS || !BINDINGS.bindings) return [];
  var overrides = {};
  if(BIND_STORE_KEY){
    try{
      var saved = JSON.parse(localStorage.getItem(BIND_STORE_KEY) || 'null');
      if(saved && saved.state) overrides = saved.state;
    }catch(e){}
  }
  var hits = [];
  BINDINGS.bindings.forEach(function(b){
    var entry = overrides[b.device + '|' + b.n];
    var commands = (entry && Array.isArray(entry.commands)) ? entry.commands : b.commands;
    var keys = (entry && Array.isArray(entry.keys)) ? entry.keys : deriveKeys(b.n, commands.length);
    commands.forEach(function(name, i){
      if(name === cmdName && keys[i]) hits.push({device:b.device, key:keys[i], n:b.n});
    });
  });
  return hits;
}
function prettyKey(key){
  if(key.indexOf('JOY_BTN') === 0) return 'B' + key.slice(7);
  if(key.indexOf('JOY_') === 0) return key.slice(4);
  return key;
}
function paintBindBadges(){
  document.querySelectorAll('a[data-bind-cmd]').forEach(function(el){
    var hits = bindingsFor(el.dataset.bindCmd);
    el.target = '_blank'; el.rel = 'noopener';
    if(!hits.length){
      el.textContent = 'non affecté';
      el.classList.add('unbound');
      el.title = 'Pas de bind confirmé dans le profil actuel — ouvre le mapping pour vérifier ou en poser un';
      el.href = 'mapping-hotas.html';
      return;
    }
    var h = hits[0];
    el.classList.remove('unbound');
    el.textContent = (DEV_LABEL[h.device] || h.device) + ' · ' + prettyKey(h.key);
    el.title = el.dataset.bindCmd;
    el.href = 'mapping-hotas.html?dev=' + encodeURIComponent(h.device) + '&n=' + encodeURIComponent(h.n);
  });
}
if(document.querySelector('a[data-bind-cmd]')){
  if(BINDINGS_URL){
    fetch(BINDINGS_URL)
      .then(function(r){ return r.ok ? r.json() : null; })
      .then(function(j){ BINDINGS = j; })
      .catch(function(){ BINDINGS = null; })
      .then(paintBindBadges);
  }else{
    paintBindBadges();
  }
}
})();
