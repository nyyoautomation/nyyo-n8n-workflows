#!/usr/bin/env sh
# Send fictional test leads to template 01.
# Usage: N8N_WEBHOOK_URL="https://YOUR-N8N-HOST/webhook/lead-intake" sh 01_sample_leads.sh
URL="${N8N_WEBHOOK_URL:-http://localhost:5678/webhook/lead-intake}"
echo "Valid lead (expect 200):"
curl -s -X POST "$URL" -H 'content-type: application/json' \
  -d '{"name":"Jordan Avery","email":"jordan.avery@example.org","company":"Brightline Studio (fictional)","message":"Hi, we need a new booking flow for our 3 studios. Can you help?","source":"pricing-page"}'; echo
echo "Invalid lead (expect 422):"
curl -s -X POST "$URL" -H 'content-type: application/json' -d '{"name":"","email":"not-an-email","message":""}'; echo
echo "Honeypot spam, form-encoded (expect 422):"
curl -s -X POST "$URL" -d 'name=Bot&email=bot@example.net&message=buy+now&website_hp=http://spam.example'; echo
