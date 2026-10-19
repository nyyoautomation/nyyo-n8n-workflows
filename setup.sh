#!/usr/bin/env bash
# One-command setup for the Nyyo Automation n8n templates (Mac / Linux).
#   ./setup.sh               start n8n with SQLite and import the 3 workflows
#   ./setup.sh --postgres    same, with a Postgres database (choose this on the first run)
#   ./setup.sh --port 5679   use another port on this computer
# Safe to run again: it never overwrites your .env and skips workflows that are already imported.
# Guide: INSTALL.md. Questions? Ask in your order chat.
set -euo pipefail

cd "$(dirname "$0")"

USE_POSTGRES=0
PORT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --postgres) USE_POSTGRES=1 ;;
    --port) shift; PORT_ARG="${1:-}" ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (try ./setup.sh --help)"; exit 2 ;;
  esac
  shift
done

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32mOK\033[0m  %s\n' "$*"; }
warn() { printf '    \033[33m!!\033[0m  %s\n' "$*"; }
die()  { printf '\n\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

random_hex() {
  if command -v openssl >/dev/null 2>&1; then openssl rand -hex "$1"
  else head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; fi
}

# Replace KEY=... in .env (portable: no "sed -i", which differs between Mac and Linux).
set_env() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  awk -v k="$key" -v v="$value" 'BEGIN{done=0} $0 ~ "^"k"=" {print k"="v; done=1; next} {print} END{if(!done) print k"="v}' .env > "$tmp"
  cat "$tmp" > .env && rm -f "$tmp"
}
get_env() { awk -F= -v k="$1" '$1==k {sub(/^[^=]*=/, ""); print; exit}' .env; }

detect_timezone() {
  local tz=""
  if [ -n "${TZ:-}" ]; then tz="$TZ"
  elif [ -L /etc/localtime ]; then tz="$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')"
  elif [ -f /etc/timezone ]; then tz="$(cat /etc/timezone)"; fi
  case "$tz" in */*|UTC) echo "$tz" ;; *) echo "UTC" ;; esac
}

# ---------------------------------------------------------------- 1. Docker
say "1/5 Checking Docker"
command -v docker >/dev/null 2>&1 || die "Docker is not installed. Install Docker Desktop (Mac/Windows) or Docker Engine (Linux), then run this script again. See INSTALL.md, step 1."
docker info >/dev/null 2>&1 || die "Docker is installed but not running. Open Docker Desktop, wait until it says 'Engine running', then run this script again."
if docker compose version >/dev/null 2>&1; then DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then DC="docker-compose"
else die "Docker Compose is missing. Update Docker Desktop, or install the docker-compose-plugin package on Linux."; fi
ok "$(docker --version)"
ok "$($DC version | head -n1)"

# ---------------------------------------------------------------- 2. .env
say "2/5 Preparing settings (.env)"
[ -f docker-compose.yml ] && [ -f .env.example ] && [ -d workflows ] || die "Run this script from the unzipped kit folder (docker-compose.yml, .env.example and workflows/ must be next to it)."
if [ ! -f .env ]; then
  cp .env.example .env
  set_env N8N_ENCRYPTION_KEY "$(random_hex 32)"
  set_env POSTGRES_PASSWORD "$(random_hex 24)"
  set_env TIMEZONE "$(detect_timezone)"
  if [ "$USE_POSTGRES" = 1 ]; then
    set_env COMPOSE_PROFILES postgres
    set_env DB_TYPE postgresdb
  fi
  chmod 600 .env
  ok "Created .env with a random encryption key (keep this file private, and back it up)"
else
  ok "Keeping your existing .env"
  if [ "$USE_POSTGRES" = 1 ] && [ "$(get_env DB_TYPE)" != "postgresdb" ]; then
    warn "--postgres ignored: this install already uses SQLite. Switching databases does not move your data (see INSTALL.md, 'Use Postgres')."
  fi
fi
if grep -Eq '^[A-Z0-9_]+=REPLACE_WITH_' .env; then
  set_env N8N_ENCRYPTION_KEY "$(random_hex 32)"; set_env POSTGRES_PASSWORD "$(random_hex 24)"
  warn "Replaced placeholder values in .env with random ones"
fi
if [ -n "$PORT_ARG" ]; then
  case "$PORT_ARG" in ''|*[!0-9]*) die "--port needs a number, for example --port 5679" ;; esac
  set_env N8N_PORT "$PORT_ARG"
  set_env WEBHOOK_URL "http://localhost:$PORT_ARG/"
fi
PORT="$(get_env N8N_PORT)"; PORT="${PORT:-5678}"
URL="http://localhost:$PORT"
ok "Database: $( [ "$(get_env DB_TYPE)" = postgresdb ] && echo Postgres || echo SQLite ) · Time zone: $(get_env TIMEZONE) · Address: $URL"

# ---------------------------------------------------------------- 3. Start
say "3/5 Starting n8n (the first start downloads about 1 GB, allow a few minutes)"
if ! $DC up -d; then
  die "n8n did not start. If the message says 'port is already allocated', run ./setup.sh --port 5679. Otherwise see INSTALL.md, Troubleshooting."
fi

say "4/5 Waiting for n8n to be ready"
ready=0
for _ in $(seq 1 90); do
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "$URL/healthz/readiness" >/dev/null 2>&1 && { ready=1; break; }
  else
    $DC exec -T n8n wget -qO- http://localhost:5678/healthz/readiness >/dev/null 2>&1 && { ready=1; break; }
  fi
  sleep 2
done
[ "$ready" = 1 ] || die "n8n did not answer on $URL within 3 minutes. Check: $DC logs --tail 50 n8n"
ok "n8n is up at $URL ($($DC exec -T n8n n8n --version 2>/dev/null | tail -n1))"

# ---------------------------------------------------------------- 4. Import
say "5/5 Importing the 3 workflows with the n8n CLI"
existing="$($DC exec -T n8n n8n list:workflow 2>/dev/null || true)"
imported=0; skipped=0
for f in workflows/*.json; do
  name="$(sed -n 's/^  "name": "\(.*\)",$/\1/p' "$f" | head -n1)"
  if [ -n "$name" ] && printf '%s\n' "$existing" | grep -Fq "|$name"; then
    ok "Already there: $name"; skipped=$((skipped+1)); continue
  fi
  if $DC exec -T n8n n8n import:workflow --input="/import/$f" >/dev/null 2>&1; then
    ok "Imported: ${name:-$f}"; imported=$((imported+1))
  else
    die "Import failed for $f. Details: $DC exec n8n n8n import:workflow --input=/import/$f"
  fi
done
total="$($DC exec -T n8n n8n list:workflow 2>/dev/null | grep -c '|' || true)"
ok "$imported imported, $skipped already present, $total workflow(s) in n8n"

cat <<NEXT

$(printf '\033[1;32m')All set. n8n is running at $URL$(printf '\033[0m')

Next steps
  1. Open $URL in your browser and create the owner account.
     This account lives only in your own n8n; nothing is sent to Nyyo Automation.
  2. Open Overview > Workflows. You will see the 3 templates (inactive).
  3. Open one, read the yellow sticky note, fill in the Config node.
  4. Connect your accounts (Google Sheets, Slack, OpenAI, email): docs/INSTALL.md, step 4.
  5. Test with the fictional data in test-data/, then publish (activate) the workflow.

Everyday commands (in this folder)
  Stop:   $DC stop          Start again: $DC up -d
  Logs:   $DC logs -f n8n   Update n8n:  change N8N_VERSION in .env, then $DC up -d
Keep .env private and back it up: it holds the key that protects your saved credentials.
Help: INSTALL.md (Troubleshooting) · Questions? Ask in your order chat.
NEXT
