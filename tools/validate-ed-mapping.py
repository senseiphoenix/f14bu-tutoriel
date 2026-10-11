#!/usr/bin/env python3
"""Verifie ED/data/ed-mapping-plan.json contre le catalogue d'actions du jeu.

Le plan de mapping est ecrit a la main : ce script est le garde-fou. Il ne
corrige rien, il refuse. A lancer apres toute modification du plan, et avant
d'appeler tools/apply-ed-mapping.py.

    python3 tools/validate-ed-mapping.py
    python3 tools/validate-ed-mapping.py --plan autre-plan.json

Ce qu'il refuse (sortie non nulle) :

  1. une action qui n'existe pas dans ED/data/ed-actions.json ;
  2. une action d'axe rangee dans les boutons, ou l'inverse ;
  3. un toggleOn sur une action qui n'accepte pas le maintien (seules 26 des
     352 actions a bouton du schema le font) ;
  4. une touche de syntaxe inconnue du jeu ;
  5. un numero de bouton au-dela de ce que porte le peripherique ;
  6. plus de deux touches pour une meme action : le jeu n'offre que Primary et
     Secondary, pas davantage ;
  7. deux fois le meme slot pour une meme action ;
  8. deux actions du MEME contexte sur la meme touche du meme peripherique --
     c'est le conflit que le jeu affiche en rouge. Deux contextes differents
     sur la meme touche, en revanche, sont la force d'Elite : c'est gratuit ;
  9. un peripherique ou un modificateur qui ne renvoie a rien de declare ;
 10. une action marquee critique laissee en attente de decision : une avarie
     ne previent pas, une commande vitale ne reste pas non assignee.

Ce qu'il signale sans refuser : les numeros a confirmer par le releve, les
chaines Device encore vides, les entrees en attente de decision, et la
couverture par contexte.
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Syntaxe de touche acceptee par Elite Dangerous, telle qu'observee dans les
# fichiers .binds reels. Les demi-axes servent a couper un axe en deux
# boutons analogiques.
KEY_RE = [
    re.compile(r"^Joy_(\d+)$"),                                 # bouton
    re.compile(r"^Joy_POV\d+(Up|Down|Left|Right)$"),            # croix POV
    re.compile(r"^Joy_[A-Z]{1,2}Axis$"),                        # axe plein
    re.compile(r"^(Pos|Neg)_Joy_[A-Z]{1,2}Axis$"),              # demi-axe
    re.compile(r"^Joy_Slider\d+$"),                             # curseur
    re.compile(r"^Key_\S+$"),                                   # clavier
    re.compile(r"^Mouse\S*$"),                                  # souris
]

# Commandes sans lesquelles le mapping n'est pas volable. Separees des
# entrees marquees "critique" dans le plan : celles-la sont les commandes de
# survie, celles-ci le minimum pour decoller.
NOYAU = [
    "RollAxisRaw", "PitchAxisRaw", "YawAxisRaw",
    "LateralThrustRaw", "AheadThrust", "VerticalThrustRaw",
    "ThrottleAxis", "PrimaryFire", "SecondaryFire",
    "UIFocus", "LandingGearToggle", "DeployHardpointToggle",
    "HyperSuperCombination",
]


def key_ok(key):
    return any(r.match(key) for r in KEY_RE)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--plan", default=str(ROOT / "ED" / "data" / "ed-mapping-plan.json"))
    ap.add_argument("--actions", default=str(ROOT / "ED" / "data" / "ed-actions.json"))
    args = ap.parse_args()

    plan = json.loads(Path(args.plan).read_text(encoding="utf-8"))
    cat = json.loads(Path(args.actions).read_text(encoding="utf-8"))["actions"]

    erreurs, avertis = [], []
    devs = plan["peripheriques"]

    def budget(dev):
        d = devs.get(dev, {})
        return d.get("boutonsAvecRotacteur", d.get("boutonsConnus", 0))

    entrees = []
    for e in plan["axes"]:
        entrees.append(("axe", e))
    for e in plan["boutons"]:
        entrees.append(("bouton", e))

    # --- 1 a 5, 9 : chaque entree prise isolement
    for attendu, e in entrees:
        a, dev, key = e["action"], e["peripherique"], e["key"]
        ou = "%s %s/%s" % (a, dev, key)

        meta = cat.get(a)
        if meta is None:
            erreurs.append("action inconnue du catalogue : %s" % ou)
            continue
        if meta["kind"] != attendu:
            erreurs.append("%s : le catalogue la donne '%s', le plan la range dans les %ss"
                           % (ou, meta["kind"], attendu))

        if dev not in devs:
            erreurs.append("%s : peripherique non declare" % ou)

        if not key_ok(key):
            erreurs.append("%s : syntaxe de touche inconnue du jeu" % ou)
        m = re.match(r"^Joy_(\d+)$", key)
        if m and dev in devs:
            n, b = int(m.group(1)), budget(dev)
            if b and n > b:
                erreurs.append("%s : bouton %d au-dela des %d que porte le peripherique"
                               % (ou, n, b))

        if "toggleOn" in e and not meta.get("toggleable"):
            erreurs.append("%s : toggleOn pose sur une action qui n'accepte pas le maintien" % ou)

        mod = e.get("modificateur")
        if mod:
            if mod.get("peripherique") not in devs:
                erreurs.append("%s : modificateur sur un peripherique non declare" % ou)
            elif not key_ok(mod.get("key", "")):
                erreurs.append("%s : touche de modificateur invalide" % ou)

        if e.get("critique") and e["statut"] != "retenu":
            erreurs.append("%s : marquee critique mais laissee en '%s'" % (ou, e["statut"]))

        if e["statut"] not in plan["statuts"]:
            erreurs.append("%s : statut '%s' inconnu" % (ou, e["statut"]))
        if e["confiance"] not in plan["confiance"]:
            erreurs.append("%s : confiance '%s' inconnue" % (ou, e["confiance"]))

    # --- 6 et 7 : le jeu n'offre que deux slots par action
    slots = {}
    for e in plan["boutons"]:
        if e["statut"] != "retenu":
            continue
        slots.setdefault(e["action"], []).append((e.get("slot", "Primary"), e["peripherique"], e["key"]))
    for a, lst in sorted(slots.items()):
        if len(lst) > 2:
            erreurs.append("%s : %d touches pour une action qui n'a que Primary et Secondary -> %s"
                           % (a, len(lst), ", ".join("%s %s/%s" % s for s in lst)))
        vus = [s[0] for s in lst]
        for nom in set(vus):
            if vus.count(nom) > 1:
                erreurs.append("%s : slot %s utilise %d fois" % (a, nom, vus.count(nom)))

    # --- 8 : conflit reel = deux actions du meme contexte sur la meme entree
    occupe = {}
    for attendu, e in entrees:
        if e["statut"] != "retenu":
            continue
        meta = cat.get(e["action"])
        if meta is None:
            continue
        mod = e.get("modificateur")
        couche = ""
        if mod:
            couche = "%s/%s" % (mod.get("peripherique"), mod.get("key"))
        cle = (meta["context"], e["peripherique"], e["key"], couche)
        occupe.setdefault(cle, []).append(e["action"])
    for cle, acts in sorted(occupe.items()):
        uniq = sorted(set(acts))
        if len(uniq) > 1:
            erreurs.append("conflit %s sur %s/%s : %s" % (cle[0], cle[1], cle[2], " + ".join(uniq)))

    # --- noyau volable
    poses = set(e["action"] for _, e in entrees if e["statut"] == "retenu")
    for a in NOYAU:
        if a not in poses:
            erreurs.append("commande du noyau non assignee : %s" % a)

    # --- signalements
    for dev, d in sorted(devs.items()):
        if not d.get("device"):
            avertis.append("peripherique %s : chaine Device vide, a reprendre de releve-rig.json" % dev)
    if not plan["schema"].get("major"):
        avertis.append("version de schema non figee, a reprendre de releve-rig.json")
    aConf = [e for _, e in entrees if e["confiance"] == "a-confirmer" and e["statut"] == "retenu"]
    if aConf:
        avertis.append("%d entrees retenues reposent sur un numero a confirmer par le releve" % len(aConf))
    attente = [e for _, e in entrees if e["statut"] == "a-trancher"]
    if attente:
        avertis.append("%d entrees en attente de decision (non ecrites dans le .binds)" % len(attente))
    for arb in plan.get("arbitrages", []):
        if arb.get("statut") == "a-trancher":
            avertis.append("arbitrage %s non tranche : %s" % (arb["id"], arb["titre"]))

    # --- rapport
    print("Plan    : %s" % Path(args.plan).name)
    print("Entrees : %d axes + %d boutons = %d" % (len(plan["axes"]), len(plan["boutons"]), len(entrees)))
    retenues = [e for _, e in entrees if e["statut"] == "retenu"]
    print("Retenues: %d  |  en attente : %d" % (len(retenues), len(attente)))

    parCtx = {}
    for _, e in entrees:
        if e["statut"] != "retenu":
            continue
        meta = cat.get(e["action"])
        if meta:
            parCtx[meta["context"]] = parCtx.get(meta["context"], 0) + 1
    print("Contexte: " + ", ".join("%s=%d" % kv for kv in sorted(parCtx.items())))

    parDev = {}
    for _, e in entrees:
        if e["statut"] == "retenu":
            parDev[e["peripherique"]] = parDev.get(e["peripherique"], 0) + 1
    print("Perif.  : " + ", ".join("%s=%d" % kv for kv in sorted(parDev.items())))
    print("Maintien: %d entrees reglent toggleOn"
          % len([e for _, e in entrees if "toggleOn" in e]))
    print()

    for w in avertis:
        print("  signale : %s" % w)
    if avertis:
        print()
    for x in erreurs:
        print("  ERREUR  : %s" % x)

    if erreurs:
        print("\n%d erreur(s) : le plan n'est pas applicable." % len(erreurs))
        return 1
    print("Plan coherent : %d entrees applicables." % len(retenues))
    return 0


if __name__ == "__main__":
    sys.exit(main())
