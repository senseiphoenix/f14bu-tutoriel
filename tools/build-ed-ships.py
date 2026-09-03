#!/usr/bin/env python3
"""Régénère ED/data/ed-ships.json à partir de la base de données Coriolis.

Source : https://github.com/EDCD/coriolis-data — le dépôt de données du
configurateur Coriolis, maintenu par EDCD (Elite Dangerous Community
Developers). Un fichier JSON par vaisseau dans `ships/`, avec les
caractéristiques de coque exactes du jeu.

Ce script ne fait que *lire* et *dériver* : aucune valeur n'est saisie à la
main. Les rôles, libellés et descriptions françaises vivent dans
`ED/data/ed-ships-fr.json`, écrit à la main et jamais touché ici.

Deux modes :

    python3 tools/build-ed-ships.py                     # télécharge depuis GitHub
    python3 tools/build-ed-ships.py --coriolis <dossier> # lit un clone local

Sémantique des emplacements internes, telle que Coriolis l'encode :

- un entier          = emplacement optionnel libre (soute possible)
- {"name":"Cargo"}   = emplacement réservé à la soute
- {"name":"Military"}= emplacement militaire (blindage, cellules) — indice
                       de vaisseau de combat
- {"name":"Limpets"} = emplacement réservé aux drones — indice de minage
- {"name":"Fighter"} = hangar à chasseur
- {"name":"PlanetaryApproachSuite"} = suite d'approche planétaire, exclue de
                       tous les décomptes

La soute maximale théorique vaut donc la somme des 2^classe sur les
emplacements libres et « Cargo » : c'est le chiffre qu'affiche Coriolis, à
condition de ne rien monter d'autre (ni bouclier, ni collecteur de carburant).
"""
import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = "https://raw.githubusercontent.com/EDCD/coriolis-data/master/ships/"
INDEX_RE = re.compile(r"require\('\./([a-z0-9_]+)'\)")

# Classe de coque -> plateforme d'atterrissage exigée.
PAD = {1: "petite", 2: "moyenne", 3: "grande"}


def fetch(name):
    with urllib.request.urlopen(RAW + name, timeout=30) as r:
        return r.read().decode("utf-8")


def ship_files(coriolis):
    """Noms de fichiers de vaisseau, lus dans ships/index.js."""
    if coriolis:
        text = (Path(coriolis) / "ships" / "index.js").read_text(encoding="utf-8")
    else:
        text = fetch("index.js")
    seen, out = set(), []
    for m in INDEX_RE.finditer(text):
        if m.group(1) not in seen:
            seen.add(m.group(1))
            out.append(m.group(1) + ".json")
    return out


def load_ship(coriolis, fname):
    if coriolis:
        raw = (Path(coriolis) / "ships" / fname).read_text(encoding="utf-8")
    else:
        raw = fetch(fname)
    d = json.loads(raw)
    key = next(iter(d))
    return key, d[key]


def slot_class(x):
    return x if isinstance(x, int) else x.get("class", 0)


def slot_name(x):
    return None if isinstance(x, int) else x.get("name")


def derive(key, s):
    p = s["properties"]

    hard = [slot_class(x) for x in s["slots"]["hardpoints"]]
    utility = s["slots"].get("utility", [])
    internals = s["slots"]["internal"]

    cargo = 0
    military = 0
    limpets = 0
    fighter = 0
    optional = []
    for x in internals:
        n, c = slot_name(x), slot_class(x)
        if n == "PlanetaryApproachSuite":
            continue
        if n == "Military":
            military += 1
        elif n == "Limpets":
            limpets += 1
            optional.append(c)
        elif n == "Fighter":
            fighter += 1
            optional.append(c)
        else:                       # entier libre ou emplacement « Cargo »
            cargo += 2 ** c
            optional.append(c)

    armed = [h for h in hard if h]
    return {
        "id": key,
        "nom": p["name"],
        "constructeur": p["manufacturer"],
        "taille": p["class"],
        "plateforme": PAD.get(p["class"], "?"),
        "prixCoque": p["hullCost"],
        "prixCatalogue": s.get("retailCost", p["hullCost"]),
        "masseCoque": p["hullMass"],
        "vitesse": p["speed"],
        "boost": p["boost"],
        "blindage": p["baseArmour"],
        "bouclier": p["baseShieldStrength"],
        "durete": p["hardness"],
        "tangage": p["pitch"],
        "roulis": p["roll"],
        "lacet": p["yaw"],
        "equipage": p["crew"],
        "masslock": p.get("masslock"),
        "pointsDurs": armed,
        "nbPointsDurs": len(armed),
        "plusGrosPointDur": max(hard) if armed else 0,
        # Somme des classes de points durs : indice de puissance de feu brute,
        # comparable d'un vaisseau a l'autre.
        "poidsArmement": sum(armed),
        "nbUtilitaires": len(utility),
        "emplacementsOptionnels": sorted(optional, reverse=True),
        "plusGrosOptionnel": max(optional) if optional else 0,
        "souteMax": cargo,
        "emplacementsMilitaires": military,
        "emplacementsDrones": limpets,
        "hangarChasseur": fighter > 0,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--coriolis", help="dossier d'un clone de EDCD/coriolis-data")
    ap.add_argument("--out", default=str(ROOT / "ED" / "data" / "ed-ships.json"))
    args = ap.parse_args()

    files = ship_files(args.coriolis)
    ships = {}
    for fname in files:
        key, s = load_ship(args.coriolis, fname)
        row = derive(key, s)
        ships[row["id"]] = row

    order = sorted(ships, key=lambda k: (ships[k]["taille"], ships[k]["prixCoque"]))
    out = {
        "generatedBy": "tools/build-ed-ships.py",
        "note": (
            "Caracteristiques de coque des vaisseaux d'Elite Dangerous, derivees "
            "de la base de donnees Coriolis (EDCD/coriolis-data). Regenere a "
            "chaque execution : ne jamais editer a la main. Les roles et les "
            "descriptions francaises sont dans ed-ships-fr.json."
        ),
        "source": {
            "depot": "https://github.com/EDCD/coriolis-data",
            "chemin": "ships/*.json",
            "mode": "clone local" if args.coriolis else "telechargement GitHub",
        },
        "champs": {
            "taille": "1 = petit, 2 = moyen, 3 = grand (taille de plateforme exigee)",
            "souteMax": "somme des 2^classe sur les emplacements optionnels et Cargo, hors suite d'approche planetaire : capacite theorique tout en soute",
            "poidsArmement": "somme des classes de points durs, indice de puissance de feu brute",
            "emplacementsMilitaires": "emplacements reserves au blindage et aux cellules : indice de vaisseau de combat",
            "emplacementsDrones": "emplacements reserves aux drones : indice de minage et de recuperation",
        },
        "counts": {"vaisseaux": len(ships)},
        "ships": {k: ships[k] for k in order},
    }

    path = Path(args.out)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(out, ensure_ascii=True, indent=1), encoding="utf-8")
    print(f"{len(ships)} vaisseaux ecrits dans {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
