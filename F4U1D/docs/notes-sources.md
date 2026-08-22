# Notes de sources — F4U-1D Corsair

Matière brute collectée pour la rédaction des leçons, **ventilée par leçon
cible** et par phase du squelette. Ce fichier n'est pas publié : c'est le
carnet de rédaction, pas du texte joueur.

## Comment s'en servir

- Chaque bloc dit **d'où il vient** (source, date de collecte) et **où il
  va** (fichier + phase du squelette).
- Rien n'est recopié tel quel dans une leçon : une note vidéo décrit *une*
  façon de faire, souvent simplifiée. Avant publication, **recouper avec le
  manuel officiel** `docs/manuel-f4u1d.pdf`
  (`Mods\aircraft\F4U-1D\Doc\DCS_F4U-1D_Manual_Early-Access_16-Sept-2025.pdf`,
  vérifié identique) — le manuel fait foi sur les valeurs chiffrées, les
  seuils et l'ordre des actions.
- Les notes marquées **`[à recouper]`** sont des points où la vidéo donne une
  valeur ou un raccourci que le manuel doit confirmer ou nuancer.
- Aucun numéro de bouton HOTAS n'est noté ici : les binds sont résolus à
  l'affichage depuis `data/f4u1d-bindings.json`, et ce fichier n'existe pas
  encore (voir `mapping-hotas.html`).

## État d'intégration (19/08/2026)

Ce carnet reste la matière brute — il n'est pas mis à jour rétroactivement
quand une leçon est écrite. Pour savoir ce qui est déjà passé dans le site,
c'est cette liste qui fait foi, pas le contenu des sections ci-dessous :

- **Écrit dans la leçon** (phases réelles, plus au stade du plan) :
  `preparer-module-controles.html` (phase 2), `demarrage-a-froid.html`
  (phases 1-3), `roulage-decollage.html` (phase 1), `navigation-radio.html`
  (phase 3), `canons-mk8.html` (phases 1-3), `bombes-roquettes.html`
  (les 4 phases).
