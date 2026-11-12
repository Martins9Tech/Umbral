"""Resumen de las partidas registradas de Umbral (TECNICO §4.9).

Lee los JSON que el juego guarda al terminar cada partida y muestra:
victorias, tiempo medio, causas de muerte, reparto de daño por arma,
armas, aumentos y sinergias más elegidos, y nivel medio por minuto.

Uso:
    python tools/telemetry_report.py                # partidas del jugador
    python tools/telemetry_report.py --modo bot     # partidas del bot
    python tools/telemetry_report.py --modo todos
    python tools/telemetry_report.py --dir RUTA     # otra carpeta
"""

import argparse
import json
import os
import sys
from collections import Counter, defaultdict
from pathlib import Path


def default_dir() -> Path:
    appdata = os.environ.get("APPDATA", str(Path.home() / ".local" / "share"))
    return Path(appdata) / "Godot" / "app_userdata" / "Umbral" / "telemetry"


def load_runs(folder: Path, mode: str) -> list[dict]:
    runs = []
    for path in sorted(folder.glob("partida_*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if mode == "todos" or data.get("modo") == mode:
            runs.append(data)
    return runs


def fmt_time(seconds: float) -> str:
    return f"{int(seconds // 60)}:{int(seconds % 60):02d}"


def report(runs: list[dict]) -> None:
    total = len(runs)
    wins = [r for r in runs if r.get("resultado") == "victoria"]
    print(f"Partidas: {total}   ·   Victorias: {len(wins)} ({100 * len(wins) / total:.0f} %)")
    print(f"Tiempo medio: {fmt_time(sum(r['tiempo_s'] for r in runs) / total)}"
          f"   ·   Nivel medio final: {sum(r['nivel'] for r in runs) / total:.1f}"
          f"   ·   Oro medio: {sum(r.get('oro_ganado', 0) for r in runs) / total:.0f}")

    causes = Counter(r["causa_muerte"] for r in runs if r.get("causa_muerte"))
    if causes:
        print("\nCausas de muerte:")
        for cause, amount in causes.most_common():
            print(f"  {cause:<32} {amount}")

    damage_share = defaultdict(list)
    for r in runs:
        damage = r.get("dano_por_fuente", {})
        run_total = sum(damage.values()) or 1
        for source, amount in damage.items():
            damage_share[source].append(100 * amount / run_total)
    if damage_share:
        print("\nReparto medio del daño (en las partidas en que aparece):")
        ranked = sorted(damage_share.items(), key=lambda kv: -sum(kv[1]) / len(kv[1]))
        for source, shares in ranked:
            print(f"  {source:<28} {sum(shares) / len(shares):5.1f} %   ({len(shares)} partidas)")

    picks = Counter()
    for r in runs:
        for weapon in r.get("armas", []):
            picks[weapon["id"]] += 1
    print("\nArmas más llevadas:")
    for weapon_id, amount in picks.most_common():
        print(f"  {weapon_id:<28} {100 * amount / total:5.0f} %")

    augments = Counter(a for r in runs for a in r.get("aumentos", []))
    if augments:
        print("\nAumentos más elegidos:")
        for augment_id, amount in augments.most_common(10):
            print(f"  {augment_id:<28} {amount}")

    synergies = Counter()
    for r in runs:
        for tag, amount in r.get("sinergias", {}).items():
            if amount >= 2:
                synergies[tag] += 1
    if synergies:
        print("\nSinergias activadas (2+ armas):")
        for tag, amount in synergies.most_common():
            print(f"  {tag:<28} {100 * amount / total:5.0f} %")

    by_minute = defaultdict(list)
    for r in runs:
        for snap in r.get("instantaneas", []):
            by_minute[snap["minuto"]].append(snap["nivel"])
    if by_minute:
        print("\nNivel medio por minuto (partidas que llegan a ese minuto):")
        for minute in sorted(by_minute):
            levels = by_minute[minute]
            print(f"  min {minute:>2}: nivel {sum(levels) / len(levels):5.1f}   ({len(levels)} partidas)")


def main() -> None:
    # La consola de Windows no usa UTF-8 por defecto: sin esto, los acentos salen mal.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dir", type=Path, default=default_dir())
    parser.add_argument("--modo", default="jugador", choices=["jugador", "bot", "quieto", "todos"])
    args = parser.parse_args()
    if not args.dir.exists():
        print(f"No hay partidas registradas todavía ({args.dir}).")
        return
    runs = load_runs(args.dir, args.modo)
    if not runs:
        print(f"No hay partidas en modo '{args.modo}' en {args.dir}.")
        return
    report(runs)


if __name__ == "__main__":
    main()
