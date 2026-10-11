#!/usr/bin/env python3
"""Applique ED/data/ed-mapping-plan.json a un fichier .binds d'Elite Dangerous.

PRINCIPE. Le script ne fabrique PAS un .binds de zero : il modifie celui que
le jeu a ecrit. C'est ce qui garantit qu'on respecte la forme exacte attendue
par la version installee -- numero de schema, actions presentes, structure de
chaque bloc -- sans rien deviner. Elite attend l'integralite du schema dans le
fichier, y compris les actions laissees en Device="{NoDevice}" : partir du
fichier du jeu evite d'en oublier une.

    # verification a blanc, n'ecrit rien
    python3 tools/apply-ed-mapping.py --binds Custom.4.2.binds --blanc

    # ecriture, avec les chaines Device relevees
    python3 tools/apply-ed-mapping.py --binds Custom.4.2.binds \
        --device mancheDroit=3344012F --device mancheGauche=3344812F \
        --device throttle=3344A26B --device pto2=4098BB10 \
        --out Custom.4.2.binds

    # test de bout en bout, sans aucun fichier du jeu
    python3 tools/apply-ed-mapping.py --autotest

Par defaut le script EFFACE d'abord toute entree du fichier qui renvoie a l'un
des quatre peripheriques du plan, puis ecrit le plan. Le resultat correspond
donc exactement au plan, sans residu d'un profil precedent. --conserver
desactive ce nettoyage.

Une sauvegarde horodatee du fichier de sortie est ecrite avant tout
remplacement. Lancer tools/validate-ed-mapping.py avant : ce script refuse un
plan qui ne passe pas la validation de base.
"""
import argparse
import json
import re
import shutil
import sys
import tempfile
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NODEV = "{NoDevice}"


# --------------------------------------------------------------- utilitaires

def slot_elem(action_el, nom):
    """Element de slot (Binding / Primary / Secondary), cree si absent."""
    el = action_el.find(nom)
    if el is None:
        el = ET.SubElement(action_el, nom)
    return el


def vider_slot(el):
    el.set("Device", NODEV)
    el.set("Key", "")
    for enfant in list(el):
        if enfant.tag in ("Modifier", "Hold"):
            el.remove(enfant)


def poser_valeur(parent, tag, valeur):
    el = parent.find(tag)
    if el is None:
        el = ET.SubElement(parent, tag)
    el.set("Value", str(valeur))


# ------------------------------------------------------------------- travail

