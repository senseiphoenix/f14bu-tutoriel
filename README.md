# F14BU Tutoriel

Site de tutoriels de pilotage pour **DCS World**, hébergé sur GitHub Pages à l'adresse :
👉 https://senseiphoenix.github.io/f14bu-tutoriel/

Ce dépôt regroupe des tutoriels HTML interactifs, un par module, pour apprendre à piloter certains avions dans DCS World. Chaque tutoriel est une appli web autonome (HTML/CSS/JS) organisée en sections, avec suivi de progression conservé localement dans le navigateur.

## Contenu

- **`index.html`** — page d'accueil, une catégorie par simulateur (DCS World, Star Citizen).
- **`F14BU/`** — tutoriel de pilotage du **F-14B(U)** (mod Heatblur), 7 sections : navigation, appontage sur porte-avions, combat air-air, survie, air-sol, gestion de mission, plus une section illustrée et un mapping HOTAS.
- **`F4U1D/`** — tutoriel de pilotage du **F4U-1D Corsair**, 7 sections : cockpit, démarrage, décollage, vol, appontage, urgences, armement.
- **`SC/`** — **Star Citizen** : aide au pilotage de vaisseau et mapping du rig HOSAS (deux Virpil, throttle CM3, WinWing PTO2, pédalier Fanatec). En construction ; les données de binds sont générées depuis les profils exportés par le jeu, voir `tools/README.md`.

## Fonctionnement

Chaque module de tutoriel est une page HTML statique. La progression de l'utilisateur dans chaque section est sauvegardée dans le stockage local du navigateur — il est donc recommandé de toujours utiliser le même navigateur pour conserver l'avancement.

## Origine

Les fichiers de ce dépôt sont générés et mis à jour avec l'aide de Claude, puis déployés ici pour être consultés via GitHub Pages plutôt qu'en local.

## Licence

Projet personnel, à usage pédagogique pour la communauté DCS World.
