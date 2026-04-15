# Launch Dashboard

> Interactive terminal dashboard for incident response.

## Quick Start

```bash
# Open incident file directly
less incidents/active/INC-20260415-1459.md

# Or view with a pager
cat incidents/active/INC-20260415-1459.md | less

# Edit the incident file
nano incidents/active/INC-20260415-1459.md
```

## Dashboard Layout

The dashboard is a Markdown document that you keep open in your editor or pager:

```
┌─────────────────────────────────────────────────────────────────────┐
│  CRISIS COMMAND CENTER                                              │
│  ┌──────────────────────┬──────────────────────────────────────┐   │
│  │  🚨 Current Incident │  🔍 Similar Incidents                │   │
│  │  ──────────────────  │  ───────────────────────────────────  │   │
│  │  Alert: Node NotReady│  1. INC-001 (92% match)              │   │
│  │  Cluster: prod       │     • Disk pressure → cleanup ✅     │   │
│  │  Nodes: 3/8 down     │     • DEC-001: Skip runtime restart  │   │
│  │  Duration: 2 min     │  2. INC-004 (76% match)              │   │
│  │                      │     • Runtime restart → 45 min ❌     │   │
│  └──────────────────────┴──────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  🧠 DECISION SUPPORT                                         │ │
│  │  💡 Skip container runtime restart                           │ │
│  │     Precedent: DEC-001 — saved 33 minutes                    │ │
│  │     Risk: LOW | Confidence: HIGH                              │ │
│  │  ⚠️ Runbook step 2 CONFLICT — precedent overrides runbook    │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  ⌨️  COMMANDS                                                │ │
│  │  kubectl get nodes                                           │ │
│  │  kubectl describe node node-worker-03                        │ │
│  │  ssh node-worker-03 "df -h /var/lib/kubelet"                 │ │
│  │  crictl rmi --prune                                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Multi-Pane Terminal Setup

Use `tmux` or terminal splits for the full experience:

### tmux Layout

```bash
# Create a 4-pane layout
tmux new-session -s incident -d
tmux split-window -v -t incident
tmux split-window -h -t incident:0.0
tmux split-window -h -t incident:0.2

# Pane 0: Incident dashboard
tmux send-keys -t incident:0.0 'cat incidents/active/INC-*.md | less' Enter

# Pane 1: kubectl terminal
tmux send-keys -t incident:0.1 'kubectl get nodes -w' Enter

# Pane 2: Logs
tmux send-keys -t incident:0.2 'kubectl logs -f -l app=payment-api --tail=100' Enter

# Pane 3: Actions
tmux send-keys -t incident:0.3 'bash' Enter

# Attach
tmux attach -t incident
```

### Terminal Split (No tmux)

```
┌─────────────────────────────────────┐
│ Terminal 1: Dashboard               │
│ cat incidents/active/INC-*.md       │
├──────────────────┬──────────────────┤
│ Terminal 2:      │ Terminal 3:      │
│ kubectl get -w   │ kubectl logs -f  │
└──────────────────┴──────────────────┘
```

## Actions During Incident

### Investigation Commands

```bash
# Check node status
kubectl get nodes -o wide

# Describe affected node
kubectl describe node node-worker-03

# Check disk usage
ssh node-worker-03 "df -h /var/lib/kubelet"

# Check pod status on affected nodes
kubectl get pods --all-namespaces -o wide | grep "node-worker-03"

# Check events
kubectl get events --sort-by='.lastTimestamp' --field-selector involvedObject.name=node-worker-03
```

### Remediation Commands

```bash
# Clean container images
ssh node-worker-03 "crictl rmi --prune"

# Clean logs
ssh node-worker-03 "journalctl --vacuum-time=2d"

# Verify recovery
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running
```

### Logging Actions

Update the incident file in real-time:

```markdown
## Actions

- 14:25 — Acknowledged page, started investigation
- 14:26 — kubectl get nodes: 3 NotReady (node-worker-03, -05, -06)
- 14:27 — Checked similar incidents: INC-001 (92% match)
- 14:28 — DECISION: Skip runtime restart (precedent DEC-001)
- 14:29 — Running crictl rmi --prune on all 3 nodes
- 14:33 — All nodes recovered. Error rate normalized.
- 14:35 — Incident resolved.
```

## Post-Incident

1. Update incident file: `Status: RESOLVED`
2. Fill in Resolution section
3. Generate incident replay (copy to Incident Replay Engine)
4. Update context graph with new decision traces
