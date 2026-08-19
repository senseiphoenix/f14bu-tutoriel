# Notes de sources — F-4E Phantom II

Matière brute collectée pour la rédaction des leçons, **ventilée par leçon
cible** et par phase du squelette. Ce fichier n'est pas publié : c'est le
carnet de rédaction, pas du texte joueur.

## Hiérarchie des sources — à respecter

1. **Guide de Chuck** — `F4E/docs/DCS F-4E Phantom II Guide.pdf`, **936 pages**,
   version téléchargée (187 Mo, plus récente que les 162 Mo livrés dans
   `Mods\aircraft\F-4E\Doc\Chucks Guide.pdf`). **C'est LA référence de
   rédaction pour ce module**, décision de l'utilisateur du 19/08/2026 :
   illustré, pas-à-pas, panneau par panneau, et structuré exactement comme
   il faut. Sa table des matières sert de plan (voir plus bas).
   *Nuance à garder en tête* : son propre avertissement dit qu'il s'appuie
   sur de la documentation publique (wiki Heatblur) et des tutoriels
   communautaires — ce n'est donc pas une source primaire, juste la
   meilleure synthèse disponible.
2. **Manuel officiel Heatblur** — `Mods\aircraft\F-4E\Doc\F-4E Manual.pdf`.
   Arbitre en cas de contradiction avec le guide de Chuck.
3. **Taxonomie du module** — `Mods\aircraft\F-4E\Input\bind_categories.lua`.
   Source technique sûre pour nommer les systèmes et organiser le mapping.
4. **Synthèses et vidéos communautaires** — utiles pour le plan et les
   priorités pédagogiques, mais **jamais pour un chiffre ou une procédure**
   sans recoupement avec 1 ou 2.

## Images — décision et réglages

**Tranché le 19/08/2026** : les planches du guide de Chuck sont extraites et
publiées, **avec crédit explicite à leur auteur** sur chaque page qui les
emploie (titre du guide, auteur, pages exactes, mention « tous droits à son
auteur »). Le dépôt et le site GitHub Pages sont publics — vérifié, ils
répondent tous deux sans authentification — et l'utilisateur assume cette
diffusion à titre pédagogique.

Les planches vont dans **`F4E/img/chuck/`**, nommées par sujet et non par
numéro de page (`demarrage-allumage.webp`, pas `p163.webp`) : le guide sera
mis à jour un jour, les numéros bougeront, les sujets non.

**Extraction** : `tools/pdf-extract.html`, servi par `tools/serve.ps1`.
Le navigateur rend la page avec PDF.js et la POSTe au serveur, qui l'écrit
sur disque. Aucun outil PDF n'est installé sur la machine et le plugin PDF
de Chrome ne rend rien en headless — c'est la seule voie qui marche ici.

```
await extract({
  pdf: '/F4E/docs/DCS%20F-4E%20Phantom%20II%20Guide.pdf',
  outDir: 'F4E/img/chuck',
  pages: [{n:163, name:'demarrage-allumage'}]
})
```

**Réglages retenus : WebP, `scale: 1.6`, `quality: 0.80`** → 1536×864,
130 à 185 Ko par planche. Mesuré sur la page 163 (dense en petit texte) :

| Format | Dimensions | Poids | Verdict |
| --- | --- | --- | --- |
| JPEG s2 q.82 | 1920×1080 | 393 Ko | inutilement lourd |
| WebP s2 q.80 | 1920×1080 | 241 Ko | de la marge en trop |
| **WebP s1.6 q.80** | **1536×864** | **171 Ko** | **retenu** |
| WebP s1.35 q.80 | 1296×729 | 133 Ko | lisible, mais juste au zoom |

Ces pages sont des diapos (aplats blancs + captures) : le **WebP** y gagne
~40 % sur le JPEG à qualité égale. 1536 px pour ~820 px d'affichage réel
laisse la réserve nécessaire aux écrans haute densité et à l'ouverture en
grand. Ce sont les valeurs par défaut du harnais, inutile de les repasser.

---

# Plan de rédaction — la table des matières de Chuck

C'est le squelette de référence. Les 20 parties, avec la page de départ
quand elle a été relevée :

