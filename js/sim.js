const STEPS = [
  { id: "webhook", title: "1. Webhook receives lead", ms: 400,
    out: (f) => ({ event: "lead.created", email: f.email, company: f.company, budget: f.budget, source: "landing" }) },
  { id: "normalize", title: "2. Normalize fields", ms: 500,
    out: (f) => ({ email: String(f.email||"").trim().toLowerCase(), company: String(f.company||"").trim(), budget_usd: Number(f.budget)||0, score: (Number(f.budget)||0) >= 200 ? "hot" : "warm" }) },
  { id: "sheet", title: "3. Append to CRM sheet", ms: 600,
    out: (p) => ({ sheet: "Leads", row: 128, written: p }) },
  { id: "ai", title: "4. Draft AI reply", ms: 700,
    out: (p) => ({ reply: `Hi ${p.written.company || "there"}, thanks for reaching out — we can scope a fixed-price automation this week. — Nyyo Automation` }) },
  { id: "slack", title: "5. Slack #sales alert", ms: 500,
    out: (p, prev) => ({ channel: "#sales", text: `🔥 New lead ${prev.email} (${prev.company}) budget $${prev.budget_usd} · score ${prev.score}` }) },
];

function el(id){ return document.getElementById(id); }

function renderFlow(active) {
  const flow = el("flow");
  flow.innerHTML = STEPS.map((s,i) => {
    const cls = i < active ? "done" : i === active ? "active" : "";
    return `<div class="step ${cls}"><span class="dot"></span><span>${s.title}</span></div>`;
  }).join('<div class="arrow">→</div>');
}

async function runSim() {
  const f = {
    email: el("email").value.trim() || "founder@demo.co",
    company: el("company").value.trim() || "Demo Co",
    budget: el("budget").value.trim() || "250",
  };
  el("run").disabled = true;
  el("log").innerHTML = "";
  let prev = f;
  for (let i = 0; i < STEPS.length; i++) {
    renderFlow(i);
    const s = STEPS[i];
    await new Promise(r => setTimeout(r, s.ms));
    const out = s.out(prev, prev);
    prev = { ...prev, ...out, ...(out.written || {}) };
    const block = document.createElement("div");
    block.className = "log-item";
    block.innerHTML = `<strong>${s.title}</strong><pre>${JSON.stringify(out, null, 2)}</pre>`;
    el("log").appendChild(block);
    el("log").scrollTop = el("log").scrollHeight;
  }
  renderFlow(STEPS.length);
  el("run").disabled = false;
}

document.addEventListener("DOMContentLoaded", () => {
  renderFlow(-1);
  el("run").addEventListener("click", runSim);
});
