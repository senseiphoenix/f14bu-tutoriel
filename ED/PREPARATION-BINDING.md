# Elite Dangerous — préparation de la session « binding complet »

Cette note est le point d'entrée de la session consacrée à l'écriture du
mapping complet sur le rig réel. Elle rassemble tout ce qu'il faut pour
commencer à travailler immédiatement : ce qui est déjà fait, ce qui demande
une manipulation de ta part avant de commencer, les décisions qui attendent
une réponse, et la chaîne d'outils prête à tourner.

La conception reste dans [CONCEPTION-MAPPING.md](CONCEPTION-MAPPING.md) ;
l'état général du dossier dans [A-FAIRE.md](A-FAIRE.md). Rien n'est répété
ici de ce qui s'y trouve déjà.

---

## 1. À faire de ton côté avant la session

Trois étapes, dans cet ordre. La première est bloquante : rien ne peut être
écrit avant.

### Étape 1 — donner deux PID distincts aux deux Alpha Prime

Elite Dangerous désigne un périphérique par une chaîne **VID+PID**
(`Device="3344012F"` = fabricant `3344`, produit `012F`), pas par un GUID
DirectInput comme DCS. Deux Alpha Prime sortis d'usine portent exactement la
même chaîne : le jeu les confond, et tout bind posé sur l'un vaut pour
l'autre.

1. Ouvrir le **VPC Configuration Tool**, onglet **Profile**.
2. Changer le PID de **l'un seulement** des deux manches.
3. Écrire le firmware, débrancher, rebrancher.
4. Vérifier dans l'écran **Contrôles** du jeu que les deux manches réagissent
   séparément.

Note le nouveau PID quelque part : le relevé le confirmera, mais savoir
lequel des deux manches a été modifié évite de les confondre ensuite.

### Étape 2 — faire écrire au jeu un fichier qui voit les quatre périphériques

Le jeu n'écrit sur disque qu'à la **sortie propre** de l'écran Contrôles, et
il ne mentionne un périphérique que s'il porte au moins un bind.

1. Brancher les quatre périphériques (deux manches, throttle CM3, PTO2).
2. Dans l'écran Contrôles, assigner **une commande quelconque sur chacun des
   quatre** — n'importe laquelle, elle sera effacée.
3. Quitter l'écran Contrôles proprement, puis quitter le jeu.

### Étape 3 — lancer le relevé

```
powershell -ExecutionPolicy Bypass -File tools\collect-ed-rig.ps1
```

Le script sauvegarde d'abord tout le dossier Bindings dans un zip horodaté
(sous `Documents\Claude\ED-sauvegardes`), puis écrit
`ED/data/releve-rig.json` et affiche un résumé. Il dira notamment :

- les quatre chaînes VID+PID réelles, telles que **le jeu** les nomme ;
- s'il reste deux périphériques sous la même chaîne — la panne de l'étape 1 ;
- le plus grand numéro de bouton que le jeu lit sur chaque périphérique ;
- le numéro de schéma du preset actif (`4.2`, `4.3`…).

**Sonder les numéros hauts.** Le script compare chaque exécution à la
précédente et affiche les binds **apparus depuis**. C'est la façon rapide de
relever les vrais numéros : assigner une commande jetable sur un cran du
rotacteur MODE du CM3, quitter, relancer le script — il dit exactement quel
numéro le jeu a lu. À répéter pour les cinq crans, et pour tout bouton
au-delà de 32.

Puis commiter `ED/data/releve-rig.json`.

---

## 2. Ce que la session trouvera prêt

### La chaîne d'outils, testée

| Outil | Rôle |
| --- | --- |
| `tools/collect-ed-rig.ps1` | relève le rig, sauvegarde, détecte les VID+PID en double, diffe avec le relevé précédent |
| `tools/parse-ed-binds.ps1` | lit un `.binds` → `ed-bindings.json` + `ed-actions.json`, signale les conflits réels |
| `tools/validate-ed-mapping.py` | refuse un plan de mapping incohérent — dix règles |
| `tools/apply-ed-mapping.py` | écrit le plan dans le `.binds` du jeu, avec sauvegarde |

Ces outils ont été vérifiés en bout en bout dans l'environnement, sur un
`.binds` synthétique de 514 actions : le plan s'écrit, se relit par le
parseur PowerShell — un outil indépendant de celui qui a écrit — et celui-ci
voit bien les quatre périphériques, les 82 binds, la couche de modificateur
inter-périphérique, et **aucun conflit**. La sauvegarde avant écrasement a
été vérifiée octet par octet.

Ce qui ne peut pas être testé ici : le comportement du **jeu** lui-même. Voir
§ 5.