| Partie | Sujet | Page | Leçon(s) du site |
| --- | --- | --- | --- |
| 1 | Introduction | 4 | — |
| 2 | Controls Setup | ~20 | 1 · Préparer le module |
| 3 | Cockpit & Equipment | — | 2, 3 · Tours de cockpit |
| 4 | Start-Up Procedure | **145** | 5 · Démarrage, 6 · INS |
| 5 | Takeoff | — | 7 · Roulage et décollage |
| 6 | Landing | — | 13 · Retour et atterrissage |
| 7 | Engine & Fuel Management | — | 8 · Vol de base et AFCS |
| 8 | Flight & Aerodynamics | — | 8 · Vol de base et AFCS |
| 9 | Emergency Procedures | — | 14 · Urgences et Bold Face |
| 10 | Radar & Sensors | — | 15 · Radar AN/APQ-120 |
| 11 | Offence: Weapons & Armament | **421** | 16 à 23 (voir détail) |
| 12 | Defence: RWR and Countermeasures | — | 24 · RWR et contre-mesures |
| 13 | IFF | — | 10 · IFF et Combat-Tree |
| 14 | Radio Communications | — | 11 · Radio et communications |
| 15 | Autopilot | — | 8 · Vol de base et AFCS |
| 16 | Navigation & ILS Landing | — | 9 · Navigation |
| 17 | Air-to-Air Refueling | — | 12 · Ravitaillement |
| 18 | Multicrew | — | **manque** — équipage humain, à créer |
| 19 | JESTER AI | — | 4 · JESTER et le Crew Chief |
| 20 | Reference Material & Acronyms | — | 26 · Checklists personnalisées |

**Absence notable : aucune partie sur les opérations d'appontage.** Ça
confirme le `[DOUTEUX]` plus bas — le F-4E de ce module ne fait pas de
porte-avions.

## Détail de la partie 4 — Démarrage (p. 145)

Découpage de Chuck, à reprendre tel quel : **A** Before Start-Up,
**B** Engine Start, **C** INS Alignment, **D** Before Taxi (Pilote),
**E** Before Taxi (WSO). Noter les **deux checklists avant roulage
distinctes** selon le siège — c'est exactement la logique biplace que le
site doit refléter. Des checklists abrégées existent en partie 20.

## Détail de la partie 11 — Armement (p. 421)

Structure réelle, bien plus riche que ce que le squelette couvre :

- **Généralités** : interface d'armement, QFE et précision d'altitude en
  air-sol, **méthodes de largage**, outil de calcul de bombardement.
- **Bombes non guidées** : MK-82 en mode **Dive Toss**, MK-82 Snake Eye
  (freinée) en **Direct**, M117 en **Loft**.
- **Bombes à sous-munitions** : MK-20 Rockeye en **Laydown**, CBU-87 en
  **Dive Laydown**, CBU-1A/A en **Direct**.
- **Bombes guidées laser** : GBU-12 Paveway II, avec deux voies —
  désignation par **JTAC** (mode Direct) et désignation au **pod**
  (mode TGT FIND).
- **Anti-piste** : BLU-107 Durandal en Direct.
- **Roquettes** : Hydra 70 FFAR.
- **Canon air-sol** : M61A1 interne et **pods SUU-23**.
- **Missiles air-sol** : AGM-12 Bullpup, AGM-65 Maverick.
- **Guidage TV** : GBU-8 HOBOS, AGM-62 Walleye.
- **Antiradar** : **AGM-45 Shrike** seulement, en mode AGM-45 (WRCS) ou
  Direct.
- **Air-air** : canon (avec et sans radar), AIM-9 (avec et sans radar),
  AIM-7 — et pour le Sparrow, **quatre variantes de procédure** :
  Multicrew WVR, Multicrew ACM, JESTER WVR, JESTER ACM.
- **Jettison** : sélectif et d'urgence.

**Ce que ça a déjà changé sur le site :**
- Les modes de largage ont des **noms précis** (Dive Toss, Direct, Loft,
  Laydown, Dive Laydown) — un encadré de la leçon 18 le dit désormais, et
  interdit explicitement le mot « CCIP ».
- La leçon 23 (SEAD) nomme le **Shrike** et signale que le Standard ARM
  n'est pas confirmé.
- Une leçon **21 · Armes à guidage TV** a été créée (Bullpup, HOBOS,
  Walleye), ainsi que **10 · IFF** et **11 · Radio**.
- La leçon 16 (AIM-7) porte un encadré rappelant ses **quatre variantes** :
  équipage humain ou JESTER, croisé avec WVR ou ACM.

