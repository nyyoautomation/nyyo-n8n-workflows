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

## Run the tests yourself
- Template 01: `sh test-data/01_sample_leads.sh` (set `N8N_WEBHOOK_URL` to your production webhook URL).
- Templates 02 and 03: point the IMAP credential to a **test** mailbox and run `python3 test-data/send_test_emails.py` (see the file header for the variables).
