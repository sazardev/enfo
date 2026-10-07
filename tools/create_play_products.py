#!/usr/bin/env python3
"""Create or update the five Enfo donation products in Google Play.

Products (one-time, consumable): enfo_donate_1, _3, _5, _10, _25.

Uses the new one-time products API (monetization.onetimeproducts) and converts
one base price per tier to every Play region with monetization.convertRegionPrices.

Auth (first match wins):
    1. --token ACCESS_TOKEN
    2. --json-key PATH, $PLAY_JSON_KEY or ~/.config/enfo/play-service-account.json
    3. gcloud Application Default Credentials (needs a quota project:
       --quota-project or the current gcloud project)

Usage:
    python3 tools/create_play_products.py [--dry-run] [--update] [--list]
        [--currency USD] [--amounts 0.99,2.99,4.99,9.99,24.99]
        [--quota-project PROJECT]
"""
import argparse, base64, json, os, subprocess, sys, tempfile, time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

PACKAGE = "com.sazarcode.enfo"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
# Google's transcoding is inconsistent: list uses oneTimeProducts, item paths
# use onetimeproducts (see the REST reference for patch/get).
LIST_URL = f"{API}/{PACKAGE}/oneTimeProducts"
ITEM_URL = f"{API}/{PACKAGE}/onetimeproducts"
ACTIVATE_URL = (f"{API}/{PACKAGE}/oneTimeProducts/-"
                "/purchaseOptions:batchUpdateStates")
SCOPE = "https://www.googleapis.com/auth/androidpublisher"
SKUS = ["enfo_donate_1", "enfo_donate_3", "enfo_donate_5",
        "enfo_donate_10", "enfo_donate_25"]
DEFAULT_AMOUNTS = [0.99, 2.99, 4.99, 9.99, 24.99]
LISTINGS = {
    "en-US": ("Donation", "One-time donation to support Enfo."),
    "es-419": ("Donación", "Donación única para apoyar a Enfo."),
    "es-ES": ("Donación", "Donación única para apoyar a Enfo."),
    "de-DE": ("Spende", "Einmalige Spende zur Unterstützung von Enfo."),
    "fr-FR": ("Don", "Don unique pour soutenir Enfo."),
    "pt-BR": ("Doação", "Doação única para apoiar o Enfo."),
    "hi-IN": ("दान", "Enfo का साथ देने के लिए एक बार का दान।"),
    "ja-JP": ("寄付", "Enfoを応援する1回限りの寄付。"),
    "ko-KR": ("후원", "Enfo를 응원하는 1회 후원."),
    "zh-CN": ("捐赠", "支持 Enfo 的一次性捐赠。"),
}


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def service_account_token(key_path: Path) -> str:
    info = json.loads(key_path.read_text(encoding="utf-8"))
    now = int(time.time())
    header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    claims = b64url(json.dumps({
        "iss": info["client_email"],
        "scope": SCOPE,
        "aud": "https://oauth2.googleapis.com/token",
        "iat": now,
        "exp": now + 3600,
    }).encode())
    signing_input = f"{header}.{claims}".encode()
    with tempfile.NamedTemporaryFile("w", suffix=".pem", delete=False) as f:
        f.write(info["private_key"])
        pem = f.name
    try:
        signature = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", pem],
            input=signing_input, capture_output=True, check=True,
        ).stdout
    finally:
        os.unlink(pem)
    assertion = f"{header}.{claims}.{b64url(signature)}"
    body = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": assertion,
    }).encode()
    with urllib.request.urlopen("https://oauth2.googleapis.com/token", body) as r:
        return json.load(r)["access_token"]


def gcloud_token() -> str:
    out = subprocess.run(
        ["gcloud", "auth", "application-default", "print-access-token"],
        capture_output=True, text=True,
    )
    if out.returncode:
        sys.exit(
            "No hay credenciales. Ejecuta primero:\n"
            "  gcloud auth application-default login "
            f"--scopes={SCOPE}\n"
            "o pasa --json-key con la clave de una cuenta de servicio."
        )
    return out.stdout.strip()


def gcloud_project():
    out = subprocess.run(["gcloud", "config", "get-value", "project"],
                         capture_output=True, text=True)
    project = out.stdout.strip()
    if out.returncode or not project or project == "(unset)":
        return None
    return project


