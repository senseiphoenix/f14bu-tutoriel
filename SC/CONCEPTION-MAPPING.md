# Star Citizen — conception du mapping HOSAS

Document de conception, à valider avant toute écriture de code ou de binds.
Rig visé : **HOSAS (deux Alpha Prime) + throttle MongoosT-50CM3 + WinWing PTO2**.
Le pédalier sort du périmètre.

---

## 1. Le principe qui change tout : le contexte fait la couche

Star Citizen range ses commandes par *actionmap*, et les **modes opérateur sont
exclusifs** : on est en mode vol, ou canons, ou missiles, ou scan, ou minage, ou
récupération, ou quantique — jamais deux à la fois. Un même bouton physique peut
donc porter une action différente dans chaque mode **sans aucun modificateur**.

Ce n'est pas une théorie : c'est déjà le cas dans ton profil actuel. La gâchette
`js1_button4` y porte **sept** actions distinctes :

| Actionmap | Action |
| --- | --- |
| `spaceship_weapons` | tir groupe canons |
| `spaceship_missiles` | accroche et tir missile |
| `spaceship_mining` | tir du laser de minage |
| `spaceship_salvage` | tir de la tête de récupération |
| `spaceship_scanning` | déclenchement du scan |
| `spaceship_quantum` | engagement du saut |
| `default` | réapparition |

**Conséquence de conception :** on ne construit pas un mapping, on en construit
sept qui partagent les mêmes doigts. Le geste « tirer » reste au même endroit
quel que soit le métier. Le modificateur `rctrl` ne sert plus qu'aux réglages
rares — pas à doubler le mapping.

Hiérarchie des multiplicateurs, du plus naturel au plus coûteux :

1. **le mode opérateur** — gratuit, la main ne bouge pas, aucun réflexe à apprendre ;
2. **l'appui court / long / double** — géré nativement par Star Citizen (`activationMode`) ;
3. **le modificateur** — réservé aux réglages qu'on fait au sol ou en croisière ;
4. **les pages du rotacteur MODE du throttle** — pour les commandes de métier.

## 2. Répartition par périphérique : qui tient quoi

Contrainte physique décisive : en HOSAS, **les deux mains sont prises**. Le
throttle et le PTO2 ne sont pas des extensions des manches, ce sont des panneaux
qu'on va chercher en lâchant un manche.

| Périphérique | Rôle | Contenu |
| --- | --- | --- |
| Manche droit | viser et tirer | rotation, ciblage, armes, senseurs, vues |
| Manche gauche | se déplacer et survivre | translation, vitesse, boucliers, contre-mesures, modes |
| Throttle CM3 | l'état du vaisseau | limiteur, énergie, métiers, MFD — réglé entre deux passes |
| PTO2 | la mise en œuvre | train, feux, portes, ATC, mise en route — au sol ou en croisière |

**Rien de vital ne va sur le throttle ni sur le PTO2.** Frein spatial,
découplage, boost, contre-mesures, éjection : uniquement sur les manches, à
position fixe, hors couche et hors mode.

## 3. Inventaire physique relevé

Sources : gabarits officiels Virpil, gabarits Joystick Diagrams (`Button_1…N`
avec coordonnées exactes), et ton mapping DCS du F-14 — qui révèle quel numéro
tombe sous quel doigt, puisque tu le voles déjà.

### Alpha Prime — 32 boutons, 6 axes (identique à gauche et à droite)

| Grappe | Numéros | Nature |
| --- | --- | --- |
| Mini-stick pouce | `rX` `rY` + **6** (press) | stick analogique |
| Hat A | **9** haut · **10** gauche · **11** bas · **12** droite · **8** press | 4 directions + press |
| Hat B | **15** haut · **16** gauche · **17** bas · **18** droite · **14** press | 4 directions + press |
| Hat C | **24** haut · **25** gauche · **26** bas · **27** droite · **23** press | 4 directions + press |
| Molette pouce | **21** haut · **22** bas · **19** press · **20** press profond | molette crantée |
| Bascule 3 positions | **29** haut · **30** bas · **28** press | switch |
| Gâchette 2 crans | **4** cran 1 · **5** cran 2 | index |
| Levier de frein | **32** bouton + `SLDR` axe | annulaire / paume |
| Boutons simples | **1** · **2** · **3** · **7** · **13** · **31** | dont **7** = palette (auriculaire) |
| Axes cardan | `X` `Y` + `Z` (twist) | |