def appliquer(arbre, plan, devices, conserver=False):
    """Modifie l'arbre en place. Retourne (binds, reglages, ignorees, soucis, efface)."""
    racine = arbre.getroot()
    par_nom = {}
    for el in racine:
        par_nom.setdefault(el.tag, el)

    nos_devices = set(d for d in devices.values() if d)
    efface = 0

    # 1. Nettoyage : toute entree renvoyant a l'un de NOS peripheriques part.
    #    Les binds clavier, souris et autres materiels sont laisses intacts.
    if not conserver:
        for el in racine:
            for nom in ("Binding", "Primary", "Secondary"):
                s = el.find(nom)
                if s is not None and s.get("Device") in nos_devices:
                    vider_slot(s)
                    efface += 1

    # 2. Ecriture du plan.
    ecrites, ignorees, soucis = 0, [], []

    for e in plan["axes"] + plan["boutons"]:
        nom = e["action"]
        if e["statut"] != "retenu":
            ignorees.append("%s (%s)" % (nom, e["statut"]))
            continue

        dev = devices.get(e["peripherique"])
        if not dev:
            soucis.append("%s : chaine Device inconnue pour '%s'" % (nom, e["peripherique"]))
            continue

        action_el = par_nom.get(nom)
        if action_el is None:
            soucis.append("%s : action absente du .binds -- version de schema differente ?" % nom)
            continue

        est_axe = e in plan["axes"]
        s = slot_elem(action_el, "Binding" if est_axe else e.get("slot", "Primary"))
        vider_slot(s)
        s.set("Device", dev)
        s.set("Key", e["key"])

        if est_axe:
            if e.get("inverse") is not None:
                poser_valeur(action_el, "Inverted", 1 if e["inverse"] else 0)
            if e.get("zoneMorte") is not None:
                poser_valeur(action_el, "Deadzone", "%.2f" % float(e["zoneMorte"]))
        else:
            # Le second slot doit exister meme vide, sinon le jeu peut recracher
            # le bloc : on s'assure que les deux sont presents.
            slot_elem(action_el, "Primary")
            slot_elem(action_el, "Secondary")
            for autre in ("Primary", "Secondary"):
                a = action_el.find(autre)
                if a.get("Device") is None:
                    a.set("Device", NODEV)
                    a.set("Key", "")
            if "toggleOn" in e:
                poser_valeur(action_el, "ToggleOn", e["toggleOn"])
            if e.get("appuiLong"):
                poser_valeur(s, "Hold", 1)
            mod = e.get("modificateur")
            if mod:
                mdev = devices.get(mod["peripherique"])
                if not mdev:
                    soucis.append("%s : modificateur sur '%s', chaine Device inconnue"
                                  % (nom, mod["peripherique"]))
                else:
                    m = ET.SubElement(s, "Modifier")
                    m.set("Device", mdev)
                    m.set("Key", mod["key"])
        ecrites += 1

    # 3. Reglages (Value=) : meme regle que les binds -- seul ce qui est
    #    tranche ET decide s'ecrit.
    reglages = 0
    for nom, r in plan.get("reglages", {}).items():
        if r.get("statut") != "retenu":
            ignorees.append("reglage %s (%s)" % (nom, r.get("statut", "sans statut")))
            continue
        if r.get("valeur") is None:
            ignorees.append("reglage %s (valeur non tranchee)" % nom)
            continue
        el = par_nom.get(nom)
        if el is None:
            soucis.append("reglage %s absent du .binds" % nom)
            continue
        el.set("Value", str(r["valeur"]))
        reglages += 1

    return ecrites, reglages, ignorees, soucis, efface


def ecrire(arbre, chemin, sauvegarder=True):
    chemin = Path(chemin)
    if sauvegarder and chemin.exists():
        stamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        copie = chemin.with_suffix(chemin.suffix + ".%s.sauvegarde" % stamp)
        shutil.copy2(chemin, copie)
        print("Sauvegarde : %s" % copie)
    arbre.write(chemin, encoding="UTF-8", xml_declaration=True)


# ------------------------------------------------------------------ autotest

def binds_synthetique(actions, chemin):
    """Fabrique un .binds a la forme du schema, pour tester la chaine sans le jeu.

    Sert UNIQUEMENT a l'autotest. Ce fichier n'est jamais une reference : la
    forme qui fait foi est celle du fichier ecrit par le jeu.
    """
    out = ['<?xml version="1.0" encoding="UTF-8" ?>',
           '<Root PresetName="Autotest" MajorVersion="4" MinorVersion="2">']
    for nom, meta in actions.items():
        if meta["kind"] == "reglage":
            out.append('\t<%s Value="0" />' % nom)
        elif meta["kind"] == "axe":
            out.append('\t<%s>\n\t\t<Binding Device="{NoDevice}" Key="" />'
                       '\n\t\t<Inverted Value="0" />\n\t\t<Deadzone Value="0.00" />\n\t</%s>'
                       % (nom, nom))
        else:
            bloc = ['\t<%s>' % nom,
                    '\t\t<Primary Device="{NoDevice}" Key="" />',
                    '\t\t<Secondary Device="{NoDevice}" Key="" />']
            if meta.get("toggleable"):
                bloc.append('\t\t<ToggleOn Value="1" />')
            bloc.append('\t</%s>' % nom)
            out.append("\n".join(bloc))
    out.append('</Root>')
    Path(chemin).write_text("\n".join(out), encoding="utf-8")


