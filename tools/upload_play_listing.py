#!/usr/bin/env python3
"""Push the fastlane listing texts (title, short and full description) to Play.

    python3 tools/upload_play_listing.py [--dry-run] [--metadata PATH]
        [--json-key PATH] [--quota-project PROJECT]

Reads store/fastlane/metadata/android/<locale>/{title,short_description,
full_description}.txt and patches each language through the Play API, then
commits the edit. Auth and API plumbing live in upload_play_bundle.py.
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from upload_play_bundle import (  # noqa: E402
    API, PACKAGE, gcloud_project, gcloud_token, request, service_account_token)


def load_listings(base: Path):
    listings = []
    for lang_dir in sorted(p for p in base.iterdir() if p.is_dir()):
        entry = {"language": lang_dir.name}
        for key, name in (("title", "title.txt"),
                          ("shortDescription", "short_description.txt"),
                          ("fullDescription", "full_description.txt")):
            f = lang_dir / name
            if f.is_file():
                entry[key] = f.read_text(encoding="utf-8").strip()
        if len(entry) > 1:
            listings.append(entry)
    return listings


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--metadata",
                    default="store/fastlane/metadata/android")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--json-key")
    ap.add_argument("--quota-project")
    args = ap.parse_args()

    root = Path(__file__).resolve().parent.parent
    base = (root / args.metadata).resolve()
    if not base.is_dir():
        sys.exit(f"No existe {base}")
    listings = load_listings(base)
    if not listings:
        sys.exit(f"Sin textos de ficha en {base}")
    print(f"{len(listings)} idiomas: " +
          ", ".join(l["language"] for l in listings))
    if args.dry_run:
        for l in listings:
            print(f"  {l['language']}: {l.get('title', '?')} | "
                  f"{len(l.get('shortDescription', ''))}/80 | "
                  f"{len(l.get('fullDescription', ''))} chars")
        return 0

    key = args.json_key or str(Path.home() / ".config/enfo/play-service-account.json")
    if Path(key).exists():
        token = service_account_token(Path(key))
        quota_project = None
    else:
        token = gcloud_token()
        quota_project = args.quota_project or gcloud_project()

    status, edit = request("POST", f"{API}/{PACKAGE}/edits", token, {},
                           quota_project)
    if status not in (200, 201):
        print(f"Error creando edit: {status} {edit}")
        return 1
    edit_id = edit["id"]
    print(f"Edit {edit_id}")

    # Existing listings: keep fields we do not manage (e.g. the promo video).
    status, existing = request("GET", f"{API}/{PACKAGE}/edits/{edit_id}/listings",
                               token, None, quota_project)
    keep = {l["language"]: l for l in existing.get("listings", [])} \
        if status == 200 else {}

    def abort(message):
        request("DELETE", f"{API}/{PACKAGE}/edits/{edit_id}", token, None,
                quota_project)
        print(message)
        return 1

    ok = 0
    for listing in listings:
        lang = listing.pop("language")
        payload = {"language": lang, **listing}
        if keep.get(lang, {}).get("video"):
            payload["video"] = keep[lang]["video"]
            print(f"  {lang}: conservo el vídeo promocional")
        status, body = request(
            "PUT",
            f"{API}/{PACKAGE}/edits/{edit_id}/listings/{lang}",
            token, payload, quota_project, content_type="application/json")
        if status not in (200, 201):
            return abort(f"Error en {lang}: {status} {body}")
        ok += 1
        print(f"  {lang}: título, descripción corta y larga actualizados")

    status, commit = request("POST", f"{API}/{PACKAGE}/edits/{edit_id}:commit",
                             token, {}, quota_project)
    if status not in (200, 201):
        return abort(f"Error al confirmar: {status} {commit}")
    print(f"Ficha publicada ({ok} idiomas, edit confirmado).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
