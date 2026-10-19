# One-command setup for the Nyyo Automation n8n templates (Windows PowerShell 5.1+ or PowerShell 7).
#   .\setup.ps1               start n8n with SQLite and import the 3 workflows
#   .\setup.ps1 -Postgres     same, with a Postgres database (choose this on the first run)
#   .\setup.ps1 -Port 5679    use another port on this computer
# If Windows blocks the script, run once:  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# or start it with:  powershell -ExecutionPolicy Bypass -File .\setup.ps1
# Safe to run again: it never overwrites your .env and skips workflows that are already imported.
# Guide: INSTALL.md. Contact: LaborX (https://laborx.com/freelancers/users/id475124)
[CmdletBinding()]
param(
  [switch]$Postgres,
  [ValidateRange(1, 65535)][int]$Port = 0
)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Say($m)  { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "    OK  $m" -ForegroundColor Green }
function Warn($m) { Write-Host "    !!  $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host ""; Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

function New-RandomHex([int]$bytes) {
  $b = New-Object byte[] $bytes
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
  ($b | ForEach-Object { $_.ToString('x2') }) -join ''
}
$EnvFile = Join-Path $PSScriptRoot '.env'
function Write-EnvFile([string[]]$lines) {
  # UTF-8 without BOM and LF line endings, so Docker Compose reads it cleanly.
  [System.IO.File]::WriteAllText($EnvFile, (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
}
function Set-EnvValue([string]$key, [string]$value) {
  $lines = @([System.IO.File]::ReadAllText($EnvFile).TrimEnd("`r", "`n") -split "`r?`n")
  $found = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -like "$key=*") { $lines[$i] = "$key=$value"; $found = $true }
  }
  if (-not $found) { $lines += "$key=$value" }
  Write-EnvFile $lines
}
function Get-EnvValue([string]$key) {
  foreach ($l in ([System.IO.File]::ReadAllText($EnvFile) -split "`r?`n")) {
    if ($l -like "$key=*") { return $l.Substring($key.Length + 1) }
  }
  return ''
}
function Get-IanaTimeZone {
  try {
    $tz = [System.TimeZoneInfo]::Local
    if ($tz.Id -match '/') { return $tz.Id }   # Linux / macOS PowerShell 7
    $iana = $null
    if ([System.TimeZoneInfo]::TryConvertWindowsIdToIanaId($tz.Id, [ref]$iana)) { return $iana }  # .NET 6+
  } catch {}
  return 'UTC'
}

# Docker Compose v2 ("docker compose") or the older "docker-compose".
$script:DC = @('docker', 'compose')
function Invoke-DC {
  $exe = $script:DC[0]; $pre = @($script:DC | Select-Object -Skip 1)
  & $exe @pre @args
}

# ---------------------------------------------------------------- 1. Docker
Say '1/5 Checking Docker'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Die 'Docker is not installed. Install Docker Desktop, then run this script again. See INSTALL.md, step 1.' }
$prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
docker info *> $null; $dockerOk = ($LASTEXITCODE -eq 0)
docker compose version *> $null; $composeV2 = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prev
if (-not $dockerOk) { Die "Docker is installed but not running. Open Docker Desktop, wait until it says 'Engine running', then run this script again." }
if (-not $composeV2) {
  if (Get-Command docker-compose -ErrorAction SilentlyContinue) { $script:DC = @('docker-compose') }
  else { Die 'Docker Compose is missing. Update Docker Desktop.' }
}
Ok (docker --version)
Ok ((Invoke-DC version) | Select-Object -First 1)

