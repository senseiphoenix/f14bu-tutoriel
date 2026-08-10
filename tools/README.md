# Outils d'export de bindings DCS

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
