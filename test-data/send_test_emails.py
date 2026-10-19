"""Send fictional test emails to a TEST mailbox for templates 02 and 03.
Use a throwaway mailbox, never a production inbox.
Usage:
  SMTP_HOST=smtp.example.com SMTP_PORT=587 SMTP_USER=you@example.com SMTP_PASS=app-password \
  INVOICE_TO=invoices-test@example.com SUPPORT_TO=support-test@example.com python3 send_test_emails.py
"""
import os, smtplib, ssl
from email.message import EmailMessage
HERE = os.path.dirname(os.path.abspath(__file__))
H, P = os.environ.get("SMTP_HOST", "127.0.0.1"), int(os.environ.get("SMTP_PORT", "3025"))
U, W = os.environ.get("SMTP_USER"), os.environ.get("SMTP_PASS")
FROM = os.environ.get("SMTP_FROM", U or "tester@example.test")
def send(to, subject, body, files=(), headers=None):
    m = EmailMessage(); m["From"], m["To"], m["Subject"] = FROM, to, subject
    for k, v in (headers or {}).items(): m[k] = v
    m.set_content(body)
    for f in files:
        m.add_attachment(open(os.path.join(HERE, f), "rb").read(), maintype="application", subtype="pdf", filename=f)
    with smtplib.SMTP(H, P) as s:
        if U: s.starttls(context=ssl.create_default_context()); s.login(U, W)
        s.send_message(m)
inv = os.environ.get("INVOICE_TO", "invoices@example.test")
sup = os.environ.get("SUPPORT_TO", "support@example.test")
send(inv, "Invoice NW-2026-0412", "Please find our invoice attached.", ["northwind_NW-2026-0412.pdf"])
send(inv, "Your invoice LDS-889", "Invoice attached.", ["lumen_LDS-889.pdf"])
send(inv, "Order QP-55102", "Receipt attached.", ["quickprint_receipt.pdf"])
send(sup, "URGENT: cannot log in since this morning", "Hi, our whole team is locked out and the dashboard is down. Please help asap.")
send(sup, "Question about invoices", "Hello, where can I download last month's invoice? Thanks!")
send(sup, "Automatic reply: Re: onboarding", "I am out of office until Monday.", headers={"Auto-Submitted": "auto-replied"})
print("Sent 3 invoice emails and 3 support emails (fictional).")