### Le plan de mapping, en données

`ED/data/ed-mapping-plan.json` traduit la section 4 du document de conception
en données exploitables : 12 axes et 81 boutons, chacun avec son périphérique,
sa touche, son repère physique, et la raison du choix. Chaque entrée porte
deux marqueurs :

- **`statut`** — `retenu` (s'écrit dans le `.binds`) ou `a-trancher`
  (listé, mais pas écrit : une décision manque). 82 retenues, 11 en attente.
- **`confiance`** — `releve-dcs` (numéro déjà relevé sur ton rig) ou
  `a-confirmer` (à figer par le relevé). 23 entrées retenues reposent
  aujourd'hui sur un numéro à confirmer.

Les chaînes `Device` des quatre périphériques sont **volontairement nulles**.
Elles viennent du relevé, jamais d'une supposition ; `apply-ed-mapping.py`
refuse de tourner tant qu'elles manquent.

### Ce qui a été vérifié sur le plan

Aucun nom d'action n'est inventé : les 93 entrées sont recoupées avec les
514 actions du catalogue, et le validateur vérifie en plus que l'action est
bien du bon type, que `toggleOn` ne tombe que sur l'une des 26 actions qui
acceptent le maintien, que la syntaxe de touche est connue du jeu, qu'aucun
numéro ne dépasse ce que porte le périphérique, et qu'aucune commande du
noyau ne manque. Les treize règles ont été testées une par une, contre des
plans volontairement cassés.

---

## 3. Les décisions qui attendent une réponse

Quatre sont ouvertes depuis le document de conception. Quatre autres sont
apparues en traduisant la proposition en données — ce sont des trous réels de
la proposition publiée, pas des préférences.

### Encore ouvertes depuis la conception

| | Question | Recommandation |
| --- | --- | --- |
| 3 | **Le pédalier** compte-t-il comme cinquième périphérique ? | Rester à trois axes par manche pour commencer, décider après le premier vol. Le lacet est faible et lent sur la plupart des vaisseaux. |
| 4 | **Twist du manche gauche** = poussée verticale ? | Oui : elle sert en permanence à l'amarrage et au combat rapproché. Couches `_Landing` laissées vides. |
| 5 | **Plage de la manette des gaz** | Avant seul, plus `ToggleReverseThrottleInput` sur un bouton. Avec un levier CM3 sans cran central, la plage complète place le zéro au milieu de la course et divise par deux la finesse dans la zone bleue. |
| 6 | **Focus interface** maintenu ou basculé ? | Maintenu, cohérent avec la palette droite — quitte à revenir dessus si garder un panneau ouvert en pilotant manque trop. |

### Apparues en écrivant le plan

| | Constat | Proposition |
| --- | --- | --- |
| A | **`UI_Up` / `Down` / `Left` / `Right` / `Select` ne sont assignés nulle part** dans la proposition publiée. Maintenir la palette ouvre donc un panneau qu'on ne peut pas parcourir. | Les poser sur le **hat A du manche droit**. Leur contexte est `interface`, le hat A porte du ciblage en contexte `vaisseau` : les deux coexistent sans conflit et sans modificateur. Coût nul — c'est exactement ce que la mécanique de contextes d'Elite permet. |
| B | **Une action n'a que deux emplacements** (`Primary`, `Secondary`), et trois touches étaient prévues pour le train, le collecteur et les phares — bascule du manche gauche *et* PTO2. | Le PTO2 détient l'état. Un inverseur dont les deux positions émettent un numéro prend les deux emplacements, pour que sa position physique reste l'état (train, phares, vision nocturne, lignes d'orbite). Là où une seule touche suffit (collecteur en maintien, verrous de rotation, cartes, alternat), le second emplacement va au manche. Conséquence : le doublon de train et de phares sur le manche gauche disparaît, et les boutons 28/29 du manche gauche redeviennent libres. |
| C | **La portée du scanner est proposée trois fois** : molette du manche droit, levier du manche droit, second levier du throttle. | Garder la molette, crantée et sans dérive. Laisser les leviers à l'accord du FSS, qui profite réellement d'un analogique. |
| D | Le document donne les quatre actions d'un hat **sans dire quelle direction porte laquelle**. | Règle unique, appliquée partout dans le plan : **horizontal = défiler une liste, vertical = désigner ou valider**. |

Les quatre premières sont dans `ED/CONCEPTION-MAPPING.md` § 5 ; les quatre
suivantes dans le champ `arbitrages` du plan, avec leur constat détaillé.

---

## 4. Déroulé proposé pour la session

