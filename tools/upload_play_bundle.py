#!/usr/bin/env python3
"""Upload an AAB to Google Play and assign it to a track.

    python3 tools/upload_play_bundle.py [--track internal] [--status completed]
        [--aab build/app/outputs/bundle/release/app-release.aab]
        [--notes "text"] [--quota-project PROJECT] [--json-key PATH]

Release notes: with --notes, only en-US is sent. Without it, every
store/fastlane/metadata/android/<locale>/changelogs/<versionCode>.txt is sent
localized. Auth: same as tools/create_play_products.py (service account JSON,
or gcloud Application Default Credentials with a quota project).
"""
import argparse, base64, json, os, subprocess, sys, tempfile, time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

PACKAGE = "com.sazarcode.enfo"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"


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
        sys.exit("Sin credenciales. Ejecuta `gcloud auth application-default "
                 f"login --scopes={SCOPE}` o pasa --json-key.")
    return out.stdout.strip()


def gcloud_project():
    out = subprocess.run(["gcloud", "config", "get-value", "project"],
                         capture_output=True, text=True)
    project = out.stdout.strip()
    if out.returncode or not project or project == "(unset)":
        return None
    return project


def fastlane_notes(version_code: str):
    """What's-new per locale from the fastlane changelogs for a versionCode."""
    base = Path(__file__).resolve().parent.parent / "store" / "fastlane" / \
        "metadata" / "android"
    notes = []
    if base.is_dir():
        for lang_dir in sorted(base.iterdir()):
            f = lang_dir / "changelogs" / f"{version_code}.txt"
            if f.is_file():
                text = f.read_text(encoding="utf-8").strip()
                if text:
                    notes.append({"language": lang_dir.name, "text": text})
    return notes


def request(method, url, token, payload=None, quota_project=None, raw=None,
            content_type=None):
    data = raw if raw is not None else (
        json.dumps(payload).encode() if payload is not None else None)
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    if quota_project:
        req.add_header("x-goog-user-project", quota_project)
    if content_type:
        req.add_header("Content-Type", content_type)
    elif data:
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


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--aab", default="build/app/outputs/bundle/release/app-release.aab")
    ap.add_argument("--version-code",
                    help="use an already-uploaded version code (skips the upload)")
    ap.add_argument("--track", default="internal")
    ap.add_argument("--status", default="completed",
                    choices=["completed", "draft", "halted", "inProgress"])
    ap.add_argument("--notes", default="")
    ap.add_argument("--json-key")
    ap.add_argument("--quota-project")
    args = ap.parse_args()

    aab = Path(args.aab)
    if not args.version_code and not aab.exists():
        sys.exit(f"No existe {aab}. Compila con: flutter build appbundle --release")

    key = args.json_key or os.environ.get("PLAY_JSON_KEY") or \
        str(Path.home() / ".config/enfo/play-service-account.json")
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

    if args.version_code:
        version_code = args.version_code
        print(f"Usando versionCode existente {version_code} (sin subir AAB)")
    else:
        size = aab.stat().st_size
        print(f"Subiendo {aab} ({size / 1e6:.1f} MB)...")
        status, bundle = request(
            "POST", f"{UPLOAD}/{PACKAGE}/edits/{edit_id}/bundles?uploadType=media",
            token, quota_project=quota_project, raw=aab.read_bytes(),
            content_type="application/octet-stream")
        if status not in (200, 201):
            print(f"Error subiendo bundle: {status} {bundle}")
            return 1
        version_code = str(bundle["versionCode"])
        print(f"Bundle subido: versionCode {version_code}")

    release = {"versionCodes": [version_code], "status": args.status}
    if args.notes:
        release["releaseNotes"] = [{"language": "en-US", "text": args.notes}]
    else:
        notes = fastlane_notes(version_code)
        if notes:
            release["releaseNotes"] = notes
            langs = ", ".join(n["language"] for n in notes)
            print(f"Novedades localizadas ({len(notes)}): {langs}")
        else:
            print(f"Sin novedades para el versionCode {version_code}")
    status, track = request(
        "PUT", f"{API}/{PACKAGE}/edits/{edit_id}/tracks/{args.track}",
        token, {"track": args.track, "releases": [release]}, quota_project)
    if status not in (200, 201):
        print(f"Error asignando track: {status} {track}")
        return 1
    print(f"Asignado al track {args.track} ({args.status})")

    status, commit = request(
        "POST", f"{API}/{PACKAGE}/edits/{edit_id}:commit", token, {},
        quota_project)
    if status not in (200, 201):
        print(f"Error al confirmar: {status} {commit}")
        return 1
    print("Publicado (edit confirmado).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
