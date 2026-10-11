# Elite Dangerous — état et suite du travail

Dernière mise à jour : 11 octobre 2026.

Objectif du dossier : le mapping complet du rig pour Elite Dangerous — deux
Virpil Alpha Prime en HOSAS (le gauche monté sur coude), throttle
MongoosT-50CM3, panneau WinWing PTO2 — et **un tutoriel par métier**, parce
qu'Elite ne se joue pas de la même façon selon qu'on mine, qu'on explore ou
qu'on chasse la prime. Le découpage par activité remplace le cursus générique
en sept sections des tutoriels DCS : ici, c'est le métier qui structure.

La conception du mapping est dans
[CONCEPTION-MAPPING.md](CONCEPTION-MAPPING.md) : mécanique de contextes propre
à Elite, décompte des commandes, allocation proposée périphérique par
périphérique, et les six décisions à trancher.

> **La session d'écriture des binds a sa propre note d'entrée :**
> [PREPARATION-BINDING.md](PREPARATION-BINDING.md). Elle liste ce qu'il y a à
> faire côté matériel avant de commencer, la chaîne d'outils prête à tourner,
> les huit décisions qui attendent une réponse et le déroulé proposé. Commencer
> par là plutôt que par ce fichier.

## Fait

- **Chaîne de données.** `tools/parse-ed-binds.ps1` lit le fichier `.binds`
  écrit par le jeu et produit `ED/data/ed-bindings.json` (périphériques
  VID/PID, axes, boutons, modificateurs, appuis longs, inversions, zones
  mortes, réglages) et `ED/data/ed-actions.json` (catalogue complet du schéma
  d'actions). Le script détecte le preset actif via `StartPreset.*.start` et
  signale les **conflits réels** — deux actions du même contexte sur la même
  entrée, ce que le jeu affiche en rouge. Format et pièges documentés dans
  `tools/README.md`.
- **Catalogue d'actions.** `ED/data/ed-actions.json` : **514 actions**
  (70 axes, 352 boutons, 92 réglages), avec pour chacune son contexte, sa
  couche de vol et le fait qu'elle accepte ou non le maintien. Contrairement à
  Star Citizen, Elite écrit tout son schéma dans le fichier, y compris les
  actions non assignées : le catalogue est exhaustif dès la première lecture.
  Extrait d'un `.binds` de référence 4.2 (voir sources du document de
  conception) en attendant l'export du rig réel.
- **Libellés français.** `ED/data/ed-labels-fr.json`, écrit à la main, jamais
  touché par le script : **201 actions** traduites et expliquées — la
  totalité du noyau vaisseau, plus les contextes SRV, FSS, DSS, interface, vue
  et équipage. Chaque nom a été recoupé avec le catalogue : aucun n'est
  inventé.
- **Conception du mapping** — proposition complète, sources citées, six
  décisions posées.
- **Chaîne de mapping, testée de bout en bout.**
  `tools/collect-ed-rig.ps1` relève le rig en une passe (sauvegarde du dossier
  Bindings, presets et preset actif, périphériques vus par le jeu avec le plus
  grand numéro de bouton lu, détection des chaînes VID+PID en double, et diff
  avec le relevé précédent pour sonder les numéros hauts).
  `ED/data/ed-mapping-plan.json` traduit la section 4 de la conception en
  données : 12 axes et 81 boutons, chacun avec son repère physique, sa raison
  et deux marqueurs (`statut`, `confiance`) — 82 entrées applicables, 11 en
  attente de décision. `tools/validate-ed-mapping.py` refuse un plan
  incohérent sur dix règles (action inexistante, mauvais type, `toggleOn`
  illégal, plus de deux emplacements pour une action, conflit de même
  contexte, commande critique laissée en attente…) ; les treize règles ont été
  testées contre des plans volontairement cassés.
  `tools/apply-ed-mapping.py` écrit le plan **dans le `.binds` du jeu** plutôt
  que d'en fabriquer un, avec sauvegarde horodatée, et porte un `--autotest`
  qui vérifie la chaîne sans aucun fichier du jeu. Vérifié en bout en bout :
  le fichier produit est relu par `parse-ed-binds.ps1` — outil indépendant —
  qui y voit les quatre périphériques, les 82 binds, la couche de modificateur
  inter-périphérique et **aucun conflit**.
