# Outils de bindings

Deux chaînes indépendantes :

- **DCS World** — transforme le mapping HOTAS défini dans le site en fichiers
  `.diff.lua` installables (scripts Lua, exécutés par l'interpréteur de DCS).
- **Star Citizen** — lit les profils `layout_*.xml` exportés par le jeu et
  produit les JSON du dossier `SC/data/` (script PowerShell, aucune
  dépendance). Voir [Star Citizen](#star-citizen) en fin de fichier.

## Outils d'export de bindings DCS

Chaîne qui transforme le mapping HOTAS défini dans le site en fichiers
`.diff.lua` installables dans DCS World.

## Prérequis

DCS World installé. Les scripts s'exécutent avec l'interpréteur Lua 5.1 fourni
par le jeu — rien à installer :

```bash
"J:\DCS World\bin\luae.exe" tools\extract-commands.lua
```

Chaque script porte un bloc `CONFIG` en tête. Le dossier `Saved Games` est
déduit de `%USERPROFILE%`. Si DCS n'est pas installé dans `J:\DCS World`,
renseigner la variable d'environnement `DCS_ROOT` :

```bash
DCS_ROOT="C:/Program Files/Eagle Dynamics/DCS World/" "J:\DCS World\bin\luae.exe" tools\extract-commands.lua
```

Ajuster aussi `locales` dans `harvest-game-commands.lua` selon la langue de
l'interface DCS, et `instances` si les dossiers `Saved Games` diffèrent.

## Le format de bind DCS

DCS stocke les commandes dans
`Saved Games\<instance>\Config\Input\<Avion>\<type>\<Périphérique {GUID}>.diff.lua`.

C'est un fichier de **différences** par rapport au profil par défaut du module,
pas la liste complète des binds :

```lua
local diff = {
	["keyDiffs"] = {
		["d3137pnilu3137cd55vd1vpnilvu0"] = {
			["added"] = { [1] = { ["key"] = "JOY_BTN1" } },
			["name"] = "Master Arm On and Cover Open, else Safe and Closed",
		},
	},
}
return diff
```

La clé est un **hash déterministe de la commande** — c'est elle qui fait
l'identité. Le champ `name` n'est que du confort de lecture : DCS ne s'en sert
pas pour retrouver la commande.

| Segment | Sens |
| --- | --- |
| `d<id>` / `p<id>` / `u<id>` | commande down / pressed / up, `nil` si absente |
| `cd<id>` | `cockpit_device_id`, `nil` pour une commande jeu |
| `vd` / `vp` / `vu` | `value_down` / `value_pressed` / `value_up` |
| `a<id>cd<id>` | forme utilisée pour les axes |

Sections possibles sous une clé : `added` (ajoute un bind), `removed` (retire
un bind par défaut), `changed` (axe : courbe, deadzone, saturation, inversion).

## Les scripts

### `extract-commands.lua`

Charge la cascade de profils d'entrée du mod F14BU avec un environnement DCS
simulé, résout les IDs numériques et calcule le hash de chaque commande.

La cascade suivie :

```
F14BU/Input/F-14BU-Pilot/joystick/default.lua
  └─ F14/Input/F-14-Pilot/joystick/default.lua
       └─ F14/Input/F-14/... └─ Config/Input/Aircrafts/common_keyboard_binding.lua
  + F14/Cockpit/devices.lua + command_defs.lua   (les IDs numériques)
```

Sortie : `F14BU/data/f14bu-commands.json`, consommé par la page web.

### `harvest-game-commands.lua`

Les constantes `iCommandXxx` / `ICommandXxx` (vues, freins, trim, comms) sont
injectées par le moteur C++ et n'apparaissent dans aucun `.lua` : leur hash est
incalculable par lecture statique.

Ce script le récupère dans les `.diff.lua` déjà écrits par DCS, où chaque entrée
porte à la fois sa clé et son libellé. Comme DCS écrit ces libellés dans la
langue de l'interface, il lit aussi les catalogues gettext du jeu
(`l10n/<langue>/LC_MESSAGES/*.mo`) pour retrouver le nom anglais du catalogue.

Sortie : `tools/game-commands-cache.lua`. À relancer avant `extract-commands.lua`.

### `extract-generic-commands.lua`

Extrait de `Config/Input/Aircrafts/base_joystick_binding.lua` les commandes
communes à tous les avions (tangage, roulis, lacet, gaz, trims, vues…), puis
vérifie empiriquement que chaque nom correspond au même hash dans les profils
de tous les avions du joueur. Sortie : `data/dcs-generic-commands.json`, avec
pour chaque commande son statut :

- `verified` — hash identique partout où la commande a été observée ;
- `majority` — quelques modules hors standard (C-101 et Mirage F1 pour les
  axes de vol, A-10C pour le trim, F-86 pour les volets, L-39/MiG-19 pour la
  position atterrissage), listés dans `excluded` ;
- `unseen` — jamais bindée chez le joueur, hash inconnu à ce jour.

Ce catalogue alimente le profil « Tous avions » de la page d'export : un même
fichier `.diff.lua` copiable dans le dossier joystick de chaque avion.

### `validate-hash.lua`

Filet de sécurité. Recalcule les hash du profil F-14 Heatblur et vérifie qu'ils
apparaissent tels quels dans les `.diff.lua` réels du joueur. Une erreur de
formule produirait des fichiers silencieusement ignorés par DCS.

Les « hash cockpit absents » signalés ne sont pas des erreurs : ce sont des
commandes que le module a modifiées depuis l'écriture du profil.

## Ordre d'exécution

```bash
"J:\DCS World\bin\luae.exe" tools\validate-hash.lua
"J:\DCS World\bin\luae.exe" tools\harvest-game-commands.lua
"J:\DCS World\bin\luae.exe" tools\extract-commands.lua
```

## Deux pièges rencontrés

**Collision de noms.** Un même libellé couvre parfois deux commandes
distinctes : « Flaps Up » existe en version jeu (`iCommandPlaneFlapsOff`,
catégorie *Systems*) et en version cockpit (`FLAPS_Lever_Key`, *Flight
Control*). Le nom seul n'est pas une clé — toujours le coupler à la catégorie.

**Deux graphies.** Le moteur expose ses constantes en `iCommandXxx` *et*
`ICommandXxx` (`ICommandSwitchDialog`). Filtrer sur la seule minuscule en rate
une partie.

---

# Star Citizen

## `parse-sc-layout.ps1`

Lit un profil exporté par le jeu et écrit les données consommées par les pages
du dossier `SC/`.

```bash
powershell -ExecutionPolicy Bypass -File tools\parse-sc-layout.ps1
```

Sans argument, le script prend le fichier le plus récent de
`<install SC>\LIVE\user\client\0\Controls\Mappings\`. Arguments utiles :
`-ScRoot`, `-Channel LIVE|PTU`, `-Layout <nom.xml>`, `-OutDir`.

Sorties, **régénérées à chaque exécution** :

| Fichier | Contenu |
| --- | --- |
| `SC/data/sc-bindings.json` | le profil courant : périphériques (nom, GUID, courbes, zones mortes), binds (actionmap, action, axe ou bouton, couche de modificateur, mode d'activation) |
| `SC/data/sc-actions.json` | catalogue des noms d'action rencontrés dans tous les layouts balayés, avec leur actionmap et les fichiers d'origine |

`SC/data/sc-labels-fr.json` (libellés et descriptions françaises) est écrit à
la main et **n'est jamais touché** par le script.

## Le format de profil Star Citizen

Le jeu exporte un XML unique par profil :

```xml
<ActionMaps version="1" profileName="BK_TriplePrime_4-8">
  <options type="joystick" instance="1" Product="RIGHT VPC Stick WarBRD-D  {43F53344-…}">
    <flight_move_pitch exponent="1.2"/>
  </options>
  <deviceoptions name="LEFT VPC Stick WarBRD-D  {83F43344-…}">
    <option input="rotx" deadzone="0.198"/>
  </deviceoptions>
  <actionmap name="spaceship_movement">
    <action name="v_space_brake"><rebind input="js1_button4"/></action>
  </actionmap>
</ActionMaps>
```

Ce qu'il faut en retenir :

- L'entrée s'écrit `js<instance>_<contrôle>` : `js2_button31`, `js3_rotz`,
  `js1_slider1`. Un modificateur se préfixe : `js1_rctrl+button31` — le profil
  du rig s'en sert comme couche secondaire.
- `Product` porte le nom **et** le GUID du périphérique, exactement comme le
  nom de fichier `.diff.lua` de DCS. **Ces GUID dérivent** : entre deux exports
  du même rig, le GUID du manche droit est devenu celui du gauche. Toujours
  relire le fichier réel plutôt qu'un ancien profil.
- `input=" "` (une espace) n'est pas un bind : c'est une commande *effacée*
  dans les options du jeu.
- L'export ne contient que ce que le joueur a modifié. Un axe laissé au réglage
  d'usine n'y figure pas — le manche droit peut piloter le tangage sans qu'aucun
  `<rebind>` ne le mentionne, seule la courbe (`exponent`) trahit son usage. Un
  fichier généré de zéro doit donc déclarer explicitement tous les axes voulus.
- Une même entrée physique portant plusieurs actions n'est pas forcément un
  conflit : Star Citizen définit les appuis court / long / double dans son
  profil par défaut, que l'export ne reproduit que s'ils ont été modifiés. Le
  script les signale sous `sharedInputs`, à relire au cas par cas.

Installation d'un profil : déposer le XML dans le dossier `Mappings`, puis dans
la console du jeu (touche `²` / `~`) :

```
pp_rebindkeys <nom_du_layout_sans_extension>
```

## Piège d'environnement

Sur ce poste, PowerShell 5.1 lève `Les types des arguments ne correspondent
pas` sur `@($liste)` quand l'objet est une `System.Collections.Generic.List[T]`
— `[object[]]`, `.ToArray()` et le pipeline fonctionnent. Le script n'utilise
donc que des tableaux natifs.

---

# Recherche globale du site

## `build-search-index.py` / `build-search-index.ps1`

Régénère `data/search-index.json`, l'index consommé par `js/site-search.js`
(bouton de recherche flottant présent sur toutes les pages). Python 3, aucune
dépendance :

```bash
python3 tools/build-search-index.py
```

Sur une machine sans Python — c'est le cas de la machine de dev, où `python`
n'est que le raccourci Microsoft Store — utiliser le port PowerShell, qui
produit le même fichier :

```bash
powershell -ExecutionPolicy Bypass -File tools/build-search-index.ps1
```

Les deux scripts sont volontairement redondants : **corriger l'un implique de
corriger l'autre**. Seule différence connue, sans effet fonctionnel : à clé de
tri égale, l'ordre des entrées ex æquo peut différer (`sorted()` de Python est
stable, `[Array]::Sort` ne l'est pas).

Trois familles d'entrées, décrites en tête du script :

- **page** — une par fichier HTML, titre = balise `<title>`.
- **leçon** — extraites des tableaux JS `id:"xx", title:"…"` /
  `id:"xx", …, nm:"…"` des pages `section-*.html` de chaque avion.
- **fonction** — commandes HOTAS non vides de chaque `data/*-bindings.json`
  trouvé sous un dossier avion, avec lien profond
  `mapping-hotas.html?dev=<périphérique>&n=<n>` (même mécanique que les
  badges `data-bind-cmd` des tutoriels).

À relancer après toute modif d'une page `section-*.html`, d'un `<title>`, ou
d'un fichier `*-bindings.json`. Quand un même intitulé de leçon ou de
fonction existe sur plusieurs avions (détecté après normalisation
accents/casse), `site-search.js` l'affiche préfixé `<Avion> — <Sujet>` pour
lever l'ambiguïté ; sinon le sujet seul suffit.