**Ce qui reste à faire de cette partie :**
- Une leçon ou une phase sur les **bombes à sous-munitions** (MK-20,
  CBU-87, CBU-1A/A) — non couverte aujourd'hui.
- Les **pods canon SUU-23**, à intégrer à la leçon 19.
- Le **jettison** sélectif et d'urgence, à répartir entre les leçons
  d'armement et la 14 (urgences).
- La désignation par **JTAC** pour la GBU-12, à ajouter à la leçon 22.
- La partie **QFE et précision d'altitude**, qui conditionne toute la
  précision air-sol et n'apparaît nulle part pour l'instant.

## Comment s'en servir

- Chaque bloc dit **d'où il vient** et **où il va** (fichier + phase).
- Les notes marquées **`[à recouper]`** attendent confirmation par le manuel
  ou le guide de Chuck.
- Les notes marquées **`[DOUTEUX]`** sont des affirmations que je crois
  **fausses ou trompeuses** — à ne pas publier sans vérification explicite.
- Aucun numéro de bouton HOTAS n'est noté ici : les binds sont résolus à
  l'affichage depuis `data/f4e-bindings.json`, qui n'existe pas encore.

---

## Rappel structurant : ce module a deux postes ET deux jeux de binds

Vérifié dans la cascade du module (`Mods\aircraft\F-4E\Input\`) : il existe
**deux profils d'entrées séparés**, `F-4E-Pilot` et `F-4E-WSO`, chacun avec
son `joystick\` et son `keyboard\`. Ce sont donc **ces deux noms** qui
apparaîtront dans `Saved Games\...\Config\Input\` — relevé, pas deviné.

Le module livre aussi des profils tout faits pour du matériel du commerce
(dont un `VPC WarBRD + MT50`, proche mais pas identique au rig utilisé ici).
**Conséquence** : des commandes peuvent être déjà assignées sans qu'aucun
fichier utilisateur n'existe. À vérifier dans l'écran Contrôles avant de
conclure que rien n'est bindé.

---

# Source S1 — Progression d'apprentissage (synthèse fournie)

- **Nature** : plan d'apprentissage structuré, transmis le 19/08/2026.
- **Statut** : synthèse rédigée, non attribuée à une source primaire. Utile
  pour **valider l'ordre des leçons**, pas pour les détails techniques.
- **Verdict** : le plan recoupe très bien le squelette construit. Il a
  révélé **trois trous réels**, depuis comblés : **AGM-65 Maverick**,
  **SEAD / Wild Weasel** (missiles antiradar), et **roquettes / mitraillage
  air-sol**. Une quatrième leçon a été ajoutée dans la foulée : **AVTR et
  débriefing**.

## Points repris tels quels (cohérents avec le module)

- Ordre général : prise en main → systèmes → air-air → air-sol → avancé.
- **LCOS** (viseur optique à calcul d'avance) pour le canon en combat
  tournoyant — cohérent avec un F-4E.
- **M61A1** interne — correct pour cette version, c'est justement ce qui
  distingue le E des Phantom antérieurs.
- **Jester 2.0** pour le WSO — confirmé, le module embarque un dossier
  `Jester\` complet et des catégories de binds dédiées.
- Radar **AN/APQ-120**, INS, TACAN/ADF, RWR/ECM — tous confirmés par la
  taxonomie du module.

## `[DOUTEUX]` — Opérations d'appontage

La synthèse mentionne *« Carrier Operations (Optionnel / F-4E adapté) —
procédures de qualification d'appontage/décollage »*.

**Je crois cette entrée fausse pour ce module et je ne l'ai pas transformée
en leçon.** Le F-4E est la version **terrestre de l'US Air Force** : ce sont
les F-4B/J/N/S de l'US Navy qui étaient embarqués. La crosse d'arrêt du F-4E
sert aux **barrières de piste**, pas aux brins d'un porte-avions. La mention
« F-4E adapté » dans la synthèse ressemble à une hésitation de sa propre
source.

**À trancher avant toute rédaction** : vérifier dans le manuel Heatblur si
le module propose quoi que ce soit d'embarqué. Si non, ne rien écrire —
et ne surtout pas recopier ici la matière d'appontage du F-14B(U) ou du
F4U-1D, qui sont de vrais avions embarqués.

## `[TRANCHÉ — la synthèse avait tort]` — « CCIP » pour les bombes lisses

La synthèse écrivait *« Bombes lisses (CCIP / Dive Bombing) »*. **Vérifié
dans le guide de Chuck (p. 422) : le mot CCIP n'apparaît pas.** Les modes
réels du F-4E portent des noms propres — **Dive Toss**, **Direct**,
**Loft**, **Laydown**, **Dive Laydown** — et chacun s'applique à des
munitions précises. Employer « CCIP » induirait en erreur quelqu'un venant
d'un jet moderne. **Ne pas l'utiliser dans la leçon 16.**

`[à recouper]` — la synthèse citait *« DSCG / AN/ASQ-91 »* comme
calculateurs. La taxonomie du module distingue bien **DSCG** et **WRCS** :
le WRCS est le calculateur de largage (c'est lui que Chuck cite pour les
modes du Shrike), le DSCG semble être un groupe d'affichage côté WSO.
Vérifier qui fait quoi avant de l'écrire.

## `[DOUTEUX]` — AGM-78 Standard ARM

La synthèse S1 annonce du *Wild Weasel / SEAD (AGM-45 Shrike & AGM-78
Standard ARM)*. **Le guide de Chuck ne liste que l'AGM-45 Shrike** dans sa
section antiradar (p. 422). Soit le Standard ARM n'existe pas sur ce module,
soit il a été ajouté après la rédaction du guide. **Vérifier dans l'éditeur
de mission avant d'en parler dans la leçon 20** — pour l'instant, elle est
écrite sans nommer de missile précis, ce qui reste correct dans les deux cas.

## Ressources nommées par la synthèse

Chaînes citées comme références : **Heatblur** (officiel), **Matt Wagner**,
**Bogey Dope**, **Redkite**, **Tricker**. À retenir comme pistes de
recherche, pas comme sources déjà validées.

---

# Source S2 — Procédure de démarrage Cold & Dark (synthèse fournie)

- **Nature** : procédure détaillée en 23 points, transmise le 19/08/2026.
- **Statut** : synthèse non attribuée. **Le guide de Chuck couvre la même
  procédure avec des captures** — c'est lui qui doit servir de base, cette
  note sert de squelette d'ordre et de liste de points à ne pas oublier.
- **Destination** : `demarrage-a-froid.html` (leçon 5) et
  `alignement-ins.html` (leçon 6).

## → `demarrage-a-froid.html`, phase 1 — Avant de mettre sous tension

- **Manettes des gaz** vérifiées sur `OFF / CUTOFF`, position arrière
  verrouillée.
- **Frein de parc** tiré et verrouillé.

## → phase 2 — L'électricité et le groupe de parc

1. **Batterie** sur `ON` (console droite).
2. **Générateurs gauche et droit** sur `NORM`.
3. Demander au **Crew Chief** l'alimentation électrique puis l'air de
   démarrage (menu de communication). C'est le point qui bloque le plus de
   débutants : sans air, le démarreur ne tourne pas.
4. Vérifier l'**intercom** avec le WSO / JESTER.
5. **Pompes à carburant** toutes sur `ON`.
6. **Feux de position** selon la visibilité.

## → phase 3 — Lancer les deux réacteurs

Séquence donnée, **moteur droit (n°2) en premier** :

1. **Commutateur de démarrage** sur `RIGHT`.
2. Attendre **10 à 12 % de régime**.
3. Passer la manette **droite** de `OFF` à `IDLE` — c'est l'injection du
   carburant. C'est là que sert le **cran d'injection** (*idle detent*) à
   mapper sur le HOTAS.
4. Surveiller la montée de la **température des gaz d'échappement**.
5. Attendre la stabilisation du ralenti vers **60 à 65 % de régime**.
6. Le démarreur se coupe seul.
7. Recommencer à l'identique pour le **moteur gauche (n°1)**.

`[à recouper]` — les seuils **10-12 %** et **60-65 %** viennent d'une
synthèse non sourcée : à confirmer dans le guide de Chuck ou le manuel avant
publication. `[à recouper]` également : l'ordre **droit puis gauche** est-il
prescrit, ou simplement l'usage ? Certains avions imposent un ordre pour des
raisons d'alimentation hydraulique ou électrique.

## → phase 4 — Après démarrage

- Faire retirer le groupe électrique et l'air par le **Crew Chief**.
- Vérifier les **pressions hydrauliques** (circuits utilitaire et commandes
  de vol) et l'extinction des voyants générateurs.
- **INS** sur `ALIGN` — à coordonner avec JESTER (voir leçon 6).
- **Volets** en position décollage.
- **Trims** réglés selon la charge.
- **Viseur** allumé.

---

# Source S3 — Commandes HOTAS essentielles (synthèse fournie)

- **Nature** : liste des commandes à mapper en priorité, transmise le
  19/08/2026, appuyée sur la catégorie `*Essentials*` du module.
- **Destination** : `preparer-module-controles.html` (leçon 1), et
  `mapping-hotas.html` quand les binds existeront.
- **Crédibilité** : bonne — la catégorie `essentials` existe bel et bien dans
  `bind_categories.lua`, ce qui confirme que la liste s'appuie sur le module
  et pas sur une intuition.

## Axes

- Tangage, roulis, lacet.
- **Deux axes de gaz distincts**, un par réacteur — particularité du biréacteur.
- **Freins différentiels** gauche et droite au palonnier.

## Démarrage et moteurs

- **Crans d'injection ralenti** (*idle detents*) gauche et droit —
  indispensables pour le passage `OFF` → `IDLE` à 10-12 % de régime.
- **Commutateur de démarrage** gauche / droit.
- **Interrupteurs de générateurs** gauche et droit.

## Roulage

- **Direction de roulette de nez** (*NWS*) — décrit comme « le bouton le plus
  important du manche », partagé avec la fonction d'acquisition automatique.
  `[à recouper]` : vérifier si c'est bien un bouton unique à double fonction
  sur ce module.
- **Frein de parc**.
- **Volets** — commande à trois positions.
- **Aérofreins** — commande à trois positions sur la manette.

## Équipage et radio

- **Jester Context Action** et **Jester UI Action** : deux boutons distincts,
  l'un pour l'action contextuelle rapide, l'autre pour ouvrir le menu. À
  mapper impérativement, sinon toute interaction avec JESTER oblige à lâcher
  le HOTAS.
- **Alternat micro** UHF / intercom.

---

# Source S4 — Vidéos proposées (à vérifier avant intégration)

Transmises le 19/08/2026. **Aucune n'a été visionnée ni vérifiée** — ce sont
des pistes. Avant d'en citer une dans `ressources.html`, contrôler qu'elle
porte bien sur le **F-4E de Heatblur dans DCS** et noter sa date.

| Sujet | Lien annoncé | Destination |
| --- | --- | --- |
| Configuration HOTAS complète | `youtube.com/watch?v=o7tTqG41FWI` | leçon 1 |
| Démarrage Cold & Dark pas-à-pas | `youtube.com/watch?v=VpKn8cgFBdQ` | leçon 5 |
| AIM-7 Sparrow, interception BVR/WVR | `youtube.com/watch?v=vE0UTSUs4yE` | leçon 14 |
| Pave Spike et bombes laser, en français | `youtube.com/watch?v=2qOiACdGy6w` | leçon 17 |
| Enregistreur AVTR | lien fourni **invalide** | leçon 20 |

**Note sur la dernière ligne** : le lien fourni pour l'AVTR n'est pas une
URL YouTube mais une recherche Google malformée. L'identifiant `rXz41sNfD9U`
qu'il contient peut être le bon, mais ça reste à vérifier — ne pas le publier
tel quel.

La vidéo de configuration HOTAS est annoncée comme portant sur un
**Thrustmaster Warthog**, pas sur le rig Virpil utilisé ici. Elle reste utile
pour comprendre *quelles* commandes mapper et pourquoi, pas pour copier des
numéros de bouton.

---

# Ce qui manque encore

- **Tout le contenu détaillé** : 22 leçons Pas à pas et 5 de
  perfectionnement sont au stade du plan. Seul le démarrage dispose d'une
  matière exploitable (S2), encore à recouper.
- **Le guide de Chuck n'a pas encore été dépouillé** — c'est la prochaine
  étape la plus rentable, il couvre à lui seul la majorité des leçons.
- **Les deux points `[DOUTEUX]`** (appontage, CCIP) à trancher.
- **La liste réelle des missions** livrées avec le module.
- **Le relevé des binds**, qui débloquerait tous les badges du site.
