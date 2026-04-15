# Similar Incidents Search

> Search the Incident Replay Engine for similar past incidents.

## Usage

```bash
# Search by alert type
grep -ril "Node NotReady" /path/to/incident-replay-engine/replays/INC-*/summary.md

# Search by cluster
grep -ril "prod-cluster" /path/to/incident-replay-engine/replays/INC-*/summary.md

# Search by keyword
grep -ril "DiskPressure" /path/to/incident-replay-engine/replays/INC-*/summary.md

# Combined search (alert type + cluster)
for dir in /path/to/incident-replay-engine/replays/INC-*/; do
  if grep -q "Node NotReady" "$dir/summary.md" 2>/dev/null && \
     grep -q "prod-cluster" "$dir/summary.md" 2>/dev/null; then
    echo "MATCH: $(basename $dir)"
    grep "^## Key Decision" "$dir/decisions.md" 2>/dev/null
  fi
done
```

## Scoring Similarity

Score each replay on 4 dimensions:

| Criteria | Weight | How to Check |
|----------|--------|-------------|
| Alert type match | 40pts | `grep -qi "$ALERT_TYPE" summary.md` |
| Cluster match | 30pts | `grep -qi "$CLUSTER" summary.md` |
| Timeline keyword match | 20pts | `grep -qi "$ALERT_TYPE" timeline.md` |
| Decision keyword match | 10pts | `grep -qi "$ALERT_TYPE" decisions.md` |

### Quick Score Script

```bash
REPLAY_DIR="/path/to/incident-replay-engine/replays"
ALERT_TYPE="Node NotReady"
CLUSTER="prod-cluster"

for dir in "$REPLAY_DIR"/INC-*/; do
  name=$(basename "$dir")
  score=0

  grep -qi "$ALERT_TYPE" "$dir/summary.md" 2>/dev/null && score=$((score + 40))
  [ -n "$CLUSTER" ] && grep -qi "$CLUSTER" "$dir/summary.md" 2>/dev/null && score=$((score + 30))
  grep -qi "$ALERT_TYPE" "$dir/timeline.md" 2>/dev/null && score=$((score + 20))
  grep -qi "$ALERT_TYPE" "$dir/decisions.md" 2>/dev/null && score=$((score + 10))

  [ "$score" -gt 0 ] && echo "$score% — $name"
done | sort -rn
```

## What to Extract from Similar Incidents

For each match (top 3), extract:

1. **Summary** — `summary.md`
2. **Key Decision** — First `## DEC-XXX` in `decisions.md`
3. **Outcome** — From `lessons.md` (what went well / what to avoid)
4. **Duration** — From `summary.md` (MTTR)

## Example Result

```
92% — INC-001
  Key Decision: DEC-001 — Skip runtime restart, disk cleanup only
  Outcome: ✅ 12 min MTTR, zero evictions
  Precedent: INC-004 (runtime restart = 45 min, 23 evictions)

76% — INC-004
  Key Decision: DEC-004 — Followed runbook (runtime restart first)
  Outcome: ❌ 45 min MTTR, 23 pod evictions

68% — INC-006
  Key Decision: DEC-006 — Partial cleanup, restart as backup
  Outcome: ✅ 18 min MTTR, restart not needed
```

## Updating the Incident File

After finding similar incidents, update the active incident file:

```markdown
### Similar Incidents

- INC-001 (92% match) — Skip runtime restart, 12 min MTTR ✅
- INC-004 (76% match) — Runtime restart, 45 min MTTR ❌
- INC-006 (68% match) — Partial cleanup, 18 min MTTR ✅
```
