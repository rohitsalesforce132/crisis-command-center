#!/bin/bash
# Decision Support Engine
# Queries context graph for precedents and decision guidance
# Usage: bash scripts/decision-support.sh --incident-id INC-20260412-1423

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INCIDENTS_DIR="$PROJECT_DIR/incidents/active"
CONTEXT_GRAPH_DIR="$HOME/.openclaw/workspace/context-graph/decisions"

# Parse arguments
INCIDENT_ID=""
ALERT_TYPE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --incident-id) INCIDENT_ID="$2"; shift ;;
        --alert-type) ALERT_TYPE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$INCIDENT_ID" ] && [ -z "$ALERT_TYPE" ]; then
    echo "Usage: bash decision-support.sh --incident-id <id> OR --alert-type <type>"
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
fi

echo "🧠 Decision Support Engine"
echo "   Analyzing: $ALERT_TYPE"
echo ""

# Search context graph for relevant decisions
DECISIONS=()
RISKS=()
OUTCOMES=()

for decision_file in "$CONTEXT_GRAPH_DIR"/*.md; do
    [ -f "$decision_file" ] || continue
    
    decision_name=$(basename "$decision_file")
    
    # Check if decision is relevant to alert type
    if grep -qi "$ALERT_TYPE" "$decision_file"; then
        # Extract decision summary
        decision_summary=$(grep "^# " "$decision_file" | head -1 | sed 's/^# //')
        
        # Extract risk level
        risk=$(grep -i "risk:" "$decision_file" | head -1 | awk -F': ' '{print $2}')
        if [ -z "$risk" ]; then
            risk="MEDIUM"
        fi
        
        # Extract outcome
        outcome=$(grep -i "outcome:" "$decision_file" | head -1 | awk -F': ' '{print $2}')
        if [ -z "$outcome" ]; then
            outcome=$(grep -i "result:" "$decision_file" | head -1 | awk -F': ' '{print $2}')
        fi
        if [ -z "$outcome" ]; then
            outcome="Unknown"
        fi
        
        DECISIONS+=("$decision_name: $decision_summary")
        RISKS+=("$risk")
        OUTCOMES+=("$outcome")
    fi
done

if [ ${#DECISIONS[@]} -eq 0 ]; then
    echo "⚠️  No relevant decisions found in context graph."
    echo ""
    echo "   This may be a new type of incident."
    echo "   Consider creating a new decision trace after resolution."
else
    echo "Found ${#DECISIONS[@]} relevant decisions:"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    printf "│ %-50s │ %-8s │ %-15s │\n" "Decision" "Risk" "Outcome"
    echo "├──────────────────────────────────────────────────────────┤"
    
    for i in "${!DECISIONS[@]}"; do
        decision="${DECISIONS[$i]}"
        risk="${RISKS[$i]}"
        outcome="${OUTCOMES[$i]}"
        
        # Color coding for risk
        case "$risk" in
            HIGH) risk_color="\033[31m" ;;
            MEDIUM) risk_color="\033[33m" ;;
            LOW|NONE) risk_color="\033[32m" ;;
            *) risk_color="\033[0m" ;;
        esac
        
        # Color coding for outcome
        case "$outcome" in
            *success*|*resolved*|*fixed*|*good*) outcome_color="\033[32m" ;;
            *failed*|*worse*|*bad*|*error*) outcome_color="\033[31m" ;;
            *) outcome_color="\033[0m" ;;
        esac
        
        printf "│ %-50s │ ${risk_color}%-6s\033[0m │ ${outcome_color}%-13s\033[0m │\n" "$decision" "$risk" "$outcome"
    done
    
    echo "└──────────────────────────────────────────────────────────┘"
fi

echo ""

# Look for conflicts with runbooks
echo "📋 Runbook Conflict Check:"
echo ""

# This would typically check runbook files
# For now, we'll check the incident replay engine for decision traces
REPLAY_ENGINE_DIR="$HOME/.openclaw/workspace/concepts/incident-replay-engine/replays"

CONFLICTS_FOUND=false

for replay_dir in "$REPLAY_ENGINE_DIR"/INC-*; do
    [ -d "$replay_dir" ] || continue
    
    decisions_file="$replay_dir/decisions.md"
    if [ -f "$decisions_file" ]; then
        # Look for runbook conflicts
        if grep -qi "runbook.*conflict" "$decisions_file"; then
            replay_name=$(basename "$replay_dir")
            echo "   ⚠️  $replay_name: Runbook conflict detected"
            CONFLICTS_FOUND=true
        fi
        
        # Look for exceptions made to runbooks
        if grep -qi "exception made" "$decisions_file"; then
            replay_name=$(basename "$replay_dir")
            echo "   ⚠️  $replay_name: Runbook exception documented"
            CONFLICTS_FOUND=true
        fi
    fi
done

if ! $CONFLICTS_FOUND; then
    echo "   ✅ No runbook conflicts found for this alert type."
fi

echo ""

# Update incident file if incident ID provided
if [ -n "$INCIDENT_ID" ]; then
    INCIDENT_FILE="$INCIDENTS_DIR/$INCIDENT_ID.md"
    
    # Add decision support section
    if ! grep -q "^### Decision Support" "$INCIDENT_FILE"; then
        awk -v section="### Decision Support" '
        /### Precedent Decisions/ { print section; print ""; print "[Auto-generated by crisis-command-center]"; print ""; next }
        { print }
        ' "$INCIDENT_FILE" > "$INCIDENT_FILE.tmp" && mv "$INCIDENT_FILE.tmp" "$INCIDENT_FILE"
    fi
    
    echo "✅ Decision support added to: $INCIDENT_FILE"
fi
