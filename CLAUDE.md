# Instructions pour Claude Code

Ce dépôt contient des tutoriels HTML interactifs pour DCS World (voir
`README.md` pour la structure générale). Ce fichier consigne les bonnes
pratiques apprises en travaillant sur les pages de mapping HOTAS
(`*/mapping-hotas.html`) et sur la génération de binds DCS, pour qu'elles
s'appliquent directement si on refait ce travail sur un autre avion.

## Vérifier ou générer des binds DCS

- **Ne jamais deviner un GUID de périphérique.** DCS écrit lui-même le nom
  et le GUID exacts dans le nom de fichier
  `Saved Games\<instance>\Config\Input\<Module>\joystick\<Nom {GUID}>.diff.lua`.
  Si un périphérique n'a encore aucun bind pour ce module, faire assigner à
  l'utilisateur une commande quelconque dans l'écran Contrôles de DCS puis
  quitter le jeu (l'écriture sur disque n'a lieu qu'à la sortie propre de
  l'écran), puis relire le dossier directement. Ne jamais faire chercher un
  GUID dans le registre Windows ou `Get-PnpDevice` — peu fiable.
- **Les GUID et assignations d'axes dérivent avec le temps** (réinstall de
  pilote, changement de port USB, remplacement de matériel). Revérifier
  l'état actuel via les fichiers `Saved Games` réels avant de faire
  confiance à un ancien profil exporté ou à une donnée déjà présente dans
  `data/*.json` — elle peut être obsolète ou simplement fausse.
- **Vérifier le vrai dossier de module avant de chercher quoi que ce soit.**
  Un mod peut utiliser son propre dossier `Config\Input\<Mod>`, distinct du
  module de base, et se trouver sur une instance DCS différente (stable vs
  Open Beta) de celle qu'on suppose. Énumérer les dossiers
  `Saved Games\DCS*\Config\Input\` réels plutôt que de supposer.
- **Valider tout `.diff.lua` généré avec l'interpréteur Lua de DCS**
  (`<install DCS>\bin\luae.exe`, voir `tools/README.md`) avant de
  l'installer : le charger, vérifier qu'il retourne une table valide, que
  chaque axe utilise une touche reconnue (`JOY_X/Y/Z/RX/RY/RZ`,
  `JOY_SLIDER1/2`), que chaque bouton suit `JOY_BTN<n>` ou
  `JOY_BTN_POV<n>_<direction>`, et qu'aucun numéro de bouton n'est utilisé
  deux fois par erreur. **Toujours sauvegarder le fichier existant avant de
  l'écraser.**
- **Pour un panneau à sélecteur de page/mode** (rotacteur physique à
  plusieurs crans, type Virpil) : ne jamais supposer que toutes les pages
  partagent les mêmes numéros de bouton — le firmware peut émettre un
  numéro DirectInput différent par page. Demander à l'utilisateur les vrais
  numéros par page (ou lui faire sonder chaque page avec une commande
  jetable puis relire le fichier) plutôt que de réutiliser le premier jeu
  de numéros trouvé.

## Concevoir l'organisation des boutons libres/programmables

- Avant d'inventer des thèmes pour des boutons libres (pages d'un
  rotacteur, boutons non affectés), **chercher si l'avion réel / le module
  DCS a déjà une taxonomie officielle de phases ou de modes**, et la
  reprendre plutôt que d'inventer. Chercher le manuel officiel du module
  (souvent fourni par l'utilisateur en PDF, sinon la doc en ligne du studio)
  et le catalogue de commandes DCS du module (champ `categories` dans
  `data/*-commands.json`) pour voir quelles catégories existent déjà.
  Présenter la proposition et les sources avant de coder.
- **Les fonctions critiques/d'urgence restent à une position FIXE**,
  indépendante de la phase de vol — une urgence peut survenir à tout
  moment, ne pas forcer une rotation du sélecteur pour l'atteindre.

## UI des pages de mapping (`mapping-hotas.html`)

- **Un indicateur dynamique (couleur de page, badge) ne doit jamais changer
  la hauteur d'une boîte d'étiquette.** Sur une planche dense, les boîtes
  voisines sont parfois à quelques % l'une de l'autre ; une boîte qui
  grandit chevauche sa voisine et en masque le contenu. Mettre ce genre
  d'indicateur en `position:absolute` (pastille en coin, `outline`) pour
  qu'il reste hors du flux.
- **Toujours vérifier dans le navigateur après une modif visuelle**, pas
  seulement en relisant le code — capture d'écran comparée à l'image
  source, pas seulement un test DOM synthétique (un chevauchement de boîtes
  ou des étiquettes à coordonnées permutées ne se voient pas forcément dans
  un test `getBoundingClientRect`).
- **Si des repères visuels (numéros, pastilles) font partie de l'image
  elle-même**, ils font foi pour la position physique réelle : un défaut de
  correspondance étiquette↔image est un bug de données (coordonnées dans le
  tableau `LABELS`), pas de logique.
- Le survol lie une étiquette sur l'image à sa ligne dans le tableau via un
  index commun (`data-i`, pas le numéro de repère qui peut contenir des
  caractères comme `rX` ou des plages `17-22`) et une délégation
  d'événement sur `document`, ce qui couvre toutes les planches d'un
  périphérique en une seule implémentation partagée.