# ---------------------------------------------------------------- 2. .env
Say '2/5 Preparing settings (.env)'
foreach ($p in 'docker-compose.yml', '.env.example', 'workflows') {
  if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $p))) { Die 'Run this script from the unzipped kit folder (docker-compose.yml, .env.example and workflows\ must be next to it).' }
}
if (-not (Test-Path -LiteralPath $EnvFile)) {
  $lines = @([System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '.env.example')) -split "`r?`n")
  Write-EnvFile $lines
  Set-EnvValue 'N8N_ENCRYPTION_KEY' (New-RandomHex 32)
  Set-EnvValue 'POSTGRES_PASSWORD' (New-RandomHex 24)
  Set-EnvValue 'TIMEZONE' (Get-IanaTimeZone)
  if ($Postgres) { Set-EnvValue 'COMPOSE_PROFILES' 'postgres'; Set-EnvValue 'DB_TYPE' 'postgresdb' }
  Ok 'Created .env with a random encryption key (keep this file private, and back it up)'
} else {
  Ok 'Keeping your existing .env'
  if ($Postgres -and (Get-EnvValue 'DB_TYPE') -ne 'postgresdb') {
    Warn "-Postgres ignored: this install already uses SQLite. Switching databases does not move your data (see INSTALL.md, 'Use Postgres')."
  }
}
if ([System.IO.File]::ReadAllText($EnvFile) -match '(?m)^[A-Z0-9_]+=REPLACE_WITH_') {
  Set-EnvValue 'N8N_ENCRYPTION_KEY' (New-RandomHex 32); Set-EnvValue 'POSTGRES_PASSWORD' (New-RandomHex 24)
  Warn 'Replaced placeholder values in .env with random ones'
}
if ($Port -gt 0) { Set-EnvValue 'N8N_PORT' "$Port"; Set-EnvValue 'WEBHOOK_URL' "http://localhost:$Port/" }
$P = Get-EnvValue 'N8N_PORT'; if (-not $P) { $P = '5678' }
$Url = "http://localhost:$P"
$db = if ((Get-EnvValue 'DB_TYPE') -eq 'postgresdb') { 'Postgres' } else { 'SQLite' }
Ok "Database: $db - Time zone: $(Get-EnvValue 'TIMEZONE') - Address: $Url"

# ---------------------------------------------------------------- 3. Start
Say '3/5 Starting n8n (the first start downloads about 1 GB, allow a few minutes)'
$ErrorActionPreference = 'Continue'
Invoke-DC up -d
$upOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = 'Stop'
if (-not $upOk) { Die "n8n did not start. If the message says 'port is already allocated', run .\setup.ps1 -Port 5679. Otherwise see INSTALL.md, Troubleshooting." }

Say '4/5 Waiting for n8n to be ready'
$ready = $false
for ($i = 0; $i -lt 90; $i++) {
  try {
    $r = Invoke-WebRequest -Uri "$Url/healthz/readiness" -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -eq 200) { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 2
}
if (-not $ready) { Die "n8n did not answer on $Url within 3 minutes. Check: docker compose logs --tail 50 n8n" }
$ver = (Invoke-DC exec -T n8n n8n --version 2>$null) | Select-Object -Last 1
Ok "n8n is up at $Url ($ver)"

# ---------------------------------------------------------------- 4. Import
Say '5/5 Importing the 3 workflows with the n8n CLI'
$ErrorActionPreference = 'Continue'
$existing = @(Invoke-DC exec -T n8n n8n list:workflow 2>$null)
$imported = 0; $skipped = 0
foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'workflows') -Filter '*.json' | Sort-Object Name)) {
  $name = (Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).name
  if ($name -and ($existing | Where-Object { $_ -like "*|$name" })) { Ok "Already there: $name"; $skipped++; continue }
  Invoke-DC exec -T n8n n8n import:workflow "--input=/import/workflows/$($f.Name)" *> $null
  if ($LASTEXITCODE -ne 0) { Die "Import failed for $($f.Name). Details: docker compose exec n8n n8n import:workflow --input=/import/workflows/$($f.Name)" }
  Ok "Imported: $name"; $imported++
}
$total = @(Invoke-DC exec -T n8n n8n list:workflow 2>$null | Where-Object { $_ -like '*|*' }).Count
$ErrorActionPreference = 'Stop'
Ok "$imported imported, $skipped already present, $total workflow(s) in n8n"

$dcName = $script:DC -join ' '
Write-Host ""
Write-Host "All set. n8n is running at $Url" -ForegroundColor Green
@"

Next steps
  1. Open $Url in your browser and create the owner account.
     This account lives only in your own n8n; nothing is sent to Nyyo Automation.
  2. Open Overview > Workflows. You will see the 3 templates (inactive).
  3. Open one, read the yellow sticky note, fill in the Config node.
  4. Connect your accounts (Google Sheets, Slack, OpenAI, email): docs\INSTALL.md, step 4.
  5. Test with the fictional data in test-data\, then publish (activate) the workflow.

Everyday commands (in this folder)
  Stop:   $dcName stop          Start again: $dcName up -d
  Logs:   $dcName logs -f n8n   Update n8n:  change N8N_VERSION in .env, then $dcName up -d
Keep .env private and back it up: it holds the key that protects your saved credentials.
Help: INSTALL.md (Troubleshooting) - LaborX (https://laborx.com/freelancers/users/id475124)
"@ | Write-Host
