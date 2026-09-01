# Elite Dangerous — conception du mapping HOSAS

Document de conception, à valider avant toute écriture de binds.
Rig visé : **HOSAS (deux Virpil Alpha Prime) + throttle MongoosT-50CM3 +
panneau WinWing PTO2**, le même que pour Star Citizen. Le pédalier reste hors
périmètre par défaut (voir décision 3).

Tout ce qui est affirmé ici sur le format et sur le comportement du jeu vient
de la lecture d'un fichier `.binds` réel (schéma 4.2, 514 actions) et des
sources listées en fin de document — rien n'est déduit de mémoire.

---

## 1. Le principe qui change tout : ici, c'est le jeu qui change de contexte

Star Citizen range ses commandes par *actionmap* et laisse le joueur choisir
son mode opérateur. Elite Dangerous fait l'inverse : **c'est le jeu qui décide
dans quel contexte on est**, et le nom de l'action porte le contexte.

Le fichier de bindings contient un bloc par action, et le contexte se lit dans
le nom :

| Suffixe / préfixe | Contexte | Actions |
| --- | --- | --- |
| *(aucun)* | vaisseau | 129 |
| `Buggy…` / `…_Buggy` | SRV | 43 |
| `Humanoid…` / `…_Humanoid` | à pied (Odyssey) | 76 |
| `ExplorationFSS…` | scanner plein spectre | 19 |
| `…SAA…` | scanner de surface (sondes) | 13 |
| `MultiCrew…` / `Order…` | équipage, tourelles, chasseur | 23 |
| `Cam…` / `FreeCam…` / `Vanity…` | suite caméra | 67 |
| `…PlacementCam…` | colonisation | 29 |

**Conséquence de conception :** un même bouton physique porte déjà une action
différente dans chaque contexte, sans modificateur et sans rien à mémoriser —
parce qu'on ne peut pas être à pied et aux commandes du vaisseau en même
temps. Le SRV, le FSS, le DSS et l'EVA sont autant de mappings gratuits
posés sur les mêmes doigts.

### Les trois couches d'axes de vol, natives

Elite Dangerous fournit **trois jeux complets d'axes pilote**, visibles dans le
fichier :

| Couche | Noms | Bascule |
| --- | --- | --- |
| normale | `PitchAxisRaw`, `RollAxisRaw`, `YawAxisRaw`, `LateralThrustRaw`, `VerticalThrustRaw`, `AheadThrust` | — |
| atterrissage | `PitchAxis_Landing`, `RollAxis_Landing`… | **automatique** à la sortie du train |
| alternative | `PitchAxisAlternate`, `RollAxisAlternate`… | manuelle, `UseAlternateFlightValuesToggle` |

Le profil de référence dépouillé laisse les 23 entrées `_Landing` et
`Alternate` entièrement vides et vole correctement train sorti : les axes
normaux restent donc actifs quand la couche d'atterrissage n'est pas remplie.
**À confirmer en jeu avant de s'y fier.**

En HOSAS, ces deux couches ne servent à rien pour retrouver des degrés de
liberté — les deux manches donnent déjà les six. Elles ne valent que pour
*permuter volontairement* un axe (voir décision 4).

### Les autres multiplicateurs, du plus naturel au plus coûteux

1. **le contexte** — gratuit, c'est le jeu qui bascule ;
2. **le maintien du focus interface** (`UIFocus`) — redirige les manches vers
   les panneaux du cockpit ; réglable en maintenu (`Bindings_FocusModeHold`) ;
3. **l'appui long** — `<Hold Value="1"/>` sur un bind ;
4. **le modificateur** — natif, et **inter-périphérique** : le profil de
   référence maintient un bouton du manche gauche pour modifier un bouton du
   manche droit (`<Modifier Device="3344812F" Key="Joy_30"/>` sous une entrée
   du manche droit). Deux modificateurs peuvent se cumuler ;
5. **les pages du rotacteur MODE du throttle**.

### Bascule ou maintien : seules 26 actions ont le choix

