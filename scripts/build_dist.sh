#!/usr/bin/env bash
# Rebuild dist/nyyo-n8n-workflows-install-kit.zip from the repo (deterministic file list, executable bit kept on setup.sh).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=dist/nyyo-n8n-workflows-install-kit.zip
STAGE="$(mktemp -d)"; D="$STAGE/nyyo-n8n-workflow-templates"
mkdir -p "$D"
cp README.md INSTALL.md LICENSE docker-compose.yml .env.example setup.sh setup.ps1 "$D/"
cp install-kit/README.md "$D/INSTALL-KIT.md"; cp install-kit/manifest.json "$D/"
cp -r workflows docs sheet-headers test-data "$D/"
chmod 755 "$D/setup.sh" "$D/test-data/01_sample_leads.sh"
# Safety: refuse to ship a real .env or anything that looks like a secret.
[ ! -e "$D/.env" ] || { echo "refusing: .env in kit"; exit 1; }
if grep -rEn '(sk-[A-Za-z0-9]{20,}|xox[bp]-[0-9]|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY)' "$D"; then echo "refusing: secret-like string"; exit 1; fi
rm -f "$OUT"; mkdir -p dist
python3 - "$STAGE" "$OUT" <<'PY'
import os, sys, zipfile
stage, out = sys.argv[1], sys.argv[2]
files = sorted(os.path.relpath(os.path.join(r, f), stage) for r, _, fs in os.walk(stage) for f in fs)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for rel in files:
        full = os.path.join(stage, rel)
        zi = zipfile.ZipInfo.from_file(full, rel)
        zi.create_system = 3  # Unix, so the executable bit on setup.sh survives unzip on Mac/Linux
        zi.compress_type = zipfile.ZIP_DEFLATED
        with open(full, "rb") as fh: z.writestr(zi, fh.read())
PY
rm -rf "$STAGE"
unzip -l "$OUT" | tail -n1
