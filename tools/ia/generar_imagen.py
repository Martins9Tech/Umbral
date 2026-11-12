"""Genera imágenes con la API de imágenes de Azure AI Foundry (GUIA_ESTILO §11).

La clave se lee de la variable de entorno AZURE_OPENAI_API_KEY (o de las
variables de usuario de Windows); nunca se imprime ni se guarda en el repo.
El endpoint y el despliegue van en tools/ia/config.local.json (ignorado por git):
    {"endpoint": "https://<recurso>.services.ai.azure.com/openai/v1", "deployment": "<modelo>"}

Uso:
    python tools/ia/generar_imagen.py --prompt "..." --out ruta.png [--size 1024x1024]
        [--transparent] [--quality high]
    python tools/ia/generar_imagen.py --lote lote.json   # [{"prompt", "out", ...}, ...]
"""

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

AQUI = os.path.dirname(os.path.abspath(__file__))


def clave():
    valor = os.environ.get("AZURE_OPENAI_API_KEY")
    if not valor and sys.platform == "win32":
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as k:
            valor = winreg.QueryValueEx(k, "AZURE_OPENAI_API_KEY")[0]
    if not valor:
        sys.exit("Falta la variable de entorno AZURE_OPENAI_API_KEY")
    return valor


def config():
    ruta = os.path.join(AQUI, "config.local.json")
    if not os.path.exists(ruta):
        sys.exit("Falta tools/ia/config.local.json con endpoint y deployment")
    return json.load(open(ruta, encoding="utf-8"))


def generar(prompt, out, size="1024x1024", transparent=False, quality="high", reintentos=8):
    cfg = config()
    cuerpo = {"model": cfg["deployment"], "prompt": prompt, "n": 1, "size": size, "quality": quality,
              "output_format": "png"}
    if transparent:
        cuerpo["background"] = "transparent"
    peticion = urllib.request.Request(
        cfg["endpoint"].rstrip("/") + "/images/generations",
        data=json.dumps(cuerpo).encode("utf-8"),
        headers={"Content-Type": "application/json", "api-key": clave()},
        method="POST")
    for intento in range(reintentos):
        inicio = time.time()
        try:
            with urllib.request.urlopen(peticion, timeout=300) as respuesta:
                datos = json.load(respuesta)
            break
        except urllib.error.HTTPError as error:
            detalle = error.read().decode("utf-8", "replace")[:400]
            if error.code in (429, 500, 503) and intento < reintentos - 1:
                print(f"  reintento ({error.code})...")
                time.sleep(min(60, 12 * (intento + 1)))
                continue
            sys.exit(f"Error {error.code}: {detalle}")
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "wb") as f:
        f.write(base64.b64decode(datos["data"][0]["b64_json"]))
    print(f"{out}  ({time.time() - inicio:.0f} s)")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--prompt")
    p.add_argument("--out")
    p.add_argument("--size", default="1024x1024")
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--quality", default="high")
    p.add_argument("--lote")
    p.add_argument("--paralelo", type=int, default=1, help="peticiones a la vez en un lote")
    args = p.parse_args()
    if args.lote:
        pendientes = [item for item in json.load(open(args.lote, encoding="utf-8"))
                      if not (item.get("saltar_si_existe", True) and os.path.exists(item["out"]))]
        print(f"{len(pendientes)} imágenes por generar")

        def una(item):
            try:
                generar(item["prompt"], item["out"], item.get("size", args.size),
                        item.get("transparent", args.transparent), item.get("quality", args.quality))
            except SystemExit as error:
                print(f"FALLO {item['out']}: {error}")

        from concurrent.futures import ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=max(1, args.paralelo)) as pool:
            list(pool.map(una, pendientes))
    else:
        generar(args.prompt, args.out, args.size, args.transparent, args.quality)


main()