- **Encore au stade du plan** (`ul.plan`, rien d'écrit) : tout le reste —
  `tour-cockpit.html`, `decollage-porte-avions.html`, `vol-de-base.html`,
  `regimes-moteur-wep.html`, `retour-atterrissage.html`,
  `appontage-essex.html`, `urgences.html`, `manoeuvres-combat.html`,
  `checklists-personnalisees.html`, toutes les leçons de perfectionnement,
  et les phases non listées ci-dessus des pages partiellement écrites.
- Chaque leçon écrite garde ses points `[à recouper]` visibles **dans la
  page elle-même** (encadrés `.note.warn`), pas seulement ici — un lecteur
  qui n'ouvre jamais ce carnet doit quand même voir ce qui n'est pas confirmé.

---

## Alerte — le module est en accès anticipé, les chiffres moteur bougent

**Confirmé le 19/08/2026 sur les forums ED (fil « Engine Settings Wrong/
Information mix up », août 2025) : trois sources qui ont l'air officielles
se contredisaient** sur les réglages moteur (RPM/pression d'admission/
mélange) — le manuel Magnitude 3, la **plaquette peinte dans le cockpit**,
et le vrai manuel de vol historique du moteur à injection d'eau. Un
développeur Magnitude 3 (**-Rudel-**) a confirmé que **la texture de la
plaquette cockpit est fausse** (reprise d'un moteur -8 sans injection
d'eau, pas celui du 1D) et que le manuel du jeu était lui-même encore en
cours de correction à cette date. Sa recommandation : se fier aux manuels
historiques datés **1er décembre 1952** ou **1er juin 1946**, pas à un
manuel de 1944 ou antérieur.

**Conséquence pour ce dépôt : ne jamais recopier une valeur moteur (RPM,
pression, régime WEP) sans revérifier contre le manuel du dépôt** (voir sa
date d'édition, `docs/manuel-f4u1d.pdf`) **et, idéalement, contre la
plaquette affichée par le module installé** — les deux ont pu changer
depuis la collecte de ces notes, le module étant patché régulièrement.
Aucune valeur chiffrée moteur de ce fichier ne doit être publiée telle
quelle dans une leçon sans ce recoupement.

---

# Source S1 — CasmoTV, tutoriel de démarrage

- **Vidéo** : « DCS: F4U Corsair — startup tutorial », chaîne CasmoTV.
  `https://www.youtube.com/watch?v=G7iiuslnMNs`
- **Module** : F4U-1D de Magnitude 3 (DCS), accès anticipé.
- **Collectée le** : 19/08/2026, transmise sous forme de résumé horodaté.
- **Couvre** : du cockpit froid jusqu'à la fin de la préparation avant
  roulage — démarrage, chauffe, déploiement de voilure, verrière, roulette de
  queue, horizon artificiel.
- **Limite** : c'est une démonstration, pas une procédure normalisée. Elle ne
  donne ni les limites moteur, ni les cas de panne, ni les variantes
  porte-avions.

---

## → `preparer-module-controles.html` (leçon 1)

**Phase 2 — Poser les axes indispensables.** Commandes que la vidéo
recommande explicitement de mapper, parce qu'elles se manipulent vite ou
sous contrainte de temps pendant le démarrage :

| Commande | Pourquoi la mapper |
| --- | --- |
| **Mélange** | Passer vite de *Cut-off* à la position centrale/intermédiaire pendant le lancement, une main restant sur le démarreur. Prévoir des positions dédiées, pas seulement un axe. |
| **Magnétos** | Défiler/sélectionner la position rapidement (dans la vidéo : 3 pressions pour atteindre `BOTH` depuis `OFF`). `[à recouper]` — le nombre de pressions dépend du sens de défilement du bind, pas de l'avion. |
| **Volets de capot** (cowl flaps) | Se règlent en continu pendant la chauffe et le roulage. |
| **Verrouillage de roulette de queue** | Bascule fréquente entre roulage et alignement ; la vidéo la met sur un interrupteur du manche. |

Note de rédaction : ça recoupe la phase 4 de la leçon 1 (« repérer ce qui
restera au clic cockpit ») — la vidéo montre que le déploiement de voilure et
la verrière restent, eux, au clic souris.

---

## → `demarrage-a-froid.html` (leçon 3)

### Phase 1 — Avant de toucher au démarreur

État de départ à poser avant toute chose :

1. **Mélange** sur `OFF` / *Cut-off* — on ne l'avance qu'au moment du
   lancement.
2. **Gaz** : entrouverts très légèrement (*crack the throttle*).
   `[à recouper]` — le manuel donne probablement une ouverture chiffrée
   (pourcentage ou tours attendus), à préférer au geste approximatif.
3. **Sélecteur de carburant** sur `MAIN` (réservoir principal).
4. **Magnétos** sur `BOTH`.
5. **Éclairage cockpit** allumé si besoin de lisibilité, **puis batterie**.
   La vidéo fait l'éclairage avant la batterie pour le confort de lecture ;
   `[à recouper]` l'ordre réel attendu par la checklist du manuel.
6. **Pompe à carburant** enclenchée.

### Phase 2 — L'amorçage et le lancement

1. **Amorçage** (*primer*) maintenu **5 à 6 secondes** — un sifflement
   confirme que ça amorce. `[à recouper]` : la durée dépend normalement de la
   température du moteur (froid vs déjà chaud), le manuel doit donner la
   règle plutôt qu'une valeur unique.
2. **Cache de sécurité du démarreur** relevé.
3. **Démarreur maintenu** jusqu'à ce que l'hélice commence à tourner.
4. **Mélange avancé** au moment où l'hélice tourne — c'est le geste
   critique de la séquence, les deux mains sont occupées, d'où le mapping
   recommandé en leçon 1.
5. **Démarreur maintenu un bref instant de plus** pour stabiliser, puis
   relâché.
6. **Gaz modulés** au besoin pour empêcher le moteur de s'arrêter juste
   après le lancement.

À écrire en complément (absent de la vidéo, à prendre au manuel) : que faire
si le moteur ne prend pas, délai avant nouvelle tentative, signes d'un moteur
noyé, surveillance de la pression d'huile pendant le lancement.

### Phase 3 — La montée en température

1. **Freins maintenus**, régime monté vers **800 tr/min**.
2. Laisser tourner **quelques minutes** à ce régime pour stabiliser
   pressions et températures. `[à recouper]` — le manuel donne sans doute un
   *seuil de température à atteindre* plutôt qu'une durée, ce qui est plus
   fiable à enseigner qu'« quelques minutes ».
3. **Volets de capot ouverts** pour favoriser le refroidissement.

### Phase 4 — Essais moteur et mise en route des systèmes

La vidéo ne couvre pas les essais magnétos ni l'essai de pas d'hélice —
**à prendre entièrement au manuel**. Elle apporte en revanche :

- **Horizon artificiel** : le décager (bouton central) s'il est encore
  bloqué. À placer ici ou en fin de leçon 4 selon le découpage retenu.

---

## → `roulage-decollage.html` (leçon 4)

### Phase 1 — Configurer avant de lâcher le frein

**Déploiement et verrouillage de la voilure** — la séquence complète, et
c'est un point où on se plante facilement :

1. Panneau droit, **clic droit** sur la commande de dépliage.
2. Attendre la **descente complète** des ailes : deux confirmations
   simultanées, les **indicateurs mécaniques qui sortent** et un
   **avertisseur sonore** (klaxon) qui se déclenche.
3. **Manette de verrouillage abaissée**, puis **immédiatement remontée**.
4. Confirmation que c'est verrouillé : **le klaxon s'arrête**.

Note de rédaction : le klaxon sert deux fois, d'abord comme signal « ailes
descendues mais pas verrouillées », puis par son silence comme signal
« verrouillé ». C'est le genre de repère sensoriel qui vaut mieux qu'une
description visuelle — à garder tel quel dans la leçon.

**Verrière** : commande **jaune** pour ouvrir/fermer. La commande **rouge
est la largage d'urgence** — à signaler explicitement, c'est un piège de clic.
Recouper avec la leçon 13 (urgences), qui doit décrire la rouge pour de bon.

**Roulette de queue** : poignée en bas à droite (tirer et tourner), ou
interrupteur du manche si mappée. **Déverrouillée pour rouler**, le contrôle
de direction se fait alors aux **freins différentiels**.
`[à recouper]` — le manuel doit donner le moment exact où on la reverrouille
avant l'alignement, la vidéo s'arrête avant.

---

# Source S2 — Spud Spike, emploi de l'armement air-sol

- **Vidéo** : « DCS F4U-1D Corsair Basic Weapons Tutorial | Guns, Rockets &
  Bombs! », chaîne Spud Spike.
  `https://www.youtube.com/watch?v=66a2xXPraTs`
- **Module** : F4U-1D de Magnitude 3 (DCS), accès anticipé.
- **Collectée le** : 19/08/2026, transmise sous forme de résumé structuré.
- **Couvre** : mise en œuvre complète de l'armement air-sol — préparation du
  coffret d'armement, bombardement en piqué, roquettes HVAR, mitraillage, et
  la discipline de dégagement.
- **Limite** : aucune valeur chiffrée (angle de piqué, altitude de largage,
  distance de convergence, vitesse de passe). C'est un *comment on s'y prend*,
  pas un *avec quels paramètres* — tout le chiffrage vient du manuel.

---

## → `canons-mk8.html` (leçon 11)

### Phase 1 — Armer et sécuriser

Séquence de mise en œuvre, dans l'ordre :

1. **Master Arm** en position haute (`ARM`).
2. **Viseur** allumé, **luminosité au maximum** — la vidéo insiste, le
   réticule est difficile à voir sinon.
3. **Alimentation des mitrailleuses** : activer les trois groupes sur le
   panneau — **extérieures, intermédiaires, intérieures**. Les six ne
   s'activent pas d'un seul geste.
4. **Armement mécanique** : basculer les **leviers de rechargement** jusqu'au
   **clic** audible. Sans ça, l'alimentation seule ne suffit pas.

**Astuce à garder telle quelle dans la leçon :** faire une **brève rafale
d'essai avant d'entrer dans la zone** — c'est la seule façon de découvrir un
problème d'armement autrement qu'au moment de tirer sur la cible.

### Phase 3 — Tirer, et Phase 4 — S'entraîner

- **Bille centrée au palonnier** pendant toute la rafale : sans calculateur,
  la moindre dissymétrie disperse le tir. C'est le geste qui distingue une
  passe qui touche d'une passe qui laboure le sol à côté.
- **Vitesse élevée maintenue** pendant toute la passe de mitraillage.
- `[à recouper]` la vidéo ne donne **ni distance de convergence, ni distance
  d'ouverture du feu** — à prendre au manuel, c'est le cœur de la phase 3
  telle qu'elle est prévue dans le squelette.

---

## → `bombes-roquettes.html` (leçon 12)

### Phase 1 — Préparer les emports

**Coffret de largage (bomb box) :**

- **Fusées / armement** : réglage **nez et queue** (*Nose & Tail*) pour
  garantir la détonation à l'impact.
  `[à recouper]` — le choix du fusible dépend normalement du type de cible et
  de l'effet recherché (retard pour un bunker, instantané pour du matériel).
  Le manuel doit donner la règle, la vidéo ne montre qu'un cas.
- **Sélection des pylônes**, un à la fois :
  - bombe centrale → activer le largage du **pylône central** ;
  - bombes sous voilure → **largage gauche** ou **largage droit** selon celle
    qu'on veut lâcher.

**Point qui mérite d'être explicite dans la leçon :** entre deux passes, il
faut **désactiver le pylône déjà utilisé puis sélectionner le suivant**. Ce
n'est pas automatique — c'est le piège classique de la deuxième passe où rien
ne part.

### Phase 2 — Le piqué de bombardement

**Préparation moteur avant d'engager le piqué** — la partie la plus
intéressante, et elle renvoie directement à la leçon 7 :

1. **Pilote automatique désactivé.**
2. **Volets de capot fermés.**
3. **Compresseur réduit**, pour éviter le **refroidissement brutal**
   (*shock cooling*) pendant la descente rapide.
   `[à recouper]` — mécanisme plausible et cohérent avec un moteur en étoile,
   mais à confirmer dans la section gestion moteur du manuel avant de
   l'enseigner comme une règle.

**La passe elle-même :**

- Arriver **à plat**, puis basculer — ça permet d'obtenir un **angle de piqué
  franc** sur la cible plutôt qu'une descente molle.
- Aligner le réticule sur la cible, larguer.
- `[à recouper]` **angle, vitesse et altitude de largage ne sont pas donnés**
  — c'est exactement ce que la phase 2 du squelette annonce, et ça ne peut
  venir que du manuel.

### Phase 3 — Les roquettes

1. **Sélecteur d'armement sur roquettes.**
2. **Vol parfaitement coordonné, bille au centre**, et **approche en ligne
   droite** — la roquette part dans l'axe de l'avion, toute dissymétrie se
   traduit directement en erreur latérale.
3. **Tirer par salves**, observer le point d'impact, **corriger la visée pour
   la salve suivante**. C'est une visée par correction successive, pas un
   calcul préalable.

### Phase 4 — Sortir de l'attaque

- **Rompre immédiatement dès la fin du tir** — virage franc, sans délai.
- **Ne jamais évoluer en ligne droite à basse altitude** : c'est ce qui
  transforme une passe réussie en avion abattu par la DCA.

---

## → `attaque-sol-coordonnee.html` (perfectionnement, leçon 4)

La discipline de dégagement de S2 est la version débutante de ce que cette
leçon doit approfondir : varier les axes et les altitudes entre les passes,
reconnaître les défenses avant d'entrer, et la fixation sur la cible comme
cause première de perte. À écrire en montant d'un cran, pas en répétant.

---

## Recoupement entre sources

S1 (démarrage) et S2 (armement) se rejoignent sur un point : le F4U-1D a bien
une fonction de **mise à plat automatique / pilote automatique**, que S2
demande de couper avant le piqué. À décrire une fois proprement en leçon 6
(vol de base), puis à rappeler en leçon 12.

---

# Source S3 — Virtual Carrier Task Force 58, radiocompas YE-ZB

- **Vidéo** : « DCS WORLD | F4U-1D Radio Homing Tutorial », chaîne Virtual
  Carrier Task Force 58.
  `https://www.youtube.com/watch?v=hqg6BRgkdDc`
- **Module** : F4U-1D de Magnitude 3 (DCS), accès anticipé.
- **Collectée le** : 19/08/2026, transmise sous forme de résumé structuré.
- **Couvre** : le principe du système YE-ZB (secteurs de 30°, identifiant
  Morse du porte-avions), la procédure cockpit complète sur le récepteur
  AN/ARR-2 et l'unité C-38, et — point rare — **la configuration côté
  éditeur de mission**, utile pour que l'utilisateur puisse s'entraîner en
  mission construite par lui-même.
- **Limite** : ne couvre que le YE-ZB. Rien sur l'ARC-5 (postes de
  communication), la navigation à l'estime, ni la lecture du gyro
  directionnel.

---

## → `navigation-radio.html` (leçon 8)

### Phase 3 — Le radiocompas (à réécrire entièrement sur cette base)

**Le principe, à expliquer avant la procédure** — sans ça, « écouter un S ou
un L » reste une recette apprise par cœur au lieu d'être compris :

- Le porte-avions (**YE**) émet un faisceau radio **tournant**, découpé en
  **secteurs de 30°** — 12 tranches de camembert autour du navire, chacune
  associée à une lettre du code Morse.
- Le récepteur de l'avion (**ZB**, matériel **AN/ARR-2**) capte, en boucle,
  deux éléments Morse : l'**identifiant du porte-avions** (ex. `CV`) puis la
  **lettre du secteur** où se trouve l'avion (ex. `S`, `L`...).
- **Le cap de retour est l'inverse du secteur entendu**, pas le secteur
  lui-même : entendre `S` (secteur centré sur le relèvement 345° depuis le
  bateau) veut dire « je suis sur ce relèvement », donc il faut voler au cap
  **165°** pour rejoindre. Entendre `L` (015°) → cap **195°**.
- **Un signal qui alterne entre deux lettres** (ex. `S` et `L` en va-et-vient)
  signifie qu'on est **sur la frontière** entre deux secteurs — l'avion est
  quasiment dans l'axe direct du bateau, c'est en fait la meilleure situation,
  pas une ambiguïté à résoudre.
- Le signal se répète **environ toutes les 30 secondes** — la leçon doit
  prévenir que la patience fait partie de la méthode, ce n'est pas un
  indicateur continu comme un TACAN.

**Procédure cockpit, dans l'ordre :**

1. Sur l'unité de contrôle **C-38**, basculer **`RECTIFIER C MHF`** sur `ON`.
   **Attendre environ 5 secondes** — les tubes à vide doivent chauffer, ce
   n'est pas instantané comme un équipement à semi-conducteurs.
2. Régler le récepteur sur le **canal présélectionné** correspondant au
   porte-avions (ex. canal 1).
3. **Spécificité DCS, à signaler explicitement comme telle** : basculer
   `CW / VOICE` sur **`VOICE`** pour *entendre* le Morse dans le jeu — c'est
   un artefact de simulation, pas un geste historique à expliquer comme tel.
4. Écouter, décoder la lettre, calculer le cap inverse, corriger — et
   recommencer à la répétition suivante du signal.

`[à recouper]` — la vidéo ne dit pas ce qui se passe **hors de portée** du
signal (silence complet ? signal faible ?), ni si la distance au bateau se
déduit d'une façon ou d'une autre (force du signal, par exemple). Point à
vérifier au manuel avant de clore la leçon.

### Note pour la leçon — configuration en éditeur de mission

Hors procédure de vol, mais utile pour que le joueur puisse **fabriquer ses
propres vols d'entraînement** (ça recoupe l'outil `missions.html`, section
« Se fabriquer ses propres vols ») :

- **Côté porte-avions** : définir une fréquence (ex. `124.000 MHz AM`) sur le
  groupe naval, et **renommer l'unité** — les **trois premières lettres** de
  son nom deviennent l'identifiant Morse transmis (`CV_` → `CV`).
  **Un seul porte-avions par fréquence**, pour éviter que deux signaux se
  chevauchent.
- **Côté Corsair** : régler le **preset de navigation ARR-2** (canal 1) sur
  la même fréquence que le porte-avions.

À reformuler en encadré « pour t'entraîner toi-même » plutôt qu'en étape de
la checklist de vol — ce n'est pas un geste qu'on fait en l'air.

---

# Source S4 — fichiers communautaires (DCS User Files)

Trois documents téléchargeables, repérés le 19/08/2026 par recherche web.
**Non téléchargés** : télécharger un fichier tiers demande une confirmation
explicite (voir règles de sécurité) — ce sont des pointeurs, pas du contenu
récupéré. Si l'utilisateur veut qu'on les récupère pour en extraire le
contenu exact, le demander avant.

- **« F4U-1D: Do Not Exceed Table »**, par *Dkha*, MàJ 26/06/2025.
  `https://www.digitalcombatsimulator.com/en/files/3345478/`
  Reproduction lisible de la plaquette de limites moteur affichée en
  cockpit — colonnes régime, réglage compresseur, RPM, altitude minimale,
  pression d'admission, mélange/température culasse max. PDF, 3,26 Mo,
  freeware redistribuable. **Vu l'alerte ci-dessus sur la plaquette
  d'origine fausse, vérifier si cette reproduction a été mise à jour après
  la correction de Magnitude 3 avant de s'y fier pour la leçon 7.**

- **« F4U-1D Procedural Checklist and Emergency procedures (V5) »**, par
  *Mike Busutil*, MàJ 22/06/2025, 1476 téléchargements.
  `https://www.digitalcombatsimulator.com/en/files/3345416/`
  **34 pages**, basé sur le manuel de vol Navy réel. Sections directement
  utiles à plusieurs leçons du squelette : Flight Preparation, Before
  engine start, Engine warmup, Idle mixture checks, **Supercharger
  checks**, Before taxi, Taxi, Hold short, Takeoff, After takeoff, Mil
  power climb, Normal Cruise, Best endurance cruise, Combat Preparation,
  Normal Descent, **Dive Checklist**, Approach and landing, Go-around,
  After landing/Shutdown, et **17 procédures d'urgence détaillées**.
  Couvre à lui seul une bonne partie des manques listés en bas de ce
  fichier (essais moteur, WEP, urgences). Freeware, **ne pas redistribuer**.

- **« F4U-1D Corsair Kneeboards with Checklists, Speeds, Engine Settings,
  Nav Sectors and Morse Reference »**, par *GTFreeFlyer*, MàJ 25/03/2026.
  `https://www.digitalcombatsimulator.com/en/files/3345803/`
  Kneeboards prêts à installer (`Saved Games\DCS\Kneeboard\F4U-1D\`) —
  vitesses caractéristiques, réglages moteur, **secteurs de navigation
  YE-ZB** et **arbre de décodage Morse** (complète directement S3). La
  description dit explicitement : *« Engine settings have been updated
  after receiving a new chart from Magnitude 3 along with a note that
  said, 'Use this engine chart. No other engine charts from 1944 or
  prior.' »* — c'est la source la plus fraîche et la plus fiable pour les
  chiffres moteur au moment de la collecte, mais **revérifier sa date de
  mise à jour contre la nôtre avant de la citer**, le module continue
  d'être patché.

---

# Source S5 — forums Eagle Dynamics (fils utiles)

Extraits de discussions communautaires, à traiter comme des **pistes à
vérifier**, pas comme des faits établis — un post de forum n'a pas
l'autorité du manuel, même quand un développeur Magnitude 3 y répond.

## → `canons-mk8.html` (leçon 11) — convergence des mitrailleuses

Fil « Gun convergence in what? », juin 2025 – mars 2026.
`https://forum.dcs.world/topic/375075-gun-convergence-in-what/`

- **Confirmé par un développeur Magnitude 3 (-Rudel-)** : l'unité de
  convergence est le **mètre**, réglable dans l'éditeur de mission (fiche
  avion → Additional Aircraft Properties → cases inner/middle/outer guns +
  case "custom pattern"). **Ce n'est pas un réglage cockpit** — à préciser
  dans la leçon, sous peine de faire chercher un bouton qui n'existe pas.
- Valeurs disponibles au moment de la collecte : **300 / 400 / 500 / 600 /
  700 / 800 m**, défaut **500 m**.
- **Repère historique cité par un contributeur** (note technique navale du
  04/06/1943, pattern #2) : convergence réelle US WWII à **450 yards**
  (inner/outer) et **250 yards** (middle) — donc bien plus courte que le
  défaut du jeu. Un autre pilote de Dogfights (Jefferson DeBlanc, F6F) est
  cité à 1000 pieds (~350 yards), corrigé en cours de fil depuis une
  confusion pieds/yards initiale.
  `[à recouper]` la communauté jugeait au moment de la collecte que 300 m
  restait plus proche de l'usage réel que le défaut 500 m — mais Magnitude 3
  avait annoncé vouloir ajouter des paliers plus courts (100-250 m) ; à
  vérifier si c'est fait dans la version installée avant de donner une
  valeur recommandée dans la leçon.

## → `bombes-roquettes.html` (leçon 12) — piqué de bombardement

Fil « Help with Bombing in the F4U Corsair », juin 2025.
`https://forum.dcs.world/topic/375545-help-with-bombing-in-the-f4u-corsair-tips-reticle-usage/`

- Une seule réponse technique, et l'auteur précise lui-même ne pas l'avoir
  vérifiée dans DCS (expérience tirée d'autres simulateurs) —
  `[à recouper]` en priorité, ne pas publier tel quel.
- Piste donnée : en piqué à environ **70°**, placer la cible **à mi-chemin
  entre le haut du capot et le bas de l'anneau des 100 mils** du réticule
  Mk.8 pour un largage centré.
- Rappel utile sur le réticule lui-même : les anneaux servent aussi à
  l'**estimation de distance par l'envergure** de la cible (règle citée par
  un autre pilote dans le fil convergence : une envergure de 30 ft pleine
  dans l'anneau 50 mils, ou 60 ft dans l'anneau 100 mils, correspond à
  400 yards) — utile pour la leçon 11 autant que la 12.

## → `retour-atterrissage.html` (leçon 9) et `appontage-essex.html` (leçon 10)

Fil « Carrier landings », juin 2025 → nov. 2025, 105 réponses.
`https://forum.dcs.world/topic/375143-carrier-landings/`

**Piège à signaler avant tout : bug d'accrochage de brin connu au moment de
la collecte**, spécifique à certaines cartes en mission construite (WW2
Marianas, Normandy) — le crochet ne s'accroche à aucun brin alors que la
même approche fonctionne sans problème sur la mission d'entraînement
Caucase ou sur un Supercarrier. Confirmé par plusieurs pilotes
indépendamment, cause non identifiée dans le fil. **À mentionner dans la
leçon comme un problème connu du module, pas comme une erreur de
pilotage** — sinon un débutant qui rate ses appontages sur ces cartes va
chercher une faute qu'il n'a pas commise.

Technique d'approche, tirée d'une interview de pilotes britanniques
relayée dans le fil (donc **témoignage historique**, pas une mesure DCS) :

- **Approche en virage continu** : les ailes reviennent à plat au moment du
  toucher (ou presque), pas avant.
- **Couper les gaz complètement dès les ailes à plat** — geste franc,
  presque un atterrissage trois points.
- **Vitesse de toucher** rapportée : **88 à 90 nœuds**.
- **Vitesse de rapprochement sur le pont** (résultante) : **28 à 30 nœuds**
  — dépend de l'équilibre vent/vitesse du bateau réglé en mission.
- Volets de capot **fermés au décollage**, **ouverts à l'atterrissage**
  (refroidissement et traînée).
- Configuration finale (train, volets, crosse) établie **tôt dans le
  circuit**, pas en courte finale.

Retours pratiques d'un joueur ayant appliqué la méthode (moins fiables,
un seul témoignage, mais concrets) : 40° de volets, régime **2400 tr/min**,
puissance ajustée pour tenir environ **93 nœuds** (90 en virage), 10° de
trim à cabrer, léger trim de direction et d'ailerons à droite.

**Sur le vent** : consensus du fil pour un vent apparent sur le pont d'au
moins **20 à 25 nœuds** (ex. bateau à 15-18 nds + vent 10-15 nds, cap
face au vent) — en dessous, l'avion devient instable à l'approche à basse
vitesse. Contacter le porte-avions par radio n'est **pas nécessaire** pour
accrocher un brin, contrairement à une intuition courante.

## → `demarrage-a-froid.html` et `regimes-moteur-wep.html` — limites moteur, à ne PAS republier telles quelles

Fil « Engine Settings Wrong/Information mix up », août 2025.
`https://forum.dcs.world/topic/378039-engine-settings-wronginformation-mix-up/`

C'est la source de l'alerte tout en haut de ce fichier. Résumé de ce qui
s'y est dit, **pour information seulement** — ces chiffres datent d'août
2025 et ont vocation à changer :

- Faire tourner le WEP à plein régime provoquait un cognement moteur
  anormal (survitesse du réglage).
- Un contributeur affirmait que le régime WEP correct était **2700 tr/min**
  sur toute la plage, contre 2550 dans les données du kneeboard de
  l'époque — et que le compresseur en position WEP devait rester neutre
  sous 8000 ft (pas "Low" dès 5000 ft comme modélisé alors).
- Le développeur Magnitude 3 a confirmé publiquement en corriger les
  chiffres et recommandé, en attendant, de se fier au **kneeboard
  communautaire** (celui de S4/GTFreeFlyer) plutôt qu'au manuel du jeu ou à
  la plaquette cockpit.

**Ne rien publier de ces chiffres précis dans la leçon 7** sans les
revérifier contre le manuel actuellement dans le dépôt et, si possible,
contre la plaquette du module installé — voir l'alerte en tête de fichier.

---

# Source S6 — Spud Spike, entraînement de base grandeur nature

- **Vidéo** : « DCS F4U-1D Corsair | World War 2 Basic Training! », chaîne
  Spud Spike. `https://www.youtube.com/watch?v=z2Ig7xg3tEc`
- **Module** : F4U-1D de Magnitude 3 (DCS), accès anticipé.
- **Collectée le** : 19/08/2026, transmise sous forme de résumé structuré.
- **Couvre** : un vol multijoueur complet — deux avions d'attaque au sol
  (dont un F4U-1D chargé bombes/HVAR) escortés par trois Corsair de
  couverture, sur Îles Marianes WWII. Démarrage, montée, interception de
  Zeros IA, passes air-sol, retour et **break militaire** en surpassage de
  piste.
- **Nature de la source** : commentaire de vol en situation réelle de jeu,
  pas un tutoriel posé — les chiffres sont donnés de mémoire pendant le
  vol, à recouper plus soigneusement encore que S1-S3.
- **Limite** : le script serveur qui réduit la robustesse de l'IA
  mentionné dans la vidéo est propre à cette session multijoueur, pas au
  module — ne pas le mentionner comme un réglage standard.

---

## → `demarrage-a-froid.html` (leçon 3) — un point que S1 n'a pas donné

**Volets d'huile (oil cooler flaps), distincts des volets de capot** :
- **Volets de capot** : ouverts en grand **au sol**, pour évacuer la
  chaleur des culasses (CHT) pendant que le moteur tourne à l'arrêt —
  confirme et précise S1, qui mentionnait l'ouverture sans ce détail.
- **Volets d'huile** : à l'inverse, **fermés au début**, tant que l'huile
  n'a pas atteint sa température de fonctionnement — une huile froide est
  visqueuse, elle fait chuter la pression affichée si on la refroidit
  encore. Point absent de S1, à ajouter en phase 3 (montée en température)
  à côté des volets de capot, en les distinguant clairement l'un de
  l'autre pour ne pas les confondre dans la leçon.

`[à recouper]` — aucune valeur de température-seuil donnée à l'oral, à
prendre au manuel.

## → `vol-de-base.html` (leçon 6) et `regimes-moteur-wep.html` (leçon 7)

**Enclenchement du compresseur en montée** : bascule vers le premier étage
**aux alentours de 8000 ft**, en entrouvrant l'intercooler au même moment.
`[à recouper]` — confirme l'existence d'un seuil mentionné plus vaguement
par S1 (leçon 7, phase « le compresseur à deux étages ») ; le manuel doit
donner la valeur exacte et si elle dépend de la masse/temp. extérieure.

**Injection d'eau (WEP)** :
- Interrupteur sur la **console gauche**, protégé par un **fil d'arrêt à
  briser** avant utilisation — détail concret à inclure tel quel dans la
  leçon (empêche une activation accidentelle).
- **Durée maximale d'utilisation : environ 5 minutes.**
  `[à recouper]` — valeur donnée de mémoire pendant un vol, à confirmer
  au manuel avant de la publier comme un chiffre sûr.

**Réglages de croisière suggérés en montée/transit** : **2500 tr/min**,
**35 à 42 in.Hg** de pression d'admission.
`[à recouper]` — cohérence à vérifier avec le tableau du manuel et avec
l'alerte générale sur les chiffres moteur (voir en tête de fichier) ;
c'est justement le genre de valeur qui a bougé entre deux patches d'après
S5.

## → `roulage-decollage.html` (leçon 4) — incertitude sur le repliage de voilure

Point à traiter avec prudence, presque comme un avertissement plutôt
qu'une procédure ferme : **l'étiquette du cockpit indique de laisser la
commande sur `Spread` (dépliée)**, mais si le **verrouillage mécanique
échoue**, la **pression hydraulique continue de pousser les ailes vers le
bas** malgré tout. Autrement dit, la position de la commande ne garantit
pas à elle seule que les ailes restent hautes.

`[à recouper]` en priorité — c'est soit un comportement du module encore
en évolution (accès anticipé), soit une mécanique réelle mal comprise par
le contributeur. Ne pas présenter ça comme un fait établi dans la leçon
tant que ce n'est pas confirmé par le manuel ou par un nouveau test. À
recouper aussi avec la séquence de verrouillage déjà collectée en S1
(klaxon qui s'arrête = verrouillé) — les deux sources ne se contredisent
pas frontalement mais S6 introduit un doute que S1 n'avait pas.

## → `canons-mk8.html` / `bombes-roquettes.html` (leçons 11-12)

Confirme un point déjà noté en S2 : **bille centrée au palonnier pendant
les passes de mitraillage**, ici décrit comme un geste actif des deux
pieds (gauche/droite) pour compenser en continu, pas une position fixe.
Rien de nouveau côté armement au-delà de cette confirmation.

## → `retour-atterrissage.html` (leçon 9) — le break militaire, absent des autres sources

Ni S1 ni S5 (technique du virage continu tirée de l'interview de pilotes
britanniques) ne décrivaient cette entrée de circuit — c'est un ajout net,
probablement à traiter comme une **variante avancée** du circuit plutôt
que la méthode de base enseignée en leçon 9 :

1. **Passage au-dessus de la piste à 300 nœuds.**
2. **Virage serré** directement en vent arrière — pas de branche vent
   arrière longue comme dans un circuit civil.
3. **Configuration très rapide** (train, volets) pendant ce virage, pour
   ne pas rattraper l'avion qui précède dans le circuit.

`[à recouper]` — c'est une procédure militaire typique (overhead break),
plausible pour ce genre d'avion, mais aucune vitesse ni distance de
sécurité n'est confirmée pour la version DCS. À ne présenter qu'après
recoupement, et clairement étiqueté comme technique avancée / vol en
patrouille plutôt que comme le circuit par défaut du pilote solo débutant.

## → `missions.html` — structure d'un vol d'entraînement à deux rôles

Hors procédure de pilotage, mais utile comme modèle pour la section « se
fabriquer ses propres vols d'entraînement » : la vidéo illustre un exercice
à deux rôles simultanés — un binôme d'attaque au sol (bombes + HVAR) escorté
par une couverture chasse — sur la carte Îles Marianes WWII. Un modèle de
mission construite que l'utilisateur peut reproduire pour s'entraîner à la
coordination, une fois les leçons individuelles acquises.

---

# Ce qui manque encore

Sujets couverts par aucune source collectée, pour lesquels il faut le manuel
seul ou une source supplémentaire :

- Essais moteur complets (magnétos, pas d'hélice) et valeurs de chute de
  régime acceptables — **probablement couvert par S4 (Procedural Checklist
  V5, sections Idle mixture checks / Supercharger checks)**, à vérifier en
  récupérant ce fichier si l'utilisateur le souhaite.
- Toute la partie décollage, à partir de l'alignement.
- Démarrage et procédures spécifiques **porte-avions** (leçon 5).
- Limites moteur chiffrées, compresseur, WEP (leçon 7) — S2, S5 et S6 en
  parlent, S6 donne même des valeurs (2500 tr/min / 35-42 in.Hg,
  ~5 min de WEP, bascule compresseur vers 8000 ft), mais **aucune n'est
  confirmée par une source écrite fiable** ; S4 (kneeboard GTFreeFlyer)
  reste la meilleure piste à récupérer et recouper avec le manuel du dépôt.
- **Tout le chiffrage précis de l'armement** : distance d'ouverture du feu
  au canon, angle et altitude de piqué validés en jeu (S5 donne une piste
  non vérifiée), distance utile des roquettes. La **convergence**, elle,
  est maintenant documentée (S5) — reste à choisir/recommander une valeur.
- **Tiny Tim** — aucune source collectée n'en parle.
- **Navigation à l'estime et postes ARC-5** — S3 ne couvre que le YE-ZB.
- **Urgences (leçon 13)** — probablement couvert par S4 (17 procédures
  détaillées), à récupérer.
- **Le comportement du repliage de voilure en cas d'échec du verrouillage**
  (S6) — point à clarifier en priorité avant d'écrire la phase concernée de
  la leçon 4, actuellement fondée uniquement sur la séquence normale de S1.
- Le **bug d'accrochage de brin sur certaines cartes** (S5) doit être
  documenté quelque part sur le site — pas forcément dans une leçon
  pas-à-pas, peut-être un encadré dans `ressources.html` ou `missions.html`.
- Le **break militaire** décrit en S6 reste à confirmer avant publication —
  voir la section dédiée ci-dessus.

---

# Disposition HOTAS — ce que dit le manuel officiel

Le Corsair n'a **pas de guide de binds** équivalent à la partie 2 du guide
de Chuck pour le F-4E (vérifié le 21/08/2026 : rien de tel dans
`F4U1D/docs/`, qui ne contient que des kneeboards, des checklists et une
liste d'arguments cockpit). En remplacement, le manuel officiel Magnitude 3
donne mieux qu'une liste de binds : **la carte du cockpit réel**, ce qui
permet de répartir les commandes là où la main du pilote les trouve
vraiment.

## Ce que porte réellement le manche (manuel §2.1, §2.3)

**Deux contacts, pas un de plus** :

- la **détente** des six .50 — « Trigger switch on the control stick » ;
- le **bouton pouce de largage** — « The thumb switch for releasing the
  bombs is located on the control stick », confirmé par la procédure de
  largage électrique (§3.3 : *Press the thumb Weapons Release button on the
  control stick*).

Tout le reste de l'armement est ailleurs : master arm, sélecteurs de canons
(interne / intermédiaire / externe) et viseur sont dans la **boîte
d'armement**, à gauche du gunsight ; l'armement des bombes est sur la
**boîte pylônes**.

## Console gauche (planche p. 25 du manuel)

C'est la main gauche du pilote, donc ce qui doit aller sur la manette :

Wing Hinge Pin Lock · Wing Folding · Manual Drop Tank and Bomb Release ·
Tail Wheel Lock · **Trim Tab Controls** · **Engine Control Unit** (gaz,
hélice, mélange) · Landing Gear and Dive Brake · **Rocket Launching
Switch** · **Ignition Switch** · Wing Flaps · CO2 Release · **Hydraulic
System Hand Pump** · **Fuel Selector** · **Auxiliary Fuel Pump**.

## Console droite (planche p. 26 du manuel)

Mk.3 Rocket Station Distribution Box · **Cooling Flaps Control** · Pilot's
Distribution Box · **AN/ARC-5 Radio Remote Controls** · Arresting Hook ·
Flare Cartridge Box · Oxygène · **Defroster** · Batterie · Map Case.

## Comment le mapping du site s'y raccroche

| Périphérique | Logique retenue |
| --- | --- |
| **Manche** | Les 2 contacts réels (détente, largage) + ce qui doit rester sous la main droite en vol : trim 3 axes, vues, sélection d'armes et de roquettes |
| **Manette** | Calquée sur la console gauche : les 3 leviers moteur sur les 3 axes, compresseur sur une molette, puis allumage, carburant, refroidissements ; radio ARC-5 et dégivrage repris de la console droite |
| **PTO2** | Les 25 binds **réels** déjà écrits par DCS : train, volets, crosse, repliage de voilure, largage sélectif |

Le rotacteur de pages Virpil (positions Blanc/Bleu/Vert/Rouge/Jaune) est
laissé **sans pagination** : contrairement au F-14B(U), le Corsair n'a pas
assez de commandes distinctes pour justifier cinq jeux de six boutons. Les
repères 38-43 gardent donc la même fonction quelle que soit la position.