Repères de lecture, tirés de ton profil DCS : **4/5** portent l'interlock et le
feu canon, donc les deux crans de gâchette ; **15-18** portent les trims, donc
le hat sous l'index ; **19-22** portent zoom et bascules, donc la molette ;
**32** et `SLDR` portent le frein de parking et les freins de roues, donc le
levier ; **7** porte le débrayage du pilote automatique, donc la palette.

### MongoosT-50CM3 — 55 boutons de base, 6 axes, rotacteur MODE

- Leviers : `rX` et `rY` (les deux manettes), `rZ` (slider de base), plus trois
  molettes analogiques libres et un mini-stick.
- Hats : deux hats 4 directions + press (**8-12**, **22-26**, **27-31**),
  bascules **2/3** et **14/15**, sélecteur **5/6/7**.
- Interrupteurs à bascule **T1-T7** (**44-49**) et encodeurs **E1/E2** avec
  poussoir (**50-55**).
- **Rotacteur MODE, 5 crans** : les six boutons **B1-B6** émettent un numéro
  différent par cran — relevé et confirmé sur ton propre CM3 pendant le travail
  DCS : Blanc **38-43**, Bleu **56-61**, Vert **62-67**, Rouge **68-73**,
  Jaune **74-79**. Soit **30 commandes distinctes sur six boutons**.

### WinWing PTO2 — 41 positions

Structure relevée dans ton mapping DCS : deux boutons simples (**1**, **2**),
des inverseurs 2 positions (**3-4**, **8-9**, **10-11**, **12-13**), des
inverseurs 3 positions (**5-7**, **14-16**, **32-34**, **35-37**), et des
sélecteurs à 4, 5 ou 6 positions (**28-31**, **23-27**, **17-22**, **38-41**).

C'est un panneau d'**états**, pas d'actions fugaces : chaque interrupteur a une
position physique qui doit correspondre à un état du vaisseau.

## 4. Allocation proposée

### Manche droit — viser et tirer

| Commande | Fonction | Pourquoi |
| --- | --- | --- |
| `X` `Y` | lacet, tangage | convention HOSAS |
| `Z` twist | roulis | déjà en place dans ton profil |
| Gâchette cran 1 (**4**) | **tir du mode courant** — canons, missile, laser de minage, faisceau de récupération, scan, saut quantique | un seul geste pour « agir », quel que soit le métier |
| Gâchette cran 2 (**5**) | tir secondaire : deuxième groupe d'armes, salve, tir soutenu | |
| Palette (**7**) | **découplage**, maintenu | critique, sous l'auriculaire, atteignable en manœuvre |
| Mini-stick `rX`/`rY` + **6** | regard libre, **6** recentre | analogique, sous le pouce |
| Hat A (**8-12**) | ciblage : cible sous réticule, hostile suivant, cible suivante, déverrouiller, épingler | le geste le plus fréquent en combat |
| Hat B (**14-18**) | visée : gimbals, pip avance/retard, convergence, ligne de précision | réglages de tir, sous l'index |
| Hat C (**23-27**) | vues : caméra suivante, regard arrière, zoom ±, recentrage | |
| Molette (**19-22**) | mode opérateur suivant / précédent ; presses = focalisation du scan | |
| Bascule (**28-30**) | **leurres**, **brouillage**, taille de salve | critique, position fixe |
| Levier `SLDR` + **32** | convergence des armes, analogique | un réglage continu mérite un axe |
| **1 2 3 13 31** | héler la cible, ping radar, sous-cible, essuie-visière, **31** = modificateur | |

### Manche gauche — se déplacer et survivre

