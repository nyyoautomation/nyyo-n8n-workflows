# One-command install: n8n + the 3 templates (Mac, Windows, Linux)

This kit runs **n8n on your own computer** with Docker and imports the three Nyyo Automation templates for you.
You don't need to know Docker or the command line: copy and paste the commands below.

- **Time needed:** about 10 minutes the first time (most of it is the n8n download, about 1 GB).
- **Cost:** free. n8n self-hosted is free to use for your own workflows under its Sustainable Use License.
- **No account with us:** nothing is sent to Nyyo Automation. Your n8n, your data, your credentials.
- **No credentials in the kit:** you connect your own Google, Slack, OpenAI and email accounts in n8n afterwards.

> What you get at the end: n8n running at http://localhost:5678 with the 3 templates already imported (inactive),
> ready for you to connect your accounts. Then follow [docs/INSTALL.md](docs/INSTALL.md) for each template.

---

## Step 1. Install Docker Desktop

### Mac
1. Go to https://www.docker.com/products/docker-desktop/ and download **Docker Desktop for Mac**.
   Pick **Apple chip** for M1/M2/M3/M4 Macs, **Intel chip** for older ones (Apple menu > About This Mac tells you which).
2. Open the downloaded `.dmg` and drag **Docker** into **Applications**.
3. Open **Docker** from Applications. Accept the terms. You can skip sign-in: no Docker account is needed.
4. Wait until the whale icon in the menu bar stops moving and Docker Desktop shows **Engine running**.

### Windows 10/11
1. Download **Docker Desktop for Windows** from the same page and run the installer. Keep **Use WSL 2** ticked.
2. Restart Windows if asked. Open **Docker Desktop** and wait for **Engine running**. Sign-in is optional; skip it.

### Linux (Ubuntu / Debian)
Install Docker Engine and the Compose plugin following https://docs.docker.com/engine/install/ , then:
```bash
sudo usermod -aG docker "$USER"   # lets you run docker without sudo; log out and back in afterwards
docker compose version            # should print "Docker Compose version v2..."
```

## Step 2. Unzip the kit and open a terminal in its folder

1. Unzip `nyyo-n8n-workflows-install-kit.zip`. You get a folder `nyyo-n8n-workflow-templates`.
2. Open a terminal in that folder:
   - **Mac:** open **Terminal** (Cmd + Space, type `Terminal`, Enter). Type `cd ` (with a space at the end),
     drag the `nyyo-n8n-workflow-templates` folder into the Terminal window, then press Enter.
   - **Windows:** open the folder in File Explorer, click the address bar, type `powershell` and press Enter.
   - **Linux:** right-click in the folder and choose **Open in Terminal**, or `cd` into it.

## Step 3. Run the setup command

**Mac / Linux**
```bash
./setup.sh
```
If you see `permission denied`, run `bash setup.sh` instead.

**Windows (PowerShell)**
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

The script does five things and tells you each one as it goes:
1. checks that Docker is installed and running;
2. creates a private settings file `.env` with a random encryption key (from `.env.example`, which holds placeholders only);
3. starts n8n with Docker Compose (data is kept in a Docker volume, so it survives restarts and updates);
4. waits until n8n is ready;
5. imports the 3 workflows with n8n's own command-line tool, then prints the next steps.

It is safe to run again: it keeps your `.env` and skips workflows that are already imported.

**Options**
| Option (Mac/Linux · Windows) | What it does |
|---|---|
| `./setup.sh --postgres` · `.\setup.ps1 -Postgres` | Uses a Postgres database instead of SQLite. Choose it on the **first** run. Recommended if several people use this n8n or you expect many executions. |
| `./setup.sh --port 5679` · `.\setup.ps1 -Port 5679` | Uses another port if 5678 is already taken. n8n then opens at http://localhost:5679 |

## Step 4. Open n8n and create your owner account

1. Open **http://localhost:5678** in your browser.
2. Fill in the **Set up owner account** form. This account exists only inside your own n8n.
   Use a strong password; you will need it each time you log in.
3. You can skip the optional questions and the offer of a free licence key.
4. Open **Overview > Workflows**: the three templates are there, inactive.

## Step 5. Connect your accounts and test

For each template you want to use:
1. Open it and read the **yellow sticky note** on the canvas.
2. Fill in the **Config** node (sheet ID, Slack channel, company name...).
3. Create the credentials it needs: see [docs/INSTALL.md](docs/INSTALL.md), step 4 (Google Sheets, Slack, OpenAI, IMAP, SMTP).
4. Test with the fictional data in `test-data/` ([docs/INSTALL.md](docs/INSTALL.md), step 5), then switch the workflow to **Active** (Publish).

