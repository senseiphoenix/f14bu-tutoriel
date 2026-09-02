# F14BU Tutoriel

Site de tutoriels de pilotage pour **DCS World**, **Star Citizen** et **Elite Dangerous**, hébergé sur GitHub Pages à l'adresse :
👉 https://senseiphoenix.github.io/f14bu-tutoriel/

Ce dépôt regroupe des tutoriels HTML interactifs, un par module, pour apprendre à piloter certains avions dans DCS World. Chaque tutoriel est une appli web (HTML/CSS/JS) organisée en sections, avec suivi de progression conservé localement dans le navigateur. Le thème visuel commun (couleurs, texture de fond, halos de survol, icônes) est partagé par toutes les pages via `css/theme.css`.

## Contenu

- **`index.html`** — page d'accueil, une catégorie par univers : DCS World (un tutoriel par avion) et simulation spatiale (Star Citizen et Elite Dangerous, qui partagent le même rig HOSAS).
- **`F14BU/`** — tutoriel de pilotage du **F-14B(U)** (mod Heatblur). Deux parcours complémentaires :
  - **`pas-a-pas.html`** — 19 tutoriels « une page », en checklists cochables, du premier démarrage à froid jusqu'à la JDAM. C'est l'entrée recommandée pour un débutant : chaque étape dit quoi faire, où, et pourquoi. Chaque tutoriel s'ouvre sur un bloc « En vidéo » (deux démonstrations YouTube choisies pour le sujet, avec un repère indiquant si elles sont tournées sur le B(U) ou sur le F-14A/B classique) ; la liste complète est reprise dans `ressources.html`.
  - **`cursus-complet.html`** et les `section-*.html` — les mêmes sujets en profondeur (7 sections : cockpit et bases, navigation, appontage, air-air, survie, air-sol, mission), qui expliquent le *pourquoi* plutôt que le geste. Chaque leçon renvoie vers son tutoriel pas à pas et inversement.
  - **`mapping-hotas.html`** — planches annotées et cherchables des quatre périphériques, alimentées par `data/f14bu-bindings.json`. Toute fonction citée dans un tutoriel porte un badge cliquable qui ouvre le mapping sur le bon bouton ; les numéros ne sont jamais écrits en dur dans le texte.
- **`F4U1D/`** — tutoriel de pilotage du **F4U-1D Corsair** (module Magnitude 3), organisé comme le F-14B(U) en un parcours à trois étapes :
  - **`pas-a-pas.html`** — 15 tutoriels « une page » en checklists cochables, du premier démarrage à froid jusqu'aux manœuvres de combat, plus `cockpit/index.html` pour le tour du poste. **Au stade du squelette** : structure, liens et progression fonctionnent, le contenu détaillé reste à rédiger depuis le manuel.
  - **`section-*.html`** — le cursus de fond en 7 sections (cockpit, démarrage, décollage, vol, appontage, urgences, armement/radio-nav), **complet et utilisable**.
  - **`perfectionnement.html`** — 5 leçons au-delà du cursus (BFM à hélice, rayon d'action, appontage avancé, attaque au sol coordonnée, Bat Bomb), également au stade du squelette.
  - Outils : `missions.html`, `ressources.html`, `corsair-progression.html` (carnet qui relit la progression de toutes les pages), et `mapping-hotas.html` — **bloqué tant que le matériel réellement utilisé sur cet avion n'a pas été relevé**, la page dit quoi faire pour débloquer plutôt que d'afficher un mapping deviné.
- **`SC/`** — **Star Citizen** : aide au pilotage de vaisseau et mapping du rig HOSAS (deux Virpil, throttle CM3, WinWing PTO2, pédalier Fanatec). En construction ; les données de binds sont générées depuis les profils exportés par le jeu, voir `tools/README.md`.
- **`ED/`** — **Elite Dangerous** : mapping du **même rig HOSAS** que Star Citizen et cursus de pilotage en sept sections. En construction ; la conception du mapping est écrite (`ED/CONCEPTION-MAPPING.md`), les données d'actions sont extraites du fichier `.binds` du jeu par `tools/parse-ed-binds.ps1`. La logique de bindings diffère nettement de celle de Star Citizen : ici c'est le jeu qui bascule entre huit contextes (vaisseau, SRV, à pied, FSS, DSS, équipage, caméra, colonisation), et un même bouton porte donc déjà une action par contexte sans modificateur.

## Fonctionnement

Chaque module de tutoriel est une page HTML statique. La progression de l'utilisateur dans chaque section est sauvegardée dans le stockage local du navigateur — il est donc recommandé de toujours utiliser le même navigateur pour conserver l'avancement.

Le style et le moteur des pages de tutoriel sont mutualisés : `css/tutoriel.css` (mise en page checklist, phases, notes, visionneuse) et `js/tutoriel.js` (progression `localStorage`, visionneuse, badges de bind), paramétrés par des attributs sur `<body>`. Les pages du F4U-1D s'appuient dessus ; celles du F-14B(U) portent encore leur copie en ligne.

Un bouton de recherche flottant (coin bas-droit, raccourci `/`) est présent sur toutes les pages : il cherche dans les titres de page, les leçons et les fonctions HOTAS de tous les avions à la fois (`data/search-index.json`, généré par `tools/build-search-index.py` — ou `tools/build-search-index.ps1`, port PowerShell strictement équivalent pour les machines sans Python). Quand un même intitulé existe sur plusieurs avions, le résultat précise lequel (`F-14B(U) — Tour du cockpit`).

Certaines pages lisent leurs données via `fetch()` (binds HOTAS, planches SVG) : ouvertes directement en `file://`, ces parties resteront vides — dont la recherche elle-même. Pour un aperçu local fidèle, servir le dépôt en HTTP :

```bash
powershell -ExecutionPolicy Bypass -File tools/serve.ps1
```

Chaque leçon du cursus a une URL propre via son ancre (`cursus-complet.html#d5`, `section-a-illustree.html#a5`) — utile pour pointer quelqu'un directement sur la bonne leçon.

## Origine

Les fichiers de ce dépôt sont générés et mis à jour avec l'aide de Claude, puis déployés ici pour être consultés via GitHub Pages plutôt qu'en local.

## Licence

Projet personnel, à usage pédagogique pour la communauté DCS World.
