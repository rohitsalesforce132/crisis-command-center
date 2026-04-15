#!/bin/bash
# Similar Incidents Search
# Searches incident replay engine for similar past incidents
# Usage: bash scripts/similar-incidents.sh --incident-id INC-20260412-1423

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INCIDENTS_DIR="$PROJECT_DIR/incidents/active"
REPLAY_ENGINE_DIR="$HOME/.openclaw/workspace/concepts/incident-replay-engine/replays"

# Parse arguments
INCIDENT_ID=""
ALERT_TYPE=""
CLUSTER=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --incident-id) INCIDENT_ID="$2"; shift ;;
        --alert-type) ALERT_TYPE="$2"; shift ;;
        --cluster) CLUSTER="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$INCIDENT_ID" ] && [ -z "$ALERT_TYPE" ]; then
    echo "Usage: bash similar-incidents.sh --incident-id <id> OR --alert-type <type> [--cluster <cluster>]"
    exit 1
fi

# If incident ID provided, extract details
if [ -n "$INCIDENT_ID" ]; then
    INCIDENT_FILE="$INCIDENTS_DIR/$INCIDENT_ID.md"
    if [ ! -f "$INCIDENT_FILE" ]; then
        echo "❌ Incident not found: $INCIDENT_FILE"
        exit 1
    fi
    
    ALERT_TYPE=$(grep -A2 "^## Alert Details" "$INCIDENT_FILE" | grep "Type:" | awk -F': ' '{print $2}')
    CLUSTER=$(grep -A2 "^## Alert Details" "$INCIDENT_FILE" | grep "Cluster:" | awk -F': ' '{print $2}')
fi

echo "🔍 Searching for similar incidents..."
echo "   Alert Type: $ALERT_TYPE"
echo "   Cluster: $CLUSTER"
echo ""

# Search in replay engine
RESULTS=()
SCORES=()

for replay_dir in "$REPLAY_ENGINE_DIR"/INC-*; do
    [ -d "$replay_dir" ] || continue
    
    replay_name=$(basename "$replay_dir")
    summary_file="$replay_dir/summary.md"
    
    if [ ! -f "$summary_file" ]; then
        continue
    fi
    
    score=0
    
    # Check for alert type match
    if grep -qi "$ALERT_TYPE" "$summary_file"; then
        score=$((score + 40))
    fi
    
    # Check for cluster match (if specified)
    if [ -n "$CLUSTER" ] && grep -qi "$CLUSTER" "$summary_file"; then
        score=$((score + 30))
    fi
    
    # Check timeline for similar keywords
    timeline_file="$replay_dir/timeline.md"
    if [ -f "$timeline_file" ]; then
        if grep -qi "$ALERT_TYPE" "$timeline_file"; then
            score=$((score + 20))
        fi
    fi
    
    # Check decisions for similar patterns
    decisions_file="$replay_dir/decisions.md"
    if [ -f "$decisions_file" ]; then
        if grep -qi "$ALERT_TYPE" "$decisions_file"; then
            score=$((score + 10))
        fi
    fi
    
    if [ "$score" -gt 0 ]; then
        RESULTS+=("$replay_name")
        SCORES+=("$score")
    fi
done

# Sort by score (descending)
sorted_indices=($(for i in "${!SCORES[@]}"; do echo "${SCORES[$i]} $i"; done | sort -rn | cut -d' ' -f2))

echo "Found ${#RESULTS[@]} similar incidents:"
echo ""
echo "┌──────────────────────────────────────────────────────────┐"
printf "│ %-20s │ %-10s │ %-20s │\n" "Incident" "Score" "Key Decision"
echo "├──────────────────────────────────────────────────────────┤"

for idx in "${sorted_indices[@]}"; do
    replay_name="${RESULTS[$idx]}"
    score="${SCORES[$idx]}"
    
    # Extract key decision
    decisions_file="$REPLAY_ENGINE_DIR/$replay_name/decisions.md"
    if [ -f "$decisions_file" ]; then
        key_decision=$(grep "^## DEC-" "$decisions_file" | head -1 | sed 's/## //' | cut -d':' -f1)
        if [ -z "$key_decision" ]; then
            key_decision=$(grep "DECISION:" "$decisions_file" | head -1 | awk -F': ' '{print $2}')
        fi
        if [ -z "$key_decision" ]; then
            key_decision="N/A"
        fi
    else
        key_decision="N/A"
    fi
    
    # Truncate if too long
    if [ ${#key_decision} -gt 20 ]; then
        key_decision="${key_decision:0:17}..."
    fi
    
    # Color coding
    if [ "$score" -ge 80 ]; then
        color="\033[32m"  # Green
    elif [ "$score" -ge 50 ]; then
        color="\033[33m"  # Yellow
    else
        color="\033[31m"  # Red
    fi
    
    printf "│ \033[1m%-20s\033[0m │ ${color}%3d%%\033[0m │ %-20s │\n" "$replay_name" "$score" "$key_decision"
done

echo "└──────────────────────────────────────────────────────────┘"

# If incident ID provided, update the incident file
if [ -n "$INCIDENT_ID" ]; then
    INCIDENT_FILE="$INCIDENTS_DIR/$INCIDENT_ID.md"
    
    # Find the section to update
    if grep -q "^### Similar Incidents" "$INCIDENT_FILE"; then
        # Replace the section
        awk -v section_start="### Similar Incidents" \
            -v section_end="^### " \
            -v content="
- ${RESULTS[0]:-None} (${SCORES[0]:-0}% match)
- ${RESULTS[1]:-None} (${SCORES[1]:-0}% match)
- ${RESULTS[2]:-None} (${SCORES[2]:-0}% match)
" '
        $0 ~ section_start { in_section=1; print; next }
        in_section && $0 ~ section_end { in_section=0; print content; }
        !in_section { print }
        ' "$INCIDENT_FILE" > "$INCIDENT_FILE.tmp" && mv "$INCIDENT_FILE.tmp" "$INCIDENT_FILE"
    fi
    
    echo ""
    echo "✅ Updated incident file: $INCIDENT_FILE"
fi
