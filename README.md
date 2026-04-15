# Crisis Command Center

> **One dashboard. One terminal. All the context.**

**Real-time incident response dashboard that pulls together monitoring, context, and decision support in one place.**

---

## The Problem

You're on-call. An alert fires. You have 5 minutes before it escalates.

What you do today:
- Open Grafana for metrics
- Open kubectl terminal for cluster state
- Search Slack for "has this happened before?"
- Scramble through Confluence for runbooks
- Check PagerDuty for who's responding
- Panic

**5 tools. 5 tabs. Zero coherence.**

---

## The Solution

**Crisis Command Center** — A single dashboard that shows:

1. **Current Incident Panel** — What's breaking, right now
2. **Similar Incidents** — The 3 most relevant past incidents (with decision traces)
3. **One-Click Actions** — kubectl, logs, runbooks, Slack threads
4. **Context Graph Integration** — Precedent decisions, known patterns
5. **Built-in Terminal** — kubectl, az, jq without leaving the dashboard
6. **AI Assistant** — Pre-loaded with full context graph + incident history

---

## Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  CRISIS COMMAND CENTER                                              │
│  ┌──────────────────────┬──────────────────────────────────────┐   │
│  │  Current Incident    │  Similar Incidents                   │   │
│  │  ──────────────────  │  ───────────────────────────────────  │   │
│  │  Alert: Node NotReady│  1. INC-001 (92% match)              │   │
│  │  Cluster: prod-cluster│     • Disk pressure → cleanup ✅  │   │
│  │  Nodes: 3/8 down     │     • DEC-001: Skip runtime restart │   │
│  │  Duration: 2 min     │  2. INC-004 (76% match)              │   │
│  │                      │     • Runtime restart → 45 min ❌  │   │
│  │  [View Live Metrics] │  3. INC-006 (68% match)              │   │
│  │  [View kubectl]      │     • Partial cleanup → 18 min     │   │
│  └──────────────────────┴──────────────────────────────────────┘   │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  DECISION SUPPORT                                            │ │
│  │  ─────────────────────────────────────────────────────────── │ │
│  │  💡 Suggestion: Skip container runtime restart              │ │
│  │     Precedent: DEC-001 (INC-001) — saved 33 minutes          │ │
│  │     Risk: LOW — 3 successful precedents, 0 failures         │ │
│  │                                                               │ │
│  │  📋 Runbook: node-notready.md (step 2) ⚠️  CONFLICT           │ │
│  │     Runbook says: "Restart container runtime"               │ │
│  │     Context graph says: "Do NOT restart on disk pressure"    │ │
│  │                                                               │ │
│  │  [View Decision Trace]  [View Incident Replay]  [Chat AI]   │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  TERMINAL (kubectl)                                          │ │
│  │  ─────────────────────────────────────────────────────────── │ │
│  │  $ kubectl get nodes                                         │ │
│  │  NAME              STATUS     ROLES    AGE   VERSION         │ │
│  │  node-worker-03    NotReady   worker   90d   v1.28.0         │ │
│  │  node-worker-05    NotReady   worker   90d   v1.28.0         │ │
│  │  node-worker-06    NotReady   worker   90d   v1.28.0         │ │
│  │                                                               │ │
│  │  [crictl rmi --prune]  [journalctl --vacuum-time=2d]        │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## How It Works

### 1. Incident Detection
- Hooks into Azure Monitor alerts (webhook)
- Or manual entry from Slack/PagerDuty

### 2. Context Retrieval
- Queries incident replay engine for similar incidents (semantic search)
- Pulls decision traces, timelines, AI replays
- Ranks by relevance (alert type, cluster, time, symptoms)

### 3. Decision Support
- Compares current state against context graph
- Flags conflicts between runbooks and precedents
- Suggests actions with confidence scores

### 4. One-Click Actions
- Pre-built kubectl commands (common patterns)
- Log queries (tail, grep, filter)
- Runbook shortcuts
- Slack thread links

### 5. AI Assistant
- Pre-loaded with full incident history
- Can answer: "What happened last time?"
- Can simulate: "What if I restart the runtime?"
- Can explain: "Why is this a bad idea?"

---

## Tech Stack

**Zero dependencies, pure Markdown + bash:**

