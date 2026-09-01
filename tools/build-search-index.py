#!/usr/bin/env python3
"""Régénère data/search-index.json à partir des pages HTML du dépôt.

Trois familles d'entrées :
- "page"    : une par fichier HTML, titre = balise <title>.
- "leçon"   : extraites des tableaux JS `id:"xx", title:"..."` /
              `id: "xx", ... nm:"..."` des pages section-*.html (F14BU,
              F4U1D, F4E) — chaque aircraft-tuto a son propre format, d'où
              les deux regex.
- "fonction": commandes HOTAS non vides de chaque data/*-bindings.json
              trouvé (actuellement seul F14BU/data/f14bu-bindings.json
              existe ; le script reprendra automatiquement les autres
              dossiers avion le jour où ils auront le même format).

Rejoue-le après toute modification des pages section-*.html, des titres de
page, ou des fichiers *-bindings.json :

    python3 tools/build-search-index.py
"""
import html
import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

AIRCRAFT_BY_FOLDER = {
    "F14BU": "F-14B(U)",
    "F4U1D": "F4U-1D Corsair",
    "F4E": "F-4E Phantom II",
    "SC": "Star Citizen",
    "ED": "Elite Dangerous",
}

TITLE_RE = re.compile(r"<title>(.*?)</title>", re.IGNORECASE | re.DOTALL)
LESSON_TITLE_RE = re.compile(r'\bid:\s*"([a-zA-Z0-9_-]+)"\s*,\s*title:\s*"([^"]*)"')
LESSON_NM_RE = re.compile(r'\bid:\s*"([a-zA-Z0-9_-]+)"\s*,[^}]{0,200}?\bnm:\s*"([^"]*)"')


def clean_text(raw):
    return html.unescape(re.sub(r"\s+", " ", raw)).strip()


def norm_key(s):
    s = unicodedata.normalize("NFD", s.lower())
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return s.strip()


def aircraft_for(rel_path):
    top = rel_path.split("/", 1)[0]
    return AIRCRAFT_BY_FOLDER.get(top)


def page_entries():
    entries = []
    for f in sorted(ROOT.glob("**/*.html")):
        rel = f.relative_to(ROOT).as_posix()
        if rel.startswith("SC/profile exemple/"):
            continue
        text = f.read_text(encoding="utf-8")
        m = TITLE_RE.search(text)
        if not m:
            continue
        title = clean_text(m.group(1))
        if not title:
            continue
        entries.append({
            "title": title,
            "path": rel,
            "aircraft": aircraft_for(rel),
            "type": "page",
        })
    return entries


def lesson_entries():
    entries = []
    for f in sorted(ROOT.glob("*/section-*.html")):
        rel = f.relative_to(ROOT).as_posix()
        aircraft = aircraft_for(rel)
        if not aircraft:
            continue
        text = f.read_text(encoding="utf-8")
        seen_ids = set()
        for pattern in (LESSON_TITLE_RE, LESSON_NM_RE):
            for m in pattern.finditer(text):
                lesson_id, title = m.group(1), clean_text(m.group(2))
                if lesson_id in seen_ids or not title:
                    continue
                seen_ids.add(lesson_id)
                entries.append({
                    "title": title,
                    "path": f"{rel}#{lesson_id}",
                    "aircraft": aircraft,
                    "type": "leçon",
                })
    return entries


def function_entries():
    entries = []
    seen = set()
    for f in sorted(ROOT.glob("*/data/*-bindings.json")):
        rel_folder = f.relative_to(ROOT).parts[0]
        aircraft = AIRCRAFT_BY_FOLDER.get(rel_folder)
        if not aircraft:
            continue
        try:
            data = json.loads(f.read_text(encoding="utf-8-sig"))
        except json.JSONDecodeError as e:
            print(f"! {f}: JSON invalide ({e}), ignoré")
            continue
        bindings = data.get("bindings")
        if not isinstance(bindings, list):
            # schéma différent (p. ex. SC/data/sc-bindings.json, sorti du
            # profil brut du jeu) : pas encore le format device/n/commands.
            continue
        for b in bindings:
            device, n = b.get("device"), b.get("n")
            for cmd in b.get("commands") or []:
                cmd = clean_text(cmd)
                if not cmd:
                    continue
                key = (rel_folder, device, n, cmd)
                if key in seen:
                    continue
                seen.add(key)
                path = f"{rel_folder}/mapping-hotas.html?dev={device}&n={n}"
                entries.append({
                    "title": cmd,
                    "path": path,
                    "aircraft": aircraft,
                    "type": "fonction",
                })
    return entries


def main():
    entries = page_entries() + lesson_entries() + function_entries()

    # dédoublonnage strict (même type, même titre normalisé, même avion,
    # même page) : peut arriver si une commande HOTAS est bindée deux fois
    # sur le même périphérique.
    dedup = {}
    for e in entries:
        key = (e["type"], norm_key(e["title"]), e["aircraft"], e["path"])
        dedup[key] = e
    entries = list(dedup.values())
    entries.sort(key=lambda e: (e["type"], e["aircraft"] or "", norm_key(e["title"])))

    out = ROOT / "data" / "search-index.json"
    out.write_text(json.dumps(entries, ensure_ascii=False, indent=1), encoding="utf-8")
    by_type = {}
    for e in entries:
        by_type[e["type"]] = by_type.get(e["type"], 0) + 1
    print(f"{len(entries)} entrées écrites dans {out.relative_to(ROOT)} : {by_type}")


if __name__ == "__main__":
    main()