def autotest(plan, actions):
    devices = {"mancheDroit": "3344012F", "mancheGauche": "3344812F",
               "throttle": "3344A26B", "pto2": "4098BB10"}
    tmp = Path(tempfile.mkdtemp(prefix="ed-autotest-"))
    src = tmp / "Custom.4.2.binds"
    binds_synthetique(actions, src)

    # Residu d'un profil precedent : doit disparaitre au nettoyage.
    arbre = ET.parse(src)
    racine = arbre.getroot()
    residu = racine.find("SetSpeed75")
    residu.find("Primary").set("Device", "3344012F")
    residu.find("Primary").set("Key", "Joy_17")
    # Et un bind clavier, qui doit SURVIVRE.
    temoin = racine.find("UI_Toggle")
    temoin.find("Primary").set("Device", "Keyboard")
    temoin.find("Primary").set("Key", "Key_Tab")
    arbre.write(src, encoding="UTF-8", xml_declaration=True)

    arbre = ET.parse(src)
    ecrites, reglages, ignorees, soucis, efface = appliquer(arbre, plan, devices)
    out = tmp / "resultat.binds"
    ecrire(arbre, out, sauvegarder=False)

    # Relecture : chaque entree retenue doit etre retrouvee a l'identique.
    relu = ET.parse(out).getroot()
    par_nom = {el.tag: el for el in relu}
    echecs = []
    attendus = 0
    for e in plan["axes"] + plan["boutons"]:
        if e["statut"] != "retenu":
            continue
        attendus += 1
        el = par_nom.get(e["action"])
        if el is None:
            echecs.append("%s : bloc absent du resultat" % e["action"])
            continue
        est_axe = e in plan["axes"]
        s = el.find("Binding" if est_axe else e.get("slot", "Primary"))
        if s is None:
            echecs.append("%s : slot absent" % e["action"])
            continue
        if s.get("Device") != devices[e["peripherique"]] or s.get("Key") != e["key"]:
            echecs.append("%s : attendu %s/%s, trouve %s/%s" % (
                e["action"], devices[e["peripherique"]], e["key"],
                s.get("Device"), s.get("Key")))
        if "toggleOn" in e:
            t = el.find("ToggleOn")
            if t is None or t.get("Value") != str(e["toggleOn"]):
                echecs.append("%s : ToggleOn non pose" % e["action"])
        mod = e.get("modificateur")
        if mod:
            m = s.find("Modifier")
            if m is None or m.get("Device") != devices[mod["peripherique"]]:
                echecs.append("%s : modificateur non pose" % e["action"])

    # Le residu doit avoir ete efface...
    r = par_nom["SetSpeed75"].find("Primary")
    if r.get("Device") != NODEV:
        echecs.append("residu du profil precedent non efface : SetSpeed75")
    # ...et le bind clavier avoir survecu.
    t = par_nom["UI_Toggle"].find("Primary")
    if t.get("Device") != "Keyboard" or t.get("Key") != "Key_Tab":
        echecs.append("bind clavier efface a tort : UI_Toggle")
    # Le schema ne doit pas avoir bouge.
    if relu.get("MajorVersion") != "4" or relu.get("MinorVersion") != "2":
        echecs.append("version de schema alteree")
    # Aucune action du schema ne doit avoir disparu.
    if len(list(relu)) != len(actions):
        echecs.append("le resultat ne contient plus les %d actions du schema" % len(actions))

    if ecrites != attendus:
        echecs.append("%d binds ecrits pour %d attendus" % (ecrites, attendus))

    print("Autotest")
    print("  actions du schema : %d" % len(list(relu)))
    print("  binds ecrits      : %d (attendus %d)" % (ecrites, attendus))
    print("  reglages ecrits   : %d" % reglages)
    print("  residus effaces   : %d" % efface)
    print("  entrees ignorees  : %d" % len(ignorees))
    for s_ in soucis:
        print("  souci : %s" % s_)
    for f in echecs:
        print("  ECHEC : %s" % f)
    shutil.rmtree(tmp, ignore_errors=True)
    if echecs or soucis:
        return 1
    print("  autotest OK : le plan s'ecrit et se relit sans perte.")
    return 0