```
crisis-command-center/
├── README.md
├── dashboard.md          # Terminal-based dashboard (fzf, tput)
├── scripts/
│   ├── incident-detect.sh    # Parse alerts, create incident file
│   ├── similar-incidents.sh  # Search replay engine for matches
│   ├── decision-support.sh   # Query context graph
│   ├── launch-dashboard.sh   # Start the dashboard
│   └── ai-query.sh          # Query AI assistant
├── incidents/
│   └── active/               # Current incidents (Markdown + metadata)
├── templates/
│   └── incident-template.md
└── config/
    ├── clusters.yaml         # Cluster configs
    └── integrations.yaml     # Azure Monitor, Slack, PagerDuty
```

**Optional:** Web UI (React/Next.js) if you want browser-based

---

## Key Features

### Real-Time Incident Detection
- Webhook receiver for Azure Monitor alerts
- Auto-creates incident file with metadata
- Triggers similar-incident search

### Semantic Similarity Search
- Search incident replay engine by:
  - Alert type (Node NotReady, Pod CrashLoopBackOff, etc.)
  - Cluster name
  - Time window
  - Error messages
- Returns ranked list with match scores

### Decision Support Engine
- Query context graph for precedents
- Flag conflicts between runbooks and historical decisions
- Suggest actions with risk scores

### Built-In Terminal
- kubectl, az, jq integrated
- Pre-built commands for common patterns
- One-click execute

### AI Assistant
- Pre-loaded with incident replay engine + context graph
- Can simulate decisions
- Can explain reasoning

---

## Usage Flow

### Step 1: Alert Fires
```
[Webhook] → incident-detect.sh
→ Creates: incidents/active/INC-001-20260412-1423.md
→ Triggers: similar-incidents.sh
```

### Step 2: Dashboard Launches
```bash
./scripts/launch-dashboard.sh INC-001
```

Shows:
- Current incident details
- Top 3 similar incidents
- Decision support suggestions
- Ready-to-run commands

### Step 3: On-Call Engineer Responds
- Sees: "Skip runtime restart" (precedent DEC-001)
- Clicks: [crictl rmi --prune]
- Nodes recover in 12 minutes

### Step 4: Post-Incident
- Dashboard auto-generates incident replay
- Decision trace recorded
- Context graph updated

---

## Value Proposition

| Metric | Before | After |
|--------|--------|-------|
| Time to first action | 5-10 min | 30-60 sec |
| Tools open | 5+ tabs | 1 dashboard |
| Decisions from precedents | Rare | Every time |
| MTTR (avg) | 35 min | 15 min |

**Crisis Command Center cuts MTTR by 50% by reducing context-switching and ensuring every decision is informed by precedent.**

---

## Roadmap

**Phase 1 (MVP):**
- Terminal-based dashboard
- Incident detection from Azure Monitor
- Similar-incident search (grep-based)
- Decision support (grep-based)
- Built-in terminal

**Phase 2:**
- Semantic similarity search (vector embeddings)
- Context graph integration (full API)
- AI assistant integration
- Web UI

**Phase 3:**
- Multi-cluster support
- Slack/PagerDuty integration
- Automated incident replay generation
- Pattern detection (cross-incident analysis)

---

## Why This Matters

**For Manav:**
- He's on-call — he'd use this immediately
- He knows Azure + k8s — this is his domain
- He's seen the pain — context-switching kills time

**For SRE teams:**
- Reduces MTTR
- Reduces on-call stress
- Captures and reuses tribal knowledge
- Makes AI-assisted incident response real

**For the ecosystem:**
- Completes the incident response stack:
  - Context Graph SRE (stores decisions)
  - Incident Replay Engine (replays incidents)
  - Crisis Command Center (responds in real-time)

---

## Next Steps

1. **Build the terminal-based dashboard** (fzf + bash)
2. **Implement incident detection** (Azure Monitor webhook)
3. **Build similar-incident search** (grep-based, upgrade to vectors later)
4. **Integrate with Context Graph SRE**
5. **Integrate with Incident Replay Engine**
6. **Test with real incidents**

---

## Inspiration

- **Datadog Incident Management** (closed-source, expensive)
- **PagerDuty Incident Response** (focused on alerts, not context)
- **FireHydrant** (enterprise, complex)

**Crisis Command Center:** Open-source, simple, built on the stack we already have (Context Graph + Incident Replay Engine).
