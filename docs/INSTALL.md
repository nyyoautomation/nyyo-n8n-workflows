# Step-by-step install guide

This guide assumes you are new to n8n. Allow about 15 to 30 minutes per template, most of it spent creating credentials.

## 0. Before you start
- An n8n instance: n8n Cloud or self-hosted. The templates were tested on self-hosted n8n 2.43.8. Use a recent version.
- The JSON file of the template you want, from the `workflows/` folder.
- A Google account (all three templates log to Google Sheets).

## 1. Import the workflow
1. In n8n, open **Workflows** and create a new, empty workflow.
2. Click the **⋯** menu (top right) and choose **Import from File**. Select the JSON file.
3. Read the **yellow sticky note** on the left. It holds the full description and setup steps.
4. Save the workflow. Do not activate it yet.

## 2. Prepare the Google Sheet
1. Create a new Google Sheet.
2. Rename the first tab to the name used in the **Config** node (`Leads`, `Invoices` or `Support log`).
3. Paste the header row from `sheet-headers/` into row 1, one column per header.
4. Copy the spreadsheet ID from the URL: it is the long string between `/d/` and `/edit`.

## 3. Fill in the Config node
Open the **Config** node and replace every placeholder (`REPLACE_WITH_...`, `Your Company`, `support@example.com`). All other nodes read from this node, so it is the only place you need to edit.

## 4. Create the credentials
Open each node with a warning icon, choose **Create new credential** and follow the steps for that service.

### Google Sheets (all templates)
- **n8n Cloud:** click **Sign in with Google** and allow access.
- **Self-hosted:** in Google Cloud Console, create a project, enable the **Google Sheets API**, create an **OAuth client ID** (web application) and add the **OAuth Redirect URL** shown in the n8n credential dialog. Paste the client ID and secret into n8n, then click **Sign in with Google**.

### Slack (templates 01 and 03)
1. Go to api.slack.com/apps, choose **Create New App**, then **From scratch**.
2. Under **OAuth & Permissions**, add the bot scope `chat:write`. Add `chat:write.public` too if you want to post without inviting the bot.
3. Install the app to your workspace and copy the **Bot User OAuth Token** (starts with `xoxb-`).
4. In n8n, create a **Slack API** credential with this token.
5. In Slack, invite the bot to the channel from the Config node: `/invite @your-app-name`.

### OpenAI (template 01)
1. Create an API key in your OpenAI account and make sure billing is set up. Usage is billed by OpenAI to you.
2. In n8n, open **OpenAI Chat Model** and create an **OpenAI** credential with the key.
3. To use another provider, delete **OpenAI Chat Model** and connect another chat model node (Anthropic, Google Gemini, Ollama...) to the **Model** input of **Draft reply with AI**.

### IMAP (templates 02 and 03)
Use a mailbox dedicated to invoices or support if you can. The trigger marks processed emails as read.
- **Gmail:** turn on 2-Step Verification, create an **app password**, then use host `imap.gmail.com`, port `993`, SSL/TLS on, user = your address, password = the app password.
- **Other providers:** use the IMAP host and port from your provider's help page. Some business accounts (for example Microsoft 365) block password-based IMAP; ask your admin.

### SMTP (template 03)
- **Gmail:** host `smtp.gmail.com`, port `465`, SSL/TLS on, same app password.
- The sender address in **Config → ackFromEmail** must be an address your SMTP account is allowed to send from.

## 5. Test before you activate
### Template 01: website form leads
1. Open **Receive form lead** and copy the **Test URL**. Click **Listen for test event**.
2. Run `N8N_WEBHOOK_URL="<test URL>" sh test-data/01_sample_leads.sh`, or post your own form.
3. Check the new row in the sheet and the Slack message. The invalid and spam samples should get a `422` response.
4. Activate the workflow and paste the **Production URL** into your form tool (POST, JSON or form-encoded). Field names: `name`, `email`, `company`, `message`, `source`, plus a hidden empty field `website_hp` as a spam trap.

### Template 02: invoice PDFs
1. Email yourself one of the fictional PDFs from `test-data/` (or run `test-data/send_test_emails.py` against a test mailbox).
2. Click **Execute workflow**. The trigger fetches unread emails.
3. Check the rows in the `Invoices` tab. Rows with a missing field show `needs review`.
4. Activate the workflow. n8n then polls the mailbox automatically.

### Template 03: support inbox triage
1. Send yourself one urgent and one normal test email (or use `test-data/send_test_emails.py`).
2. Click **Execute workflow**. The urgent email should reach Slack, the normal one should get an acknowledgement, and both should be logged.
3. Tune `urgentKeywords` and `urgencyThreshold` in **Config**, then activate.

## 6. Troubleshooting
| Symptom | Fix |
|---|---|
| Google Sheets: "Sheet with name ... not found" | The tab name must match `sheetName` in Config exactly. |
| Columns end up in new columns | Row 1 must contain the exact header names from `sheet-headers/`. |
| Slack: `not_in_channel` | Invite the bot to the channel or add the `chat:write.public` scope. |
| Slack: `channel_not_found` | Use the channel name with `#`, or the channel ID. |
| IMAP: authentication failed | Use an app password, check host, port and SSL settings. |
| Template 02: total or vendor empty | The PDF may be scanned (no text layer) or use an unusual label. Add your supplier's pattern in **Parse invoice fields**. |
| Template 03 replies to robots | Add the sender to the patterns in **Score urgency** (`isAutomated`). |

## Support
Nyyo Automation · Remote · Worldwide · LaborX (https://laborx.com/freelancers/users/id475124)