> **Webhooks from the internet (template 01).** On a laptop, `http://localhost:5678` is reachable only from that computer,
> which is fine for testing with `test-data/01_sample_leads.sh`. For a real website form, n8n must be reachable from the internet:
> run this kit on a server with a domain and HTTPS, and set `WEBHOOK_URL` in `.env` to that address (for example `https://n8n.your-domain.com/`).
> Nyyo Automation can set this up for you as part of a paid package.

---

## Everyday use

Run these in the kit folder:

| Task | Command |
|---|---|
| Stop n8n | `docker compose stop` |
| Start n8n again | `docker compose up -d` (or simply open Docker Desktop: the stack restarts automatically) |
| See what n8n is doing | `docker compose logs -f n8n` (Ctrl + C to leave) |
| Update n8n | Change `N8N_VERSION` in `.env` (see the n8n release notes first), then `docker compose pull && docker compose up -d` |
| Back up | Keep a copy of `.env`. Export your workflows: `docker compose exec n8n n8n export:workflow --all --output=/home/node/.n8n/backup.json`, then `docker compose cp n8n:/home/node/.n8n/backup.json ./backup.json` |
| Remove everything | `docker compose down -v` **deletes your workflows, executions and saved credentials.** Back up first. |

**Keep `.env` private.** It holds `N8N_ENCRYPTION_KEY`, which encrypts the credentials you save in n8n.
If you lose it, n8n can no longer read those credentials. Never send it to anyone, including us.

### Use Postgres
Run `./setup.sh --postgres` (Windows: `.\setup.ps1 -Postgres`) on a **fresh** install. It sets `COMPOSE_PROFILES=postgres`
and `DB_TYPE=postgresdb` in `.env` and starts a Postgres 16 container next to n8n (not exposed outside Docker).
Switching an existing SQLite install to Postgres does not move your data: export your workflows and credentials first
(`n8n export:workflow --all`, `n8n export:credentials --all`), then reinstall and import them.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Docker is not installed` or `docker: command not found` | Install Docker Desktop (step 1), then **open a new terminal window**. |
| `Docker is installed but not running` / `Cannot connect to the Docker daemon` | Open Docker Desktop and wait for **Engine running**. On Linux: `sudo systemctl start docker`. |
| `permission denied` when running `./setup.sh` | Run `bash setup.sh`, or once `chmod +x setup.sh`. |
| Windows: `running scripts is disabled on this system` | Use `powershell -ExecutionPolicy Bypass -File .\setup.ps1`, or once `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. |
| `port is already allocated` / `address already in use` | Another program uses port 5678 (often another n8n). Run `./setup.sh --port 5679`. |
| `n8n did not answer ... within 3 minutes` | Run `docker compose logs --tail 50 n8n`. On slow connections the first download can take longer: run the script again. |
| Linux: `permission denied ... docker.sock` | Run `sudo usermod -aG docker "$USER"`, log out and back in. |
| `N8N_ENCRYPTION_KEY is missing` | You ran `docker compose` before the setup script. Run `./setup.sh` once. |
| Mac: `unknown shorthand flag: 'd'` or `docker compose` not found | Update Docker Desktop. On older installs the script falls back to `docker-compose` automatically. |
| The browser shows a "secure cookie" warning | Open n8n at `http://localhost:5678` exactly (not the computer's IP address). For LAN or server use, set up HTTPS. |
| Workflows are missing in n8n | Run the setup script again: it imports only what is missing. Or import by hand: **Workflows > ⋯ > Import from File** with the files in `workflows/`. |
| Credentials stopped working after reinstalling | The new install has a new `.env` key. Restore your old `.env` before starting, or re-create the credentials. |
| Mac with Apple chip: very slow first start | Normal: Docker downloads the ARM image and n8n runs its database setup once. Later starts take a few seconds. |
| Template-specific errors (Sheets, Slack, IMAP) | See the troubleshooting table in [docs/INSTALL.md](docs/INSTALL.md). |

Still stuck? Ask in your order chat and paste the output of `docker compose logs --tail 100 n8n`
(it contains no passwords, but check before sending).

---
Nyyo Automation · Remote · Worldwide · Questions? Ask in your order chat. · Kit licence: MIT (see LICENSE). n8n itself is licensed by n8n GmbH under its own terms.
