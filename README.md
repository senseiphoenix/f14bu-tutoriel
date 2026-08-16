# F14BU Tutoriel

Site de tutoriels de pilotage pour **DCS World**, hébergé sur GitHub Pages à l'adresse :
👉 https://senseiphoenix.github.io/f14bu-tutoriel/

Ce dépôt regroupe des tutoriels HTML interactifs, un par module, pour apprendre à piloter certains avions dans DCS World. Chaque tutoriel est une appli web (HTML/CSS/JS) organisée en sections, avec suivi de progression conservé localement dans le navigateur. Le thème visuel commun (couleurs, texture de fond, halos de survol, icônes) est partagé par toutes les pages via `css/theme.css`.

## Contenu

- **`index.html`** — page d'accueil, une catégorie par simulateur (DCS World, Star Citizen).
- **`F14BU/`** — tutoriel de pilotage du **F-14B(U)** (mod Heatblur). Deux parcours complémentaires :
  - **`pas-a-pas.html`** — 19 tutoriels « une page », en checklists cochables, du premier démarrage à froid jusqu'à la JDAM. C'est l'entrée recommandée pour un débutant : chaque étape dit quoi faire, où, et pourquoi.
  - **`cursus-complet.html`** et les `section-*.html` — les mêmes sujets en profondeur (7 sections : cockpit et bases, navigation, appontage, air-air, survie, air-sol, mission), qui expliquent le *pourquoi* plutôt que le geste. Chaque leçon renvoie vers son tutoriel pas à pas et inversement.
  - **`mapping-hotas.html`** — planches annotées et cherchables des quatre périphériques, alimentées par `data/f14bu-bindings.json`. Toute fonction citée dans un tutoriel porte un badge cliquable qui ouvre le mapping sur le bon bouton ; les numéros ne sont jamais écrits en dur dans le texte.
- **`F4U1D/`** — tutoriel de pilotage du **F4U-1D Corsair**, 7 sections : cockpit, démarrage, décollage, vol, appontage, urgences, armement.
- **`SC/`** — **Star Citizen** : aide au pilotage de vaisseau et mapping du rig HOSAS (deux Virpil, throttle CM3, WinWing PTO2, pédalier Fanatec). En construction ; les données de binds sont générées depuis les profils exportés par le jeu, voir `tools/README.md`.

## Fonctionnement

Chaque module de tutoriel est une page HTML statique. La progression de l'utilisateur dans chaque section est sauvegardée dans le stockage local du navigateur — il est donc recommandé de toujours utiliser le même navigateur pour conserver l'avancement.

Certaines pages lisent leurs données via `fetch()` (binds HOTAS, planches SVG) : ouvertes directement en `file://`, ces parties resteront vides. Pour un aperçu local fidèle, servir le dépôt en HTTP :

```bash
powershell -ExecutionPolicy Bypass -File tools/serve.ps1
```

Chaque leçon du cursus a une URL propre via son ancre (`cursus-complet.html#d5`, `section-a-illustree.html#a5`) — utile pour pointer quelqu'un directement sur la bonne leçon.

## Origine

Les fichiers de ce dépôt sont générés et mis à jour avec l'aide de Claude, puis déployés ici pour être consultés via GitHub Pages plutôt qu'en local.

## Licence

Projet personnel, à usage pédagogique pour la communauté DCS World.