| Commande | Fonction | Pourquoi |
| --- | --- | --- |
| `X` `Y` | translation latérale, avant/arrière | convention HOSAS |
| `Z` twist | translation verticale | voir décision 2 |
| Gâchette cran 1 (**4**) | **boost**, maintenu | |
| Gâchette cran 2 (**5**) | postcombustion soutenue | |
| Palette (**7**) | **frein spatial**, maintenu | critique, jamais déplacé |
| Mini-stick `rX`/`rY` + **6** | rayon tracteur : distance et orientation de la charge | analogique, inutilisé en combat |
| Hat A (**8-12**) | **boucliers** : avant, arrière, gauche, droite, équilibrer | |
| Hat B (**14-18**) | modes : **NAV/SCM**, mode vol, mode opérateur ±, quantique | la main gauche décide « dans quoi on est » |
| Hat C (**23-27**) | **triangle d'énergie** : moteurs, boucliers, armes, retour à l'équilibre | |
| Molette (**19-22**) | plage de vitesse ± ; presses = limiteur actif / coupé | |
| Bascule (**28-30**) | ESP, sécurité G, compensation de gravité | réglages de pilotage |
| Levier `SLDR` + **32** | limiteur de vitesse en relatif, secours du throttle | |
| **1 2 3 13 31** | train, VTOL, phares, portes, **31** = modificateur | doublons de confort du PTO2 |

### Throttle CM3 — l'état du vaisseau

| Commande | Fonction |
| --- | --- |
| Levier `rX` | **limiteur de vitesse, absolu** — la position du levier fait foi |
| Levier `rY` | **puissance analogique du métier** : laser de minage en mode minage, écartement des faisceaux en récupération, focalisation en scan |
| Slider `rZ`, molettes libres | zoom, distance du tracteur, réglages fins |
| Hats et bascules | navigation dans les MFD, sélection de cible, communications |
| **T1-T7** (44-49) | états : feux de position, phares, éclairage cabine, verrouillage des portes et des trappes |
| **E1/E2** (50-55) | énergie fine : moteurs ±, boucliers ± ; poussoirs = min / max |
| **Rotacteur MODE** | une page par métier : Blanc = vol et navigation · Bleu = combat · Vert = minage · Rouge = urgences et systèmes · Jaune = récupération et fret |

Les urgences figurent sur la page Rouge **et** en doublon sur les manches : une
panne ne prévient pas, elle ne doit jamais imposer de tourner un rotacteur.

### PTO2 — la mise en œuvre

La sérigraphie est celle d'un F/A-18. On respecte le **sens physique** de chaque
inverseur plutôt que son étiquette gravée :

| Repères | Organe physique | Fonction Star Citizen |
| --- | --- | --- |
| **35-37** | levier de train, 3 positions | **train d'atterrissage**, sortie / rentrée |
| **5-7** | volets, 3 positions | **VTOL**, déployé / transit / rentré |
| **38-41** | frein de parking | **verrouillage du vaisseau**, portes et trappes |
| **32-34** | crosse d'appontage | **amarrage** : mode docking, invoquer l'amarrage |
| **14-16** | perche de ravitaillement | **ravitaillement** et transfert de cargo |
| **8-9 · 10-11 · 12-13** | inverseurs 2 positions | feux de position, phares, éclairage cabine |
| **1 · 2** | boutons | **mise en route complète**, appel du contrôle |
| **17-22 · 23-27 · 28-31** | sélecteurs multi-positions | groupes d'armes, programmes de contre-mesures, préréglages d'énergie |

## 5. Ce qui reste à trancher

**Décision 1 — JoyToKey.** Le profil communautaire dont dérive le tien exige
JoyToKey pour les fonctions que Star Citizen refuse de binder sur un joystick
(molette souris pour le tracteur, quelques touches d'interface). Deux voies :
tout en binds natifs, quitte à laisser trois ou quatre fonctions au clavier ; ou
garder JoyToKey et couvrir toutes les fonctions, au prix d'une dépendance qui
doit tourner à chaque session.

**Décision 2 — le twist du manche gauche, et le coude.** Le montage en guidon de
moto rend le twist proche d'une poignée d'accélérateur. Deux options : garder les
six axes canoniques — twist = translation verticale, limiteur sur le levier du
throttle — ce que je recommande, car les deux mains restent sur les manches en
combat ; ou dédier le twist gauche au limiteur de vitesse et déporter la
translation verticale sur le mini-stick, plus intuitif mais moins précis pour
esquiver.

**Décision 3 — le relevé matériel.** Rien ne peut être écrit dans le jeu tant que
l'ordre `js1…js4` n'est pas figé : brancher les quatre périphériques, binder une
commande au hasard sur le PTO2, exporter depuis le jeu, relancer
`tools/parse-sc-layout.ps1`. Sans ça, `js4_button35` peut désigner le PTO2 comme
n'importe quel autre périphérique.