- **Quatre trous de la proposition publiée** trouvés en la traduisant en
  données, et documentés : `UI_*` assigné nulle part, trois touches pour une
  action qui n'a que deux emplacements, portée du scanner proposée trois fois,
  direction de chaque action dans un hat non précisée. Détail et propositions
  dans [PREPARATION-BINDING.md](PREPARATION-BINDING.md) § 3.
- **Accueil et sommaire.** Elite Dangerous partage la rangée « Simulation
  spatiale » de la page d'accueil avec Star Citizen ; `ED/index.html` liste les
  pages livrées, les planches à venir et les dix tutoriels par métier.
- **Page vaisseaux** — `ED/vaisseaux.html` : les 47 coques pilotables, avec
  rôle, résumé et note, filtrables par métier, taille de plateforme et budget,
  plus une vue tableau triable sur douze colonnes. Les caractéristiques sont
  dérivées de la base **Coriolis** (`EDCD/coriolis-data`) par
  `tools/build-ed-ships.py` — aucun chiffre n'est saisi à la main. Les rôles et
  les textes vivent dans `ED/data/ed-ships-fr.json`, écrit à la main.
- **Page ressources** — `ED/ressources.html` : outils du quotidien (Inara,
  EDSM, Spansh, Coriolis), applications à installer (EDMC, EDDiscovery, EDDI,
  EDDN), documentation officielle, **communauté francophone** (Remlok
  Industries, Deep Space Network, Mille-Sabords, ComTAC) et chaînes vidéo.
  Sélection établie le 3 septembre 2026.

## À faire, dans l'ordre

### 1 à 3. Relevé matériel et décisions — voir la note de passation

Les trois premières étapes (PID distincts sur les deux Alpha Prime — bloquant,
relevé matériel, décisions à trancher) sont détaillées dans
[PREPARATION-BINDING.md](PREPARATION-BINDING.md), avec les manipulations
exactes, les commandes à lancer et le déroulé de la session. Elles ne sont pas
répétées ici.

Résumé : changer le PID de l'un des deux manches dans le VPC Configuration
Tool, assigner une commande jetable sur chacun des quatre périphériques depuis
l'écran Contrôles du jeu, quitter proprement, puis

```
powershell -ExecutionPolicy Bypass -File tools\collect-ed-rig.ps1
```

et commiter `ED/data/releve-rig.json`.

### 4. Gabarits et planches interactives — `ED/mapping-hotas.html`

Même mécanique que `F14BU/mapping-hotas.html` : onglets par périphérique,
étiquettes en pourcentage sur l'image, survol liant l'étiquette à sa ligne de
tableau par un index commun, filtres par catégorie, impression.

Les gabarits sont **déjà dans le dépôt**, rassemblés pour Star Citizen — le
rig est le même :

| Périphérique | Substrat | État |
| --- | --- | --- |
| Manche droit | `SC/img/VPC_Constellation_ALPHA_Prime_R.svg` | 824 × 1166, boutons 1 à 32 à coordonnées exactes |
| Manche gauche | `SC/img/VPC_Constellation_ALPHA_Prime_L.svg` | idem |
| Throttle | `SC/img/throttle.png` | gabarit officiel Virpil, 1 à 55 et les 5 crans du rotacteur MODE |
| PTO2 | `SC/img/PTO 2 Panel of Take Off.svg` | 41 emplacements `Button_1…41` exploitables par script |

Ajout propre à Elite : un **sélecteur de contexte** (vaisseau · SRV · à pied ·
FSS · DSS · équipage) plutôt qu'un sélecteur de couche de modificateur —
c'est le contexte qui multiplie le mapping ici. En pastille
`position:absolute`, pour ne jamais changer la hauteur d'une boîte
d'étiquette.

### 5. Les tutoriels, un par métier

Progression en `localStorage` comme les tutoriels DCS, moteur partagé
`css/tutoriel.css` + `js/tutoriel.js`. Trois fondamentaux communs, puis un
module par activité — le sommaire de `ED/index.html` fait déjà foi.

**Fondamentaux** — servent dans tous les métiers :

| | Module | Contenu prévu |
| --- | --- | --- |
| A | Prise en main | Le rig et les six axes, la manette des gaz et **la zone bleue**, assistance de vol maintenue sur la palette, focus interface et les quatre panneaux |
| B | Naviguer | Carte galactique et tracé de route, supercroisière, saut hyperespace, ravitaillement stellaire, décélération et approche orbitale |
| C | Se poser et s'amarrer | Demande d'amarrage, train, verrouillage de rotation, pad, amarrage automatique, atterrissage planétaire |

