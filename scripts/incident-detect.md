# Incident Detection

> Parse alerts and create incident files for the Crisis Command Center.

## Creating an Incident

When an alert fires, create a Markdown file in `incidents/active/`:

```bash
INCIDENT_ID="INC-$(date +%Y%m%d-%H%M)"
cat > "incidents/active/${INCIDENT_ID}.md" << 'EOF'
# INC-20260415-1459 — Node NotReady

**Cluster:** prod-cluster
**Severity:** P1
**Detected:** 2026-04-15 09:29:44 UTC
**Status:** ACTIVE

---

## Alert Details

**Type:** Node NotReady
**Cluster:** prod-cluster
**Nodes Affected:** node-worker-03, node-worker-05, node-worker-06
**Description:** 3 worker nodes showing NotReady with DiskPressure=True

---

## Context

### Similar Incidents
[Run similar-incidents search]

### Decision Support
[Run decision-support analysis]

### Precedent Decisions
[Query context graph]

---

## Actions

[Log actions taken here]

---

## Resolution

[Fill in when resolved]
EOF
```

## Azure Monitor Webhook

Configure Azure Monitor Action Group to call a webhook endpoint that creates the incident file:

### Alert Payload Format

```json
{
  "alertType": "Kubernetes Node NotReady",
  "cluster": "prod-cluster",
  "severity": "P1",
  "nodes": ["node-worker-03", "node-worker-05", "node-worker-06"],
  "description": "3 worker nodes showing NotReady with DiskPressure=True",
  "timestamp": "2026-04-15T09:29:44Z"
}
```

### Webhook Receiver

```bash
# Simple webhook receiver (requires netcat)
while true; do
  nc -l -p 8092 > /tmp/alert.json
  ALERT_TYPE=$(jq -r '.alertType' /tmp/alert.json)
  CLUSTER=$(jq -r '.cluster' /tmp/alert.json)
  SEVERITY=$(jq -r '.severity' /tmp/alert.json)
  NODES=$(jq -r '.nodes | join(",")' /tmp/alert.json)
  DESCRIPTION=$(jq -r '.description' /tmp/alert.json)

  INCIDENT_ID="INC-$(date +%Y%m%d-%H%M)"
  # ... create incident file using variables above
done
```

## Severity Levels

| Level | Response Time | Example |
|-------|--------------|---------|
| P1 | <5 min | Production down, customer-facing |
| P2 | <15 min | Partial outage, degraded service |
| P3 | <1 hour | Non-critical, internal only |
| P4 | Next business day | Low impact, cosmetic |

## Manual Incident Creation

For incidents detected manually (Slack, phone call, etc.):

1. Create the file with `Status: ACTIVE`
2. Fill in alert details
3. Run similar-incidents search
4. Run decision-support analysis
5. Launch dashboard
