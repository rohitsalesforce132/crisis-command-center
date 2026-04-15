#!/bin/bash
# Launch Dashboard
# Interactive terminal dashboard for incident response
# Usage: bash scripts/launch-dashboard.sh INC-20260412-1423

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"
INCIDENTS_DIR="$PROJECT_DIR/incidents/active"

INCIDENT_ID="$1"

if [ -z "$INCIDENT_ID" ]; then
    echo "Usage: bash launch-dashboard.sh <INC-XXX>"
    echo ""
    echo "Available incidents:"
    ls -1 "$INCIDENTS_DIR" 2>/dev/null | grep "INC-"
    exit 1
fi

INCIDENT_FILE="$INCIDENTS_DIR/$INCIDENT_ID.md"

if [ ! -f "$INCIDENT_FILE" ]; then
    echo "❌ Incident not found: $INCIDENT_FILE"
    exit 1
fi

# Clear screen
clear

# Extract incident details
ALERT_TYPE=$(grep -A2 "^## Alert Details" "$INCIDENT_FILE" | grep "Type:" | awk -F': ' '{print $2}')
CLUSTER=$(grep -A2 "^## Alert Details" "$INCIDENT_FILE" | grep "Cluster:" | awk -F': ' '{print $2}')
SEVERITY=$(grep -A2 "^## Alert Details" "$INCIDENT_FILE" | grep "Severity:" | awk -F': ' '{print $2}')
NODES=$(grep -A2 "^## Alert Details" "$INCIDENT_FILE" | grep "Nodes" | awk -F': ' '{print $2}')
DETECTED=$(grep -A2 "^## Alert Details" "$INCIDENT_FILE" | grep "Detected:" | awk -F': ' '{print $2}')

# Extract similar incidents
SIMILAR_INCIDENTS=$(sed -n '/### Similar Incidents/,/^### /p' "$INCIDENT_FILE" | tail -n +2 | head -n -1)

# Extract decision support
DECISION_SUPPORT=$(sed -n '/### Decision Support/,/^### /p' "$INCIDENT_FILE" | tail -n +2 | head -n -1)

# Dashboard function
show_dashboard() {
    clear
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  CRISIS COMMAND CENTER                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Current Incident Panel
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  🚨 CURRENT INCIDENT                                          │"
    echo "├──────────────────────────────────────────────────────────────┤"
    printf "│  ID:          %-40s │\n" "$INCIDENT_ID"
    printf "│  Type:        %-40s │\n" "$ALERT_TYPE"
    printf "│  Cluster:     %-40s │\n" "$CLUSTER"
    printf "│  Severity:    %-40s │\n" "$SEVERITY"
    printf "│  Nodes:       %-40s │\n" "$NODES"
    printf "│  Detected:    %-40s │\n" "$DETECTED"
    echo "└──────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Similar Incidents Panel
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  🔍 SIMILAR INCIDENTS                                         │"
    echo "├──────────────────────────────────────────────────────────────┤"
    if [ -n "$SIMILAR_INCIDENTS" ]; then
        echo "$SIMILAR_INCIDENTS" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                printf "│  %-60s │\n" "$line"
            fi
        done
    else
        printf "│  %-60s │\n" "No similar incidents found."
    fi
    echo "└──────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Decision Support Panel
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  🧠 DECISION SUPPORT                                          │"
    echo "├──────────────────────────────────────────────────────────────┤"
    if [ -n "$DECISION_SUPPORT" ]; then
        echo "$DECISION_SUPPORT" | head -5 | while IFS= read -r line; do
            if [ -n "$line" ]; then
                printf "│  %-60s │\n" "$line"
            fi
        done
    else
        printf "│  %-60s │\n" "Run decision-support.sh to get suggestions."
    fi
    echo "└──────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Actions Menu
    echo "ACTIONS:"
    echo "  [1] View similar incidents details"
    echo "  [2] View decision support details"
    echo "  [3] Open incident file for editing"
    echo "  [4] Launch kubectl terminal"
    echo "  [5] Run similar-incident search"
    echo "  [6] Run decision-support engine"
    echo "  [7] Generate incident replay"
    echo "  [0] Exit"
    echo ""
    echo -n "Select action [0-7]: "
}

# Main loop
while true; do
    show_dashboard
    read -r choice
    
    case $choice in
        1)
            echo ""
            echo "Similar Incidents Details:"
            echo "───────────────────────────"
            "$SCRIPT_DIR/similar-incidents.sh" --incident-id "$INCIDENT_ID"
            echo ""
            echo "Press Enter to continue..."
            read
            ;;
        2)
            echo ""
            echo "Decision Support Details:"
            echo "─────────────────────────"
            "$SCRIPT_DIR/decision-support.sh" --incident-id "$INCIDENT_ID"
            echo ""
            echo "Press Enter to continue..."
            read
            ;;
        3)
            ${EDITOR:-nano} "$INCIDENT_FILE"
            ;;
        4)
            echo ""
            echo "Launching kubectl terminal..."
            echo "Type 'exit' to return to dashboard."
            echo ""
            bash
            ;;
        5)
            "$SCRIPT_DIR/similar-incidents.sh" --incident-id "$INCIDENT_ID"
            echo ""
            echo "Press Enter to continue..."
            read
            ;;
        6)
            "$SCRIPT_DIR/decision-support.sh" --incident-id "$INCIDENT_ID"
            echo ""
            echo "Press Enter to continue..."
            read
            ;;
        7)
            echo ""
            echo "Generating incident replay..."
            echo "This would copy the incident file to the incident replay engine."
            echo "Feature coming soon!"
            echo ""
            echo "Press Enter to continue..."
            read
            ;;
        0)
            echo ""
            echo "Exiting Crisis Command Center..."
            exit 0
            ;;
        *)
            echo ""
            echo "Invalid choice. Press Enter to continue..."
            read
            ;;
    esac
done