1. Lire `ED/data/releve-rig.json` et **figer les quatre chaînes `Device`** dans
   le plan, ainsi que le numéro de schéma.
2. Remonter les 23 entrées `a-confirmer` dont le numéro est maintenant connu.
3. Trancher les huit décisions ci-dessus, et basculer les 11 entrées
   `a-trancher` en `retenu` ou les retirer.
4. `python3 tools/validate-ed-mapping.py` — doit sortir sans erreur.
5. `python3 tools/apply-ed-mapping.py --binds <le .binds du jeu> --blanc`
   pour le bilan, puis sans `--blanc` pour écrire.
6. Mettre à jour `StartPreset.*.start`, lancer le jeu, **vérifier dans l'écran
   Contrôles qu'aucune ligne n'est rouge**.
7. Relancer `tools\parse-ed-binds.ps1` pour régénérer les JSON depuis le
   fichier réellement en service, et commiter.
8. Alors seulement : les planches `ED/mapping-hotas.html`, qui se génèrent
   depuis le plan et les gabarits déjà présents dans `SC/img/`.

Les contextes SRV, à pied, FSS, DSS et équipage viennent **après** le noyau
vaisseau : ils se posent sur les mêmes doigts sans rien déplacer, puisque
c'est le jeu qui bascule. Le rotacteur MODE du CM3 reste un confort
mnémotechnique, jamais le chemin vers une commande vitale.

---

## 5. Ce qui reste à vérifier en jeu, et qui ne peut pas l'être avant

Quatre points sont documentés comme probables, pas comme certains. Ils se
vérifient en dix minutes au premier vol, et chacun change une décision s'il
tombe du mauvais côté.

1. **Les axes `_Landing` laissés vides coupent-ils les axes normaux train
   sorti ?** Le profil de référence dépouillé laisse les 23 entrées
   `_Landing` et `Alternate` vides et vole correctement train sorti — c'est
   une observation sur un fichier, pas une confirmation en vol. Si les axes
   se coupent, il faut remplir la couche atterrissage à l'identique.
2. **Jusqu'à quel numéro de bouton le jeu lit-il ?** Le profil de référence
   prouve `Joy_74`. Les pages Rouge et Jaune du rotacteur MODE du CM3 montent
   à 79 sur ce rig d'après le relevé DCS. À sonder par la méthode du § 1,
   étape 3, avant d'y placer quoi que ce soit d'utile.
3. **`ToggleOn = 0` vaut-il bien « maintien » ?** C'est la lecture retenue, et
   tout le traitement du PTO2 en dépend — c'est ce qui permet qu'un inverseur
   maintenu *soit* l'état plutôt que de dériver. À confirmer sur une seule
   action (`ToggleCargoScoop` est la plus lisible : le collecteur s'ouvre et
   se ferme à vue).
4. **Les chaînes exactes des réglages** `UIFocusMode` et `ThrottleRange` ne
   sont pas écrites dans le plan : elles sont à relever en basculant le
   réglage depuis le jeu puis en relisant le fichier. Les écrire de mémoire
   est le genre d'erreur qui fait silencieusement retomber un réglage sur sa
   valeur par défaut.

---

## 6. Rappel des pièges propres à Elite Dangerous

- **Le fichier du jeu fait foi.** `apply-ed-mapping.py` modifie le `.binds`
  écrit par le jeu au lieu d'en fabriquer un : c'est ce qui garantit qu'on
  respecte la forme et le numéro de schéma attendus sans rien deviner. Un
  fichier `4.0` n'est pas lu par un jeu qui attend `4.2`.
- **Elite attend l'intégralité du schéma** dans le fichier, y compris les
  actions laissées en `Device="{NoDevice}"`. Partir du fichier du jeu évite
  d'en oublier une.
- **Sauvegarder avant d'écraser**, toujours. Les deux outils qui écrivent le
  font d'eux-mêmes, mais le dossier Bindings mérite aussi son zip.
- **Pas de commande ON et OFF séparées**, contrairement à DCS. Train, points
  durs, phares, vision nocturne, lignes d'orbite sont des bascules pures :
  seules les 26 actions qui portent un élément `ToggleOn` peuvent vraiment
  tenir sur un inverseur maintenu.
- **Les points durs rentrent d'eux-mêmes** à l'entrée en supercroisière : ne
  jamais les mettre sur un inverseur maintenu, la position physique mentirait.
- **Le contexte est gratuit, le modificateur est cher.** Deux actions de
  contextes différents partagent une touche sans conflit — c'est la force du
  jeu. Avec ~184 entrées physiques pour 82 commandes de vaisseau utiles,
  aucun modificateur n'est nécessaire en vol.