Une action porte le choix bascule / maintien seulement si son bloc contient un
`<ToggleOn>`. Sur 352 actions à bouton du schéma, **26** l'ont. Dans le
contexte vaisseau et SRV :

`ToggleFlightAssist` · `ToggleCargoScoop` · `ToggleDriveAssist` ·
`UseAlternateFlightValuesToggle` · `DisableRotationCorrectToggle` ·
`ToggleReverseThrottleInput` · `HeadLookToggle` · `VerticalThrustersButton` ·
`YawToRollButton` · `MicrophoneMute` · `AutoBreakBuggyButton` ·
`ToggleCargoScoop_Buggy` · `BuggyToggleReverseThrottleInput`

Toutes les autres commandes « Toggle » du jeu — **train d'atterrissage, points
durs, phares, vision nocturne, lignes d'orbite, mode combat/analyse** — sont
des bascules pures : le jeu n'expose *aucune* commande ON et OFF séparées,
contrairement à DCS. C'est la contrainte majeure du PTO2, traitée au § 4.

## 2. Le problème n'est pas la place, c'est la discipline

Décompte du contexte vaisseau, hors réglages : 129 actions, dont 23 pour les
couches atterrissage/alternative, 15 équivalents « bouton » d'axes déjà tenus
par les manches, 9 vitesses fixes. **Noyau réellement utile : 82 commandes,
dont 7 axes.**

En face, le rig offre :

| Périphérique | Boutons | Axes |
| --- | --- | --- |
| Alpha Prime droit | 32 | X, Y, Z, SLDR + mini-stick rX/rY |
| Alpha Prime gauche | 32 | idem |
| MongoosT-50CM3 | 55 de base, **79** en comptant les cinq pages du rotacteur MODE | 6 |
| WinWing PTO2 | 41 | — |

Soit ~184 entrées pour 82 commandes de vaisseau. **Elite Dangerous tient
largement dans ce rig sans un seul modificateur en vol.** Le modificateur est
réservé aux réglages rares ; les pages du rotacteur MODE deviennent un confort
mnémotechnique, pas une nécessité.

> **Point à vérifier sur le rig réel.** Le profil de référence utilise
> `Joy_74` sur le throttle : le jeu lit donc au moins 74 numéros de bouton par
> périphérique. Les pages Rouge et Jaune du CM3 montent à 79 sur ce rig
> (relevé DCS) — à confirmer avant d'y placer quoi que ce soit d'utile.

## 3. Répartition par périphérique : qui tient quoi

Contrainte physique identique à Star Citizen : en HOSAS, **les deux mains sont
prises**. Mais Elite ajoute une contrainte propre — la **manette des gaz est
l'organe de pilotage central** du jeu (la « zone bleue » du bandeau de vitesse
donne le meilleur taux de virage), pas un simple limiteur. Le CM3 cesse donc
d'être un panneau de réglages : son levier principal est vital.

| Périphérique | Rôle | Contenu |
| --- | --- | --- |
| Manche droit | viser et tirer | rotation, ciblage, armes, senseurs, focus interface |
| Manche gauche | manœuvrer et survivre | translation, énergie, contre-mesures, assistance, FSD |
| Throttle CM3 | **la vitesse**, puis l'état | manette des gaz, portée scanner, accord FSS, pages métier |
| PTO2 | les états tenus | train, collecteur, feux, cartes, amarrage |

Reste hors couche, hors page et à position fixe : **assistance de vol, boost,
leurres, dissipateur, cellule de bouclier, triangle d'énergie**. Une avarie ne
prévient pas.

## 4. Allocation proposée

Les numéros de bouton des Alpha Prime et du CM3 sont ceux relevés sur ce rig
pour DCS et Star Citizen ; ils sont détaillés dans
[`../SC/CONCEPTION-MAPPING.md`](../SC/CONCEPTION-MAPPING.md) § 3 et ne sont pas
répétés ici.

### Manche droit — viser et tirer