# ---------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--binds", help="fichier .binds ecrit par le jeu (entree)")
    ap.add_argument("--out", help="fichier a ecrire (defaut : le meme, apres sauvegarde)")
    ap.add_argument("--plan", default=str(ROOT / "ED" / "data" / "ed-mapping-plan.json"))
    ap.add_argument("--actions", default=str(ROOT / "ED" / "data" / "ed-actions.json"))
    ap.add_argument("--releve", default=str(ROOT / "ED" / "data" / "releve-rig.json"),
                    help="releve du rig, pour verifier les chaines Device")
    ap.add_argument("--device", action="append", default=[], metavar="ROLE=CHAINE",
                    help="chaine Device d'un role, ex. mancheDroit=3344012F")
    ap.add_argument("--preset", help="renomme le preset (attribut PresetName)")
    ap.add_argument("--conserver", action="store_true",
                    help="ne pas effacer les entrees existantes de nos peripheriques")
    ap.add_argument("--blanc", action="store_true", help="n'ecrit rien, affiche le bilan")
    ap.add_argument("--autotest", action="store_true",
                    help="test de bout en bout sur un .binds synthetique")
    args = ap.parse_args()

    plan = json.loads(Path(args.plan).read_text(encoding="utf-8"))
    actions = json.loads(Path(args.actions).read_text(encoding="utf-8"))["actions"]

    if args.autotest:
        return autotest(plan, actions)

    if not args.binds:
        ap.error("--binds est requis (ou --autotest)")

    # Chaines Device : le plan d'abord, puis les --device de la ligne de commande.
    devices = {}
    for role, d in plan["peripheriques"].items():
        devices[role] = d.get("device")
    for spec in args.device:
        if "=" not in spec:
            ap.error("--device attend ROLE=CHAINE, recu : %s" % spec)
        role, chaine = spec.split("=", 1)
        if role not in devices:
            ap.error("role inconnu du plan : %s" % role)
        devices[role] = chaine.strip()

    # Le releve fait foi : on refuse une chaine qu'il n'a pas vue.
    releve = Path(args.releve)
    if releve.exists():
        try:
            r = json.loads(releve.read_text(encoding="utf-8-sig"))
            vues = set()
            for p in r.get("peripheriques", []):
                vues.add(p.get("device"))
            for w in r.get("windows", []):
                vues.add(w.get("edDevice"))
            for role, d in devices.items():
                if d and vues and d not in vues:
                    print("  attention : %s = %s n'apparait pas dans le releve du rig" % (role, d))
        except (ValueError, OSError) as exc:
            print("  attention : releve du rig illisible (%s) -- chaines Device non verifiees"
                  % exc.__class__.__name__)
    else:
        print("  attention : pas de releve du rig (%s) -- chaines Device non verifiees" % releve.name)

    manquants = [r for r, d in devices.items() if not d]
    if manquants:
        print("\nChaines Device manquantes : %s" % ", ".join(sorted(manquants)))
        print("Lancer d'abord tools/collect-ed-rig.ps1 cote Windows, puis renseigner")
        print("peripheriques.<role>.device dans le plan, ou passer --device role=CHAINE.")
        return 1

    arbre = ET.parse(args.binds)
    if args.preset:
        arbre.getroot().set("PresetName", args.preset)

    ecrites, reglages, ignorees, soucis, efface = appliquer(arbre, plan, devices, args.conserver)

    print("\nEntree   : %s" % args.binds)
    print("Schema   : %s.%s" % (arbre.getroot().get("MajorVersion"),
                                arbre.getroot().get("MinorVersion")))
    print("Preset   : %s" % arbre.getroot().get("PresetName"))
    print("Effacees : %d entrees de nos peripheriques" % efface)
    print("Ecrites  : %d binds + %d reglages" % (ecrites, reglages))
    print("Ignorees : %d" % len(ignorees))
    for i in ignorees:
        print("    - %s" % i)
    for s in soucis:
        print("  souci : %s" % s)

    if soucis:
        print("\nRien n'a ete ecrit : regler les soucis ci-dessus d'abord.")
        return 1
    if args.blanc:
        print("\n--blanc : aucun fichier ecrit.")
        return 0

    cible = args.out if args.out else args.binds
    ecrire(arbre, cible)
    print("Ecrit    : %s" % cible)
    print("\nNe pas oublier : mettre a jour StartPreset.*.start pour que le jeu")
    print("selectionne ce preset au lancement.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