def request(method: str, url: str, token: str, payload=None, quota_project=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    if quota_project:
        req.add_header("x-goog-user-project", quota_project)
    if data:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            body = r.read()
            return r.status, json.loads(body) if body else None
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        try:
            return e.code, json.loads(body)
        except json.JSONDecodeError:
            return e.code, {"raw": body}


def money(amount: float, currency: str) -> dict:
    units = int(amount)
    nanos = round((amount - units) * 1_000_000_000)
    return {"currencyCode": currency, "units": str(units), "nanos": nanos}


def convert_prices(token, amount, currency, quota_project):
    url = f"{API}/{PACKAGE}/pricing:convertRegionPrices"
    status, body = request("POST", url, token,
                           {"price": money(amount, currency)}, quota_project)
    if status != 200:
        sys.exit(f"convertRegionPrices {amount} {currency}: {status} {body}")
    return body


def product_payload(sku: str, conversion: dict) -> dict:
    regions = conversion["convertedRegionPrices"]
    other = conversion.get("convertedOtherRegionsPrice") or {}
    option = {
        "purchaseOptionId": "buy",
        "buyOption": {"legacyCompatible": True, "multiQuantityEnabled": True},
        "regionalPricingAndAvailabilityConfigs": [
            {
                "regionCode": code,
                "price": data["price"],
                "availability": "AVAILABLE",
            }
            for code, data in regions.items()
        ],
    }
    if other.get("usdPrice") and other.get("eurPrice"):
        option["newRegionsConfig"] = {
            "usdPrice": other["usdPrice"],
            "eurPrice": other["eurPrice"],
            "availability": "AVAILABLE",
        }
    return {
        "packageName": PACKAGE,
        "productId": sku,
        "listings": [
            {"languageCode": loc, "title": title, "description": desc}
            for loc, (title, desc) in LISTINGS.items()
        ],
        "purchaseOptions": [option],
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--token")
    ap.add_argument("--json-key")
    ap.add_argument("--currency", default="USD")
    ap.add_argument("--amounts", default=",".join(str(a) for a in DEFAULT_AMOUNTS))
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--update", action="store_true",
                    help="overwrite products that already exist")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--quota-project",
                    help="GCP project with the API enabled (for user credentials)")
    args = ap.parse_args()

    amounts = [float(a) for a in args.amounts.split(",")]
    if len(amounts) != len(SKUS):
        sys.exit(f"--amounts necesita {len(SKUS)} valores")

    if args.dry_run:
        fake = {"convertedRegionPrices": {}, "convertedOtherRegionsPrice": {}}
        for sku in SKUS:
            print(json.dumps(product_payload(sku, fake),
                             ensure_ascii=False, indent=2))
        print("(dry-run: sin precios convertidos por región)")
        return 0

    if args.token:
        token = args.token
        quota_project = args.quota_project
    else:
        key = args.json_key or os.environ.get("PLAY_JSON_KEY") or \
            str(Path.home() / ".config/enfo/play-service-account.json")
        if Path(key).exists():
            token = service_account_token(Path(key))
            quota_project = None
        else:
            token = gcloud_token()
            quota_project = args.quota_project or gcloud_project()

    if args.list:
        status, body = request("GET", LIST_URL, token, quota_project=quota_project)
        if status == 204 or body is None:
            print("0 productos")
            return 0
        if status != 200:
            print(f"Error {status}: {body}")
            return 1
        products = body.get("oneTimeProducts", [])
        for p in products:
            states = [o.get("state") for o in p.get("purchaseOptions", [])]
            print(f"{p.get('productId', '?'):20} {states}")
        print(f"{len(products)} producto(s)")
        return 0

    conversions = {}
    region_version = None
    failures = 0
    for sku, amount in zip(SKUS, amounts):
        status, existing = request("GET", f"{ITEM_URL}/{sku}", token,
                                   quota_project=quota_project)
        exists = status == 200
        if exists and not args.update:
            print(f"{sku}: ya existe (usa --update para sobrescribir)")
            continue
        if amount not in conversions:
            conversions[amount] = convert_prices(token, amount, args.currency,
                                                 quota_project)
        conversion = conversions[amount]
        region_version = conversion.get("regionVersion", {}).get("version")
        payload = product_payload(sku, conversion)
        query = urllib.parse.urlencode({
            "updateMask": "listings,purchaseOptions",
            "allowMissing": "true",
            "latencyTolerance":
                "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT",
            "regionsVersion.version": region_version or "",
        })
        status, body = request("PATCH", f"{ITEM_URL}/{sku}?{query}", token,
                               payload, quota_project)
        if status in (200, 201):
            print(f"{sku}: {'actualizado' if exists else 'creado'} "
                  f"({amount} {args.currency}, {len(payload['purchaseOptions'][0]['regionalPricingAndAvailabilityConfigs'])} regiones)")
        else:
            failures += 1
            print(f"{sku}: ERROR {status}: {body}")

    if not failures:
        status, body = request("POST", ACTIVATE_URL, token, {"requests": [
            {"activatePurchaseOptionRequest": {
                "packageName": PACKAGE,
                "productId": sku,
                "purchaseOptionId": "buy",
                "latencyTolerance":
                    "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT",
            }}
            for sku in SKUS
        ]}, quota_project)
        if status in (200, 201):
            print("Opciones de compra activadas (buy).")
        else:
            failures += 1
            print(f"ERROR activando: {status} {body}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