| Commande | Action Elite | Pourquoi |
| --- | --- | --- |
| `X` `Y` | `RollAxisRaw`, `PitchAxisRaw` | le roulis oriente le plan de virage : c'est lui qui va sur l'axe le plus rapide |
| `Z` twist | `YawAxisRaw` | volontairement lent sur la plupart des vaisseaux, il n'affine que la visée |
| Gâchette cran 1 (**4**) | `PrimaryFire` | |
| Gâchette cran 2 (**5**) | `SecondaryFire` | |
| Palette (**7**) | `UIFocus`, **maintenue** | maintenir la palette redirige les hats vers les panneaux du cockpit : toute l'interface se pilote sans lâcher les manches |
| Mini-stick `rX`/`rY` + **6** | `HeadLookYawAxis`, `HeadLookPitchAxisRaw`, **6** = `HeadLookReset` | regard libre analogique sous le pouce |
| Hat A (**8-12**) | `SelectTarget` · `CycleNextHostileTarget` · `CyclePreviousHostileTarget` · `SelectTargetsTarget` · **8** = `SelectHighestThreat` | le geste le plus fréquent en combat |
| Hat B (**14-18**) | `CycleNextSubsystem` / `CyclePreviousSubsystem` · `CycleFireGroupNext` / `CycleFireGroupPrevious` · **14** = `DeployHardpointToggle` | armement et visée fine, sous l'index |
| Hat C (**23-27**) | `CycleNextPanel` / `CyclePreviousPanel` · `CycleNextPage` / `CyclePreviousPage` · **23** = `UI_Back` | navigation d'interface, cohérente avec la palette |
| Molette (**19-22**) | `RadarIncreaseRange` / `RadarDecreaseRange` ; **19/20** = `PlayerHUDModeToggle` (combat / analyse) | |
| Bascule (**28-30**) | **29** `FireChaffLauncher` · **30** `DeployHeatSink` · **28** `UseShieldCell` | **critique, position fixe** |
| Levier `SLDR` + **32** | libre — candidat : `RadarRangeAxis` analogique | |
| **1 2 3 13 31** | `NightVisionToggle`, `OrbitLinesToggle`, `TargetNextRouteSystem`, `WingNavLock`, **31** = modificateur | |

### Manche gauche — manœuvrer et survivre

| Commande | Action Elite | Pourquoi |
| --- | --- | --- |
| `X` `Y` | `LateralThrustRaw`, `AheadThrust` | convention HOSAS |
| `Z` twist | `VerticalThrustRaw` | voir décision 4 |
| Gâchette cran 1 (**4**) | `UseBoostJuice` | **critique** |
| Gâchette cran 2 (**5**) | libre | |
| Palette (**7**) | `ToggleFlightAssist`, **en maintien** (`ToggleOn = 0`) | l'action accepte le maintien : palette tenue = assistance coupée, relâchée = rétablie. Aucun doute sur l'état, jamais de bascule involontaire |
| Mini-stick `rX`/`rY` + **6** | libre en vaisseau ; sert de regard/visée dans les contextes FSS, DSS et à pied | |
| Hat A (**8-12**) | **triangle d'énergie** : **10** `IncreaseSystemsPower` · **9** `IncreaseEnginesPower` · **12** `IncreaseWeaponsPower` · **11** `ResetPowerDistribution` | reprend la disposition clavier par défaut (gauche/haut/droite/bas) — **critique** |
| Hat B (**14-18**) | `SetSpeed100` · `SetSpeedZero` · `SetSpeed50` · `SetSpeedMinus100` · **14** = `ToggleReverseThrottleInput` | vitesses fixes de secours quand la main quitte le throttle |
| Hat C (**23-27**) | `HyperSuperCombination` · `DecreaseSpeedButtonMax` (sortie de supercroisière) · `TargetNextRouteSystem` · `GalaxyMapOpen` · **23** = `SystemMapOpen` | tout le voyage sous un seul hat |
| Molette (**19-22**) | `ForwardKey` / `BackwardKey` (vitesse fine) ; **19/20** = `ToggleRotationLock`, `DisableRotationCorrectToggle` | |
| Bascule (**28-30**) | **29** `LandingGearToggle` · **30** `ToggleCargoScoop` (maintien) · **28** `ShipSpotLightToggle` | doublons de confort du PTO2, atteignables en manœuvre |
| Levier `SLDR` + **32** | libre — candidat : `ExplorationFSSRadioTuningX_Raw` | l'accord du FSS mérite un axe analogique |
| **1 2 3 13 31** | `EjectAllCargo` (sous modificateur), `MicrophoneMute`, `RecallDismissShip`, `ChargeECM`, **31** = modificateur | |