**Les métiers** :

| | Module | Contenu prévu |
| --- | --- | --- |
| 1 | Commerce et fret | Lire les cours sur Inara, monter une boucle rentable, contrebande et marché noir, objectifs communautaires |
| 2 | Chasse à la prime | Zones de résurgence, scan de délit, **triangle d'énergie**, sous-systèmes, armes fixes et gimbal, leurres et dissipateur, savoir rompre |
| 3 | Exploration | Mode analyse, scan de découverte, **FSS** et accord fréquentiel, **DSS** et largage de sondes, valeur des corps, frôlement d'étoile |
| 4 | Minage | Choisir un anneau et lire les points chauds, laveur et raffinerie, drones prospecteurs et collecteurs, minage au noyau à l'explosif |
| 5 | Transport de passagers | Cabines et classes, exigences des VIP, missions de tourisme, gestion de la chaleur et discrétion |
| 6 | Récupération et sauvetage | Épaves et sources de signal, collecte de matériaux, secours aux stations en feu |
| 7 | Exobiologie | Repérer une planète vivante depuis le FSS, échantillonner à pied à la bonne distance, valoriser les découvertes |

**Aller plus loin** :

| | Module | Contenu prévu |
| --- | --- | --- |
| 8 | Au sol : SRV et à pied | Conduite et tourelle du SRV, collecte au sol ; à pied (Odyssey) : combinaisons, outils, avant-postes |
| 9 | Ingénierie | Débloquer les ingénieurs, récolter les matériaux, choisir ses modifications, effets expérimentaux |
| 10 | Équipage et pouvoirs | Multi-équipage, escadrilles, chasseurs télépilotés, Powerplay, colonisation |

Chaque leçon renvoie vers la planche de mapping par un badge cliquable, comme
sur les pages DCS : les numéros de bouton ne sont jamais écrits en dur dans le
texte. Chaque métier renvoie aussi vers les coques adaptées de
[`vaisseaux.html`](vaisseaux.html), par le filtre de rôle correspondant.

**Sur les sources.** Les gestes se rédigent d'après les guides et les vidéos
listés dans [`ressources.html`](ressources.html) ; tout chiffre daté — prix
d'une marchandise, meilleur point d'extraction, rendement horaire — reste hors
du texte et renvoie vers Inara ou Spansh. Un guide de minage de 2021 est
excellent sur la méthode et faux sur les prix.

> Note de méthode : la sélection de ressources a été établie par recherche web
> depuis cette session, mais le proxy réseau de l'environnement bloque la
> plupart de ces domaines — le contenu des pages n'a donc pas pu être relu
> directement. Les liens sont à revalider une fois, à la main, avant d'appuyer
> une leçon dessus.

### 6. Export depuis le navigateur — `ED/export-bindings.html`

**L'écriture des binds est déjà faite en ligne de commande** par
`tools/apply-ed-mapping.py`, qui modifie le `.binds` du jeu depuis le plan et
sauvegarde l'ancien. Cette page ne reste utile que pour le confort : produire
le fichier sans ouvrir un terminal, et voir le mapping avant de l'installer.

Si elle est écrite, elle doit reprendre les mêmes garde-fous que l'outil en
ligne de commande :

- **sauvegarder le fichier existant avant de l'écraser** ;
- partir du `.binds` du jeu plutôt que d'en fabriquer un : Elite attend le
  schéma **complet**, y compris les actions laissées en `Device="{NoDevice}"`,
  et le fichier du jeu porte déjà le bon numéro de version (`MajorVersion` /
  `MinorVersion`) — un fichier `4.0` n'est pas lu par un jeu qui attend `4.2` ;
- mettre à jour `StartPreset.*.start` pour que le preset soit sélectionné au
  lancement ;
- vérifier qu'aucune entrée ne porte deux actions du même contexte — les deux
  scripts signalent déjà ces conflits.

## Rappel

Ce dossier ne touche à rien des tutoriels DCS existants. Les seules pages
partagées sont `index.html` (catégories d'accueil), `README.md`,
`tools/README.md` et les gabarits d'images du dossier `SC/img/`.
