# Decision Support Engine

> Query the context graph for precedents and decision guidance.

## Usage

```bash
# Search context graph for relevant decisions
grep -ril "Node NotReady" /path/to/context-graph/decisions/*.md

# Search by keyword
grep -ril "disk pressure" /path/to/context-graph/decisions/*.md

# Search by outcome
grep -ril "skip.*restart" /path/to/context-graph/decisions/*.md

# Get decision details
cat /path/to/context-graph/decisions/DEC-001.md
```

## Decision Analysis

For each matching decision, extract:

| Field | Where to Find |
|-------|--------------|
| Decision ID | `# DEC-XXX: Title` |
| Risk Level | `risk: HIGH/MEDIUM/LOW` |
| Outcome | `outcome: success/failed/unknown` |
| Precedent | `precedent: INC-XXX` |
| Rationale | `## Why This Decision Was Made` |

### Quick Analysis

```bash
CONTEXT_GRAPH="/path/to/context-graph/decisions"
ALERT_TYPE="Node NotReady"

echo "🧠 Decision Support Analysis"
echo "   Alert: $ALERT_TYPE"
echo ""

for file in "$CONTEXT_GRAPH"/*.md; do
  if grep -qi "$ALERT_TYPE" "$file"; then
    decision=$(grep "^# DEC-" "$file" | head -1)
    risk=$(grep -i "risk:" "$file" | head -1)
    outcome=$(grep -i "outcome:" "$file" | head -1)
    echo "$decision"
    echo "  $risk"
    echo "  $outcome"
    echo ""
  fi
done
```

## Runbook Conflict Detection

Check if the context graph contradicts any runbook steps:

```bash
# Search for documented exceptions to runbooks
grep -ril "exception\|override\|conflict" /path/to/incident-replay-engine/replays/INC-*/decisions.md

# Search for runbook steps that were skipped
grep -ril "skip.*step\|skipped.*runbook" /path/to/incident-replay-engine/replays/INC-*/decisions.md
```

## Decision Confidence

| Precedent Count | Confidence | Guidance |
|----------------|------------|----------|
| 3+ successful | HIGH | Safe to follow precedent |
| 2 successful | MEDIUM | Follow with caution |
| 1 successful | LOW | Use as reference, verify |
| 0 / mixed | UNCERTAIN | Escalate or investigate further |

## Example Output

```
🧠 Decision Support Analysis
   Alert: Node NotReady

DEC-001: Skip runtime restart on disk-pressure nodes
  Risk: LOW
  Outcome: success (12 min MTTR)
  Confidence: HIGH (3 successful precedents: INC-001, INC-006, INC-007)
  Exception: Runbook step 2 overridden

⚠️ RUNBOOK CONFLICT DETECTED:
  Runbook says: "Restart container runtime (step 2)"
  Precedent says: "Do NOT restart on disk-pressure nodes"
  Action: Follow precedent, skip step 2
```

## Updating the Incident File

After analysis, update the active incident:

```markdown
### Decision Support

💡 Suggestion: Skip container runtime restart
   Precedent: DEC-001 (INC-001) — saved 33 minutes
   Risk: LOW — 3 successful precedents, 0 failures
   Confidence: HIGH

📋 Runbook: node-notready.md (step 2) ⚠️ CONFLICT
   Runbook says: "Restart container runtime"
   Precedent says: "Do NOT restart on disk-pressure nodes"
```