### Throttle CM3 — la vitesse d'abord

| Commande | Action Elite |
| --- | --- |
| Levier `rX` | **`ThrottleAxis`** — l'axe le plus important du jeu |
| Levier `rY` | `RadarRangeAxis` ou `ExplorationFSSRadioTuningAbsoluteX` (position absolue) |
| Slider `rZ`, molettes libres | zoom FSS, champ de vision DSS, réglages fins |
| Hats et bascules | panneaux (`FocusLeftPanel`, `FocusRightPanel`, `FocusCommsPanel`, `FocusRadarPanel`), `UI_*` |
| **T1-T7** (44-49) | états rares : lignes d'orbite, vision nocturne, couleurs, Galnet |
| **E1/E2** (50-55) | énergie fine et portée du scanner ; poussoirs = équilibrer |
| **Rotacteur MODE** | Blanc = vol et navigation · Bleu = combat · Vert = exploration (FSS/DSS) · Rouge = urgences et systèmes · Jaune = SRV et à pied |

Le rotacteur est ici un **confort, pas une nécessité** : le jeu bascule déjà
seul entre vaisseau, SRV, FSS, DSS et à pied. Il sert à dégrouper les
commandes rares d'un même métier, jamais à atteindre une commande vitale.

### PTO2 — les états tenus, et le piège des bascules

C'est le point le plus délicat du mapping, et il tient à une différence de
fond avec DCS : **Elite n'expose pas de commande ON et OFF séparées.** Le
train, les points durs, les phares sont des bascules.

Deux cas, à traiter différemment :

1. **Inverseur dont chaque position émet son propre numéro** (les inverseurs
   2 et 3 positions du PTO2 : `3-4`, `5-7`, `8-9`…). Assigner la *même*
   bascule aux deux positions : chaque basculement produit un appui, donc une
   inversion. Le manche reste cohérent tant que le jeu ne change pas l'état
   tout seul — or il le fait : **les points durs rentrent d'eux-mêmes à
   l'entrée en supercroisière**. Ne pas mettre les points durs sur un
   inverseur maintenu.
2. **Action acceptant le maintien** (`ToggleCargoScoop`, `ToggleFlightAssist`,
   `ToggleDriveAssist`, `MicrophoneMute`…). Régler `ToggleOn = 0` : la
   position physique de l'inverseur *est* l'état, sans dérive possible. Ce
   sont les seules commandes qui méritent vraiment un inverseur maintenu.

Proposition, en respectant le sens physique de chaque organe plutôt que la
sérigraphie F/A-18 :

| Repères | Organe | Action Elite |
| --- | --- | --- |
| **35-37** | levier de train, 3 positions | `LandingGearToggle` sur les deux positions extrêmes |
| **5-7** | volets, 3 positions | `ToggleCargoScoop` **en maintien** |
| **8-9** · **10-11** · **12-13** | inverseurs 2 positions | `ShipSpotLightToggle`, `NightVisionToggle`, `OrbitLinesToggle` |
| **32-34** | crosse d'appontage | `ToggleRotationLock`, `DisableRotationCorrectToggle` |
| **14-16** | perche de ravitaillement | `RecallDismissShip`, `EjectAllCargo` (position gardée) |
| **38-41** | frein de parking | `MicrophoneMute` **en maintien** (alternat radio) |
| **1** · **2** | boutons | `GalaxyMapOpen`, `SystemMapOpen` |
| **17-22** · **23-27** · **28-31** | sélecteurs multi-positions | groupes de feu, pages de panneau, préréglages d'énergie |

## 5. Ce qui reste à trancher

