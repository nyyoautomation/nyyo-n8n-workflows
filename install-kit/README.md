# Install kit (free)

Everything needed to run the three templates on your own n8n, included free with every package.

**One command** (needs Docker Desktop or Docker Engine):
- Mac / Linux: `./setup.sh` (options: `--postgres`, `--port 5679`)
- Windows: `powershell -ExecutionPolicy Bypass -File .\setup.ps1` (options: `-Postgres`, `-Port 5679`)

It creates `.env` from `.env.example` with a random encryption key, starts n8n (persistent volume, optional Postgres),
imports the 3 workflows with the n8n CLI and prints the next steps. Safe to run again.

| File | Contents |
|---|---|
| `INSTALL.md` | Beginner guide, Mac first, with troubleshooting |
| `docker-compose.yml`, `.env.example` | Self-hosted n8n stack (placeholders only, no credentials) |
| `setup.sh`, `setup.ps1` | One-command setup for Mac/Linux and Windows |
| `workflows/` | Three importable n8n JSON files (no credentials, placeholders only) |
| `docs/INSTALL.md` | Per-template setup: Config node and credentials (Google Sheets, Slack, OpenAI, IMAP, SMTP) |
| `docs/TESTING.md`, `docs/kit-test-proof/` | Test report and raw test output |
| `docs/screenshots/`, `docs/demo.gif` | Canvas and successful executions |
| `sheet-headers/` | Header rows for Google Sheets |
| `test-data/` | Fictional test data and scripts |
| `LICENSE` | MIT |

Already running n8n? Import the files in `workflows/` with **Workflows → ⋯ → Import from File**, then follow `docs/INSTALL.md`.

Contact: LaborX (https://laborx.com/freelancers/users/id475124)
