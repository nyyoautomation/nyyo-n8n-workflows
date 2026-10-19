# n8n workflow templates by Nyyo Automation

Three free, ready-to-import n8n workflows for everyday small-business jobs. Each one is built only with built-in n8n nodes, has a setup sticky note on the canvas, keeps every setting in one **Config** node and contains **no credentials**.

![Canvas and successful executions](docs/demo.gif)

| # | Template | Nodes used | AI key needed |
|---|---|---|---|
| 01 | [Send website form leads to Google Sheets and Slack with an AI-drafted reply](workflows/01_lead_to_sheets_slack_ai.json) | Webhook, Code, If, Basic LLM Chain + OpenAI Chat Model, Google Sheets, Slack, Respond to Webhook | Yes (OpenAI, or swap the model) |
| 02 | [Extract invoice data from email PDF attachments into Google Sheets](workflows/02_invoice_email_pdf_to_sheets.json) | Email Trigger (IMAP), Code, Extract from File, Google Sheets | No |
| 03 | [Triage support emails from IMAP, alert Slack on urgent ones and auto-acknowledge the rest](workflows/03_support_inbox_triage_slack.json) | Email Trigger (IMAP), Code, Filter, If, Slack, Send Email (SMTP), Google Sheets | No |

**Tested on:** n8n 2.43.8, self-hosted (Docker). Not yet tested on n8n Cloud. The one-command kit was tested from scratch on Linux (Docker Engine); see [docs/TESTING.md](docs/TESTING.md).
**Licence:** MIT (see [LICENSE](LICENSE)).

## One-command install (free kit, Docker)
No n8n yet? The kit starts a self-hosted n8n on your computer and imports the 3 templates for you.

1. Install Docker Desktop and download the ZIP from [`dist/`](dist/nyyo-n8n-workflows-install-kit.zip). Unzip it.
2. In a terminal, inside the unzipped folder:
   - Mac / Linux: `./setup.sh` (add `--postgres` to use Postgres instead of SQLite)
   - Windows: `powershell -ExecutionPolicy Bypass -File .\setup.ps1`
3. Open http://localhost:5678, create your owner account: the 3 templates are already there.

Beginner guide with copy-paste steps and troubleshooting: **[INSTALL.md](INSTALL.md)** (Mac first, then Windows and Linux).

## Already have n8n?
1. Download a JSON file from [`workflows/`](workflows/).
2. In n8n: **Workflows → Create → ⋯ → Import from File**.
3. Read the yellow sticky note, fill in the **Config** node, connect your credentials.
4. Follow the per-template guide: **[docs/INSTALL.md](docs/INSTALL.md)**.

## What is in this repo
| Path | Contents |
|---|---|
| `INSTALL.md` | One-command install guide for beginners (Docker, Mac / Windows / Linux) |
| `docker-compose.yml`, `.env.example` | Self-hosted n8n with a persistent volume and optional Postgres (placeholders only) |
| `setup.sh`, `setup.ps1` | One-command setup: start n8n, import the 3 workflows with the n8n CLI, print next steps |
| `workflows/` | The three importable templates (clean exports, no credentials, placeholders only) |
| `docs/INSTALL.md` | Step-by-step install and credential guide |
| `docs/TESTING.md` | How each template and the install kit were tested, with results |
| `docs/kit-test-proof/` | Raw output of the from-scratch install kit test |
| `docs/screenshots/` | Canvas, successful execution and node output for each template |
| `sheet-headers/` | One-line CSV header rows to paste into Google Sheets |
| `test-data/` | Fictional test data: sample leads (curl), 3 invoice PDFs, test email sender |
| `dist/` | ZIP of the whole kit |

## Honest limits
- Template 01 needs an AI provider. The reply is a **draft** for a human to review; nothing is sent to the lead automatically.
- Template 02 reads the **text layer** of PDFs. Scanned images need an OCR step first. Unusual layouts can leave a field empty; those rows are marked `needs review`.
- Template 03 uses keyword rules, not AI. Tune the keywords and threshold to your inbox.

## Contact
Nyyo Automation · Remote · Worldwide · LaborX (https://laborx.com/freelancers/users/id475124)
