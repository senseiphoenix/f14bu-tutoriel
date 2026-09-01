# Elite Dangerous — état et suite du travail

Dernière mise à jour : 1er septembre 2026.

Objectif du dossier : le mapping complet du rig pour Elite Dangerous — deux
Virpil Alpha Prime en HOSAS (le gauche monté sur coude), throttle
MongoosT-50CM3, panneau WinWing PTO2 — et un cursus de pilotage en sept
sections, sur le modèle des tutoriels DCS du dépôt.

La conception du mapping est dans
[CONCEPTION-MAPPING.md](CONCEPTION-MAPPING.md) : mécanique de contextes propre
à Elite, décompte des commandes, allocation proposée périphérique par
périphérique, et les six décisions à trancher.

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
- **Accueil et sommaire.** Catégorie sur la page d'accueil du site, et cette
  page `ED/index.html` avec les planches et le cursus prévus.

## À faire, dans l'ordre

### 1. Donner deux PID distincts aux deux Alpha Prime — bloquant

Elite Dangerous désigne un périphérique par sa chaîne **VID+PID**
(`Device="3344012F"`), pas par un GUID. Deux Alpha Prime sortis d'usine
portent la même chaîne : le jeu les confond, et un bind posé sur l'un vaut
pour l'autre.

Ouvrir le **VPC Configuration Tool**, onglet *Profile*, changer le PID de l'un
des deux manches, écrire le firmware, rebrancher. Vérifier ensuite dans
l'écran Contrôles du jeu que les deux manches réagissent séparément.

Sans cette étape, **aucun bind HOSAS ne peut être écrit**.

### 2. Relevé matériel

Une fois les PID distincts : brancher les quatre périphériques, assigner une
commande quelconque sur chacun depuis l'écran Contrôles du jeu, quitter
proprement, puis :

```
powershell -ExecutionPolicy Bypass -File tools\parse-ed-binds.ps1
```

Objectifs du relevé :

- figer les chaînes VID+PID réelles des quatre périphériques ;
- vérifier **jusqu'à quel numéro de bouton** le jeu lit chaque périphérique
  (le profil de référence prouve `Joy_74` ; les pages Rouge et Jaune du
  rotacteur MODE du CM3 montent à 79 sur ce rig) ;
- confirmer que les axes `_Landing` laissés vides ne coupent pas les axes
  normaux train sorti.

Régénérer les JSON après chaque sauvegarde de preset depuis le jeu.

### 3. Trancher les six décisions

Voir [CONCEPTION-MAPPING.md](CONCEPTION-MAPPING.md) § 5 : distinction des
manches (faite à l'étape 1), relevé matériel, pédalier, twist gauche, plage de
la manette des gaz, focus interface maintenu ou basculé.

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

### 5. Cursus de pilotage — sept sections

Progression en `localStorage` comme les tutoriels DCS, moteur partagé
`css/tutoriel.css` + `js/tutoriel.js`.

| | Section | Contenu prévu |
| --- | --- | --- |
| A | Prise en main | Le rig et les six axes, la manette des gaz et **la zone bleue**, assistance de vol et son maintien sur la palette, le focus interface et les quatre panneaux |
| B | Naviguer | Carte galactique et tracé de route, supercroisière, saut hyperespace, ravitaillement stellaire, décélération et approche orbitale |
| C | Se poser et s'amarrer | Demande d'amarrage, train, verrouillage de rotation, pad, amarrage automatique, atterrissage planétaire |
| D | Combattre | Points durs et groupes de feu, **triangle d'énergie**, ciblage et sous-systèmes, armes fixes et gimbal, leurres, dissipateur, cellule de bouclier, silence radio |
| E | Explorer | Mode analyse, scan de découverte, **FSS** et accord fréquentiel, **DSS** et largage de sondes, cartographie et valeur des corps |
| F | Au sol | SRV : conduite, tourelle, collecte ; à pied (Odyssey) : combinaisons, outils, avant-postes |
| G | Métiers et équipage | Minage, commerce et cargaison, multi-équipage, tourelles, ordres au chasseur |

Chaque leçon renvoie vers la planche de mapping par un badge cliquable, comme
sur les pages DCS : les numéros de bouton ne sont jamais écrits en dur dans le
texte.

### 6. Export installable — `ED/export-bindings.html`

Génère le `Custom.4.x.binds` à déposer dans
`%LOCALAPPDATA%\Frontier Developments\Elite Dangerous\Options\Bindings\`.

Points de vigilance :

- **sauvegarder le fichier existant avant de l'écraser** ;
- écrire le schéma **complet** : Elite attend toutes les actions dans le
  fichier, y compris celles laissées en `Device="{NoDevice}"` ;
- respecter le numéro de version du schéma (`MajorVersion` / `MinorVersion`)
  du fichier écrit par la version du jeu installée — un fichier `4.0` n'est
  pas lu par un jeu qui attend `4.2` ;
- mettre à jour `StartPreset.*.start` pour que le preset soit sélectionné au
  lancement ;
- vérifier qu'aucune entrée ne porte deux actions du même contexte : le script
  de lecture signale déjà ces conflits.

## Rappel

Ce dossier ne touche à rien des tutoriels DCS existants. Les seules pages
partagées sont `index.html` (catégories d'accueil), `README.md`,
`tools/README.md` et les gabarits d'images du dossier `SC/img/`.
