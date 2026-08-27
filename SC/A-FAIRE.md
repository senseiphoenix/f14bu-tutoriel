# Star Citizen — état et suite du travail

Dernière mise à jour : 12 août 2026.

Objectif du dossier : une aide au pilotage de vaisseau et, surtout, le mapping
complet du rig — deux Virpil Alpha Prime en HOSAS (le gauche monté sur coude,
tenu comme un guidon de moto), throttle MongoosT-50CM3 et panneau WinWing PTO2.
**Le pédalier Fanatec sort du périmètre** (décidé le 28 août 2026).

La conception du mapping est dans [CONCEPTION-MAPPING.md](CONCEPTION-MAPPING.md) :
principes, inventaire physique des quatre périphériques, allocation proposée
commande par commande, et les trois décisions à trancher.

## Fait

- **Chaîne de données.** `tools/parse-sc-layout.ps1` lit le profil exporté par
  le jeu et régénère `data/sc-bindings.json` (périphériques, GUID, axes,
  boutons, couches de modificateur, courbes, zones mortes) et
  `data/sc-actions.json` (catalogue des noms d'action rencontrés). Format du
  XML et pièges documentés dans `tools/README.md`.
- **Libellés français.** `data/sc-labels-fr.json`, écrit à la main, jamais
  touché par le script : 303 actions traduites et expliquées, soit 100 % du
  profil courant plus 76 actions gardées pour la refonte du mapping.
- **Accueil et sommaire.** Catégories sur la page d'accueil du site, et cette
  page `SC/index.html` avec les planches et le cursus prévus.
- **Inventaire des images**, voir `img/LISEZMOI.txt`.

Profil courant lu : `layout_BK_TriplePrime_4-8_exported.xml`, 238 binds,
3 périphériques, 2 couches (base et `rctrl`).

## À faire, dans l'ordre

### 1. Relevé matériel — bloquant

Brancher les cinq périphériques, binder une commande quelconque sur le PTO2 et
sur les pédales dans Star Citizen, puis exporter le profil depuis le jeu
(Options → Keybindings → Export). Objectif : figer l'ordre `js1…js5` réel, les
noms et les GUID actuels.

Les GUID dérivent : entre deux exports du même rig, celui du manche droit est
devenu celui du gauche. Ne jamais faire confiance à un ancien profil.

Puis régénérer :

```
powershell -ExecutionPolicy Bypass -File tools\parse-sc-layout.ps1
```

**Pourquoi ce relevé compte vraiment.** Le profil courant `BK_TriplePrime_4-8`
porte exactement les mêmes GUID que le profil communautaire rangé dans
`SC/profile exemple/` — il en dérive. Or ce profil a été fabriqué sur des
gimbals **WarBRD**, ce que ses chaînes `Product` disent encore
(`RIGHT VPC Stick WarBRD-D`), alors que les fichiers écrits par DCS sur cette
machine annoncent des gimbals **MT-50CM3** (`R-VPC Stick MT-50CM3`).

Hypothèse à confirmer : Star Citizen conserve les noms et GUID du profil
importé tant que le périphérique n'a pas été rebindé, auquel cas les
identifiants du fichier actuel décrivent la machine de l'auteur du profil, pas
la nôtre. Les fichiers DCS, eux, sont écrits par le jeu lui-même ici : ils font
foi pour le matériel réel. Seul un export frais après avoir bindé chaque
périphérique tranchera.

### 2. Gabarits — fait

Les deux grips ont leur gabarit Joystick Diagrams, copiés dans `SC/img/` :
`VPC_Constellation_ALPHA_Prime_R.svg` et `_L.svg`, 824 × 1166, boutons 1 à 32 à
coordonnées exactes plus les axes. Le throttle a le gabarit officiel Virpil
(`SC/img/throttle.png`, 1 à 55 et le rotacteur MODE), le PTO2 son SVG
Joystick Diagrams (41 positions).

Les gabarits `nOHbWwB.png` et `Yogidragon Dual Alpha Template.png` sont des
**Constellation ALPHA**, pas des Prime : ne pas s'en servir comme planche.

### 3. Conception du mapping HOSAS

Référence à dépouiller d'abord : `SC/profile exemple/Dual Virpil Alpha Prime/`
— profil communautaire pour deux Alpha Prime en 4.8 (238 binds), avec ses deux
fiches PDF, vaisseau et sol. **Il exige JoyToKey pour fonctionner** : une part
des commandes passe par de l'émulation clavier plutôt que par des binds natifs.
À décider explicitement : on garde cette dépendance, ou on vise un profil qui
tient en binds natifs. Ce dossier reste hors dépôt, il pèse 15 Mo.

Refonte complète, pas une reprise de l'existant. À présenter avec ses sources
**avant** d'écrire du code, conformément à `CLAUDE.md` :

- s'appuyer sur la taxonomie officielle du jeu — modes maîtres **NAV / SCM**
  comme axe de phase, actionmaps comme catégories — plutôt que d'inventer des
  thèmes ;
- répartition manche gauche (translation) / manche droit (rotation), rôle du
  throttle, du PTO2 et des pédales, contenu des couches ;
- les fonctions critiques restent à position **fixe**, hors couche : éjection,
  contre-mesures, frein spatial, découplage, boost, triangle d'énergie.

### 4. Planches interactives — `SC/mapping-hotas.html`

Même mécanique que `F14BU/mapping-hotas.html` : onglets par périphérique,
étiquettes placées en pourcentage sur l'image, survol liant l'étiquette à sa
ligne de tableau par un index commun, filtres par catégorie, mode édition avec
magnétisme sur les cases, export des positions, impression.

Matière déjà disponible :

| Périphérique | Substrat | État |
| --- | --- | --- |
| Manche droit | `images/alphra prime right.png` | coordonnées des 32 boîtes déjà dans `F14BU/mapping-hotas.html` (tableau `LABELS`, entrées `stick`) |
| Manche gauche | à obtenir, voir étape 2 | — |
| PTO2 | `SC/img/PTO 2 Panel of Take Off.svg` | 41 emplacements `Button_1…41` avec coordonnées exactes dans le SVG, exploitables par script |
| Throttle | `SC/img/throttle.png` | gabarit officiel Virpil « VPC MongoosT-50CM3 Throttle », boîtes numérotées 1 à 55, axes X, Y, Z, rX, rY, rZ, et les 5 crans du rotacteur MODE (OFF, bleu, vert, rouge, jaune) |
| Pédales | `F14BU/img/pedals_fanatec_csl_elite_v2.webp` | réutilisable |

Ajout propre à Star Citizen : un sélecteur de couche (base / `rctrl`, et
NAV / SCM si la conception le retient), en pastille `position:absolute` pour ne
jamais changer la hauteur d'une boîte d'étiquette.

### 5. Le coude « guidon moto »

Bloc dédié : ce que l'inclinaison change dans la correspondance geste ↔ axe sur
le manche gauche, et le twist qui devient une poignée d'accélérateur. Il manque
une photo du manche gauche avec son coude — pour l'illustration seulement,
l'inventaire des commandes est déjà couvert par le gabarit.

### 6. Cursus de pilotage

Sept sections, progression en `localStorage` comme les tutoriels DCS : prise en
main et modes maîtres, décoller et naviguer, se poser et s'amarrer, combattre,
les métiers, hors du siège, équipage.

### 7. Export installable — `SC/export-bindings.html`

Génère le `layout_*.xml` à déposer dans le dossier `Mappings` du jeu, avec le
rappel de la commande console `pp_rebindkeys <nom>`.

Points de vigilance : sauvegarder le fichier existant avant de l'écraser ;
déclarer **explicitement tous les axes**, puisque l'export du jeu ne contient
que ce qui a été modifié et qu'un axe laissé d'usine n'y figure pas ; vérifier
qu'aucune entrée ne porte deux actions par erreur.

## Rappel

Ce dossier ne touche à rien des tutoriels DCS existants. Les seules pages
partagées sont `index.html` (catégories d'accueil), `README.md` et
`tools/README.md`.