**Décision 1 — distinguer les deux Alpha Prime. Bloquant.**
Elite Dangerous ne désigne pas un périphérique par un GUID DirectInput mais par
une chaîne **VID+PID hexadécimale** : `Device="3344012F"` = fabricant `3344`
(Virpil), produit `012F`. Deux exemplaires du même modèle sortis d'usine
portent **exactement la même chaîne** : le jeu ne peut alors pas les
distinguer, et tout bind posé sur l'un vaut pour l'autre.

Le profil de référence dépouillé contient précisément deux périphériques
Virpil distincts — `3344012F` et `3344812F` — même fabricant, PID différents.
La manœuvre est donc connue et fonctionne : **changer le PID de l'un des deux
manches dans le VPC Configuration Tool** (onglet Profile), puis rebrancher.
Rien ne peut être écrit tant que ce n'est pas fait.

Le jeu accepte aussi un nom convivial (`VPCThrottle` dans le même profil),
déclaré dans `ControlSchemes\DeviceMappings.xml` côté installation. Ce fichier
est écrasé à chaque mise à jour du jeu : le PID reste la solution durable.

**Décision 2 — le relevé matériel.** Comme pour Star Citizen : brancher les
quatre périphériques, assigner une commande quelconque sur chacun depuis
l'écran Contrôles, quitter proprement, puis lancer
`tools\parse-ed-binds.ps1`. Objectif : figer les chaînes VID+PID réelles et
vérifier jusqu'à quel numéro de bouton le jeu lit chaque périphérique.

**Décision 3 — le pédalier.** Le lacet est faible et lent sur la plupart des
vaisseaux d'Elite : le mettre aux pieds libère le twist du manche droit, mais
ajoute un cinquième périphérique à identifier. Recommandation : rester à trois
axes par manche pour commencer, décider après le premier vol.

**Décision 4 — le twist du manche gauche.** Même arbitrage que pour Star
Citizen, avec un argument supplémentaire ici : la poussée verticale sert en
permanence à l'amarrage et au combat rapproché. Recommandation : twist gauche
= `VerticalThrustRaw`, et laisser les couches `_Landing` vides.

**Décision 5 — la plage de la manette des gaz.** `ThrottleRange` accepte
« avant seul », « avant et arrière » et « plage complète ». Avec un levier CM3
sans cran central, la plage complète place le zéro au milieu de la course et
divise par deux la finesse dans la zone bleue. Recommandation : **avant seul**,
plus `ToggleReverseThrottleInput` sur un bouton pour la marche arrière.

**Décision 6 — le focus interface.** `UIFocusMode` en maintenu
(`Bindings_FocusModeHold`) rend la palette droite cohérente avec le reste du
mapping, mais interdit de garder un panneau ouvert en pilotant. Recommandation :
maintenu, quitte à revenir dessus.

## 6. Sources

- Fichier `.binds` de référence, schéma **4.2**, profil HOTAS Virpil
  communautaire — 514 actions, deux manches Virpil à PID distincts et un
  throttle nommé : [dance-cmdr/elite-dangerous-keybindings-for-virpil-setup](https://github.com/dance-cmdr/elite-dangerous-keybindings-for-virpil-setup/blob/main/Custom.4.2.binds).
  C'est de ce fichier que sort `data/ed-actions.json`.
- Second fichier `.binds` (schéma 4.0) pour recoupement :
  [netkingcol/ED-binding-transform](https://github.com/netkingcol/ED-binding-transform/blob/main/Custom.4.0.binds).
- Identification des périphériques, VID/PID et `DeviceMappings.xml` :
  [EDCD/EliteCustomButtonNames](https://github.com/EDCD/EliteCustomButtonNames).
- Deux manettes identiques vues comme une seule, et changement de PID dans
  l'outil Virpil : [Elite recognize two joysticks as one](https://forums.frontier.co.uk/threads/elite-recognize-two-joysticks-as-one.636794/),
  [Fixing disappearing custom binds](https://forums.frontier.co.uk/threads/fixing-disappearing-custom-binds-due-to-failed-to-find-guid-for-device-bind-loading-error.631419/).
- Couches d'atterrissage et commandes de vol alternatives :
  [How do alternate flight controls work?](https://steamcommunity.com/app/359320/discussions/0/1326718197204296253/).
