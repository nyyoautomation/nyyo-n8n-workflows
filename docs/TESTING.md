# Test report

All three templates were imported into a fresh **self-hosted n8n 2.43.8** (Docker) and executed end to end with **fictional data only**.

## Test setup
- **Triggers ran for real:** the webhook of template 01 was called with `curl`, and the IMAP triggers of templates 02 and 03 polled a local test mail server (GreenMail) that received real emails with real PDF attachments.
- **SMTP ran for real:** the acknowledgement email of template 03 was delivered to the test mail server and read back.
- **Third-party APIs were mocked:** Google Sheets, Slack and OpenAI were answered by a local mock server that records each request. The unmodified n8n nodes made their normal API calls; only the network endpoint was local. No real Google, Slack or OpenAI account was used, so the AI reply in the test is a canned mock response.
- The exact JSON files in `workflows/` were imported. Only test credentials were attached.

## Results
| Template | Scenario | Result |
|---|---|---|
| 01 | Valid lead (JSON) | HTTP 200; AI draft created; row appended to `Leads`; Slack message posted |
| 01 | Missing name, bad email, empty message | HTTP 422 with the list of errors; nothing logged |
| 01 | Honeypot field filled (form-encoded) | HTTP 422 "rejected as spam"; nothing logged |
| 02 | 3 emails: a US-format invoice, a European-format invoice (`2.856,00 EUR`), a receipt without a total, plus a non-PDF attachment | 3 rows appended. Totals 1242 USD and 2856 EUR, ISO dates, third row flagged `needs review (missing: total)`, `.txt` file skipped |
| 03 | 4 emails: urgent, normal, `no-reply` sender, auto-reply | Urgent one posted to Slack (score 7), normal one acknowledged by email, 2 automated ones filtered out, 2 rows logged |

Every execution finished with status **success**. See `docs/screenshots/` for the canvas, the execution view and a node output for each template.

## One-command install kit (from scratch)
Tested on Oct 19, 2026, on Linux with Docker Engine 26.1 and Compose 2.26, n8n 2.43.8. Raw output: [`kit-test-proof/`](kit-test-proof/).

1. **Scratch:** the shipped ZIP was unzipped into an empty folder. No n8n container, volume or `.env` existed.
2. **`./setup.sh`:** it created `.env` (random key), started n8n, waited for readiness and imported the 3 workflows with `n8n import:workflow`. `n8n list:workflow` then listed all 3.
3. **Re-run:** `./setup.sh` again kept `.env` and reported `0 imported, 3 already present`, with no duplicates.
4. **Owner view:** an owner account was created through n8n's normal first-run endpoint. The owner sees the 3 workflows, inactive.
5. **Execution with fictional data:** test-only credentials pointing to the local mock (Sheets, Slack, OpenAI) were attached to template 01. The template was published and its **production** webhook was called:
   - valid lead: HTTP 200, execution `success`, all 10 nodes ran (AI draft, Sheets row, Slack message);
   - invalid lead and honeypot: HTTP 422, execution `success` on the reject branch.
6. **Also tested:** `setup.ps1` with PowerShell 7.4 (on Linux) using `-Postgres`. Postgres 16 started, n8n migrated, the 3 workflows were imported into Postgres, and a re-run skipped them.

Not tested: Docker Desktop on a real Mac or Windows PC, and Windows PowerShell 5.1.

## Run the tests yourself
- Template 01: `sh test-data/01_sample_leads.sh` (set `N8N_WEBHOOK_URL` to your production webhook URL).
- Templates 02 and 03: point the IMAP credential to a **test** mailbox and run `python3 test-data/send_test_emails.py` (see the file header for the variables).
