#!/bin/bash
# =============================================
# CyberArk Shop Deployment Setup Script
# =============================================

# Define paths for Ansible playbooks
ANSIBLE_DIR="ansible"
PLAYBOOK_DIR="$ANSIBLE_DIR/playbooks"

# Function to print section headers
print_section() {
  echo "============================================="
  echo "$1"
  echo "============================================="
}

# Define steps and their corresponding playbook commands
STEPS=(
  "Install & Create kind Cluster"
  "Install dependencies (venctl, jq, etc.)"
  "Create necessary directories"
  "Deploy service accounts"
  "Setup Kubernetes namespaces"
  "Generate Venafi manifests"
  "Deploy Venafi components"
  "Setup Venafi Cloud integration"
  "Deploy sandbox resources"
  "Create Unmanaged Kid in Nginx"
  "Create Expiry Eddie - Long Duration Cert"
  "Create Cipher-Snake - Bad Key Size"
  "Create Ghost-Rider - Orphan Cert"
  "Create Phantom-CA & Certificate"
  "Setup Configuration for Service Mesh"
  "Install Istio Service Mesh"
  "Deploy CyberArk Shop Microservice App with Firefly"
)

PLAYBOOKS=(
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/kind.yml' --tags 'install, create'"
  "ansible-galaxy collection install -r '$ANSIBLE_DIR/requirements.yml' && ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/install_dependencies.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/setup_directories.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/create_service_accounts.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/configure_k8s_namespaces.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/generate_manifests.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/install_venafi_components.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/setup_cloud_integration.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/setup_sandbox.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/create_unmanaged_kid.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/create_expiry_eddie.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/create_cipher-snake.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/create_ghost-rider.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/create_phantom-ca.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/setup_mesh_apps.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/install_istio.yml'"
  "ansible-playbook -i ansible/inventory '$PLAYBOOK_DIR/deploy_mesh_apps.yml'"
)

TOTAL_STEPS=${#STEPS[@]}

# =============================================
# Display Menu Options
# =============================================
clear
print_section "CYBERARK SHOP DEPLOYMENT SETUP"

# Grouped (Lettered) Options
echo "Grouped Options:"
echo "  A) Deploy KinD Cluster Only               -> Step 1"
echo "  B) Deploy (A) & Venafi Components          -> Steps 1-8"
echo "  C) Deploy (A), (B) & TLS Protect for K8s    -> Steps 1-14"
echo "  D) Deploy (A), (B), (C) & Workload Identity  -> Steps 1-17 (Default)"
echo ""

# Detailed Numbered Menu with Group Annotations
echo "Detailed Steps:"
for (( i=0; i<TOTAL_STEPS; i++ )); do
  # Group assignment based on step index (0-based)
  if [ $i -eq 0 ]; then
    group="A"
  elif [ $i -lt 8 ]; then
    group="B"
  elif [ $i -lt 14 ]; then
    group="C"
  else
    group="D"
  fi
  printf "  %2d. [Group %s] %s\n" $((i+1)) "$group" "${STEPS[$i]}"
done

echo ""
echo "Enter a number (1-$TOTAL_STEPS) to start from that step,"
echo "or a letter (A, B, C, D) for a preset grouping."
echo "Press ENTER with no input to run the full deployment."
echo -n "Your selection: "
read -r CHOICE

# =============================================
# Process User Input to Determine Execution Range
# =============================================
# Default to full deployment
START_INDEX=0
END_INDEX=$((TOTAL_STEPS - 1))

if [[ -z "$CHOICE" ]]; then
  echo "No input provided. Running full deployment (steps 1-$TOTAL_STEPS)."
elif [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
  if (( CHOICE >= 1 && CHOICE <= TOTAL_STEPS )); then
    START_INDEX=$((CHOICE - 1))
    echo "Starting deployment from step $CHOICE through step $TOTAL_STEPS."
  else
    echo "Invalid number. Running full deployment."
  fi
elif [[ "$CHOICE" =~ ^[A-Za-z]$ ]]; then
  LETTER=$(echo "$CHOICE" | tr '[:lower:]' '[:upper:]')
  case "$LETTER" in
    A)
      END_INDEX=0
      echo "Running Group A: Only step 1 (KinD Cluster)."
      ;;
    B)
      END_INDEX=7
      echo "Running Group B: Steps 1 through 8 (KinD + Venafi Components)."
      ;;
    C)
      END_INDEX=13
      echo "Running Group C: Steps 1 through 14 (including TLS Protect for K8s)."
      ;;
    D)
      END_INDEX=$((TOTAL_STEPS - 1))
      echo "Running Group D: Full deployment (steps 1-$TOTAL_STEPS)."
      ;;
    *)
      echo "Invalid letter selection. Running full deployment."
      ;;
  esac
else
  echo "Invalid input. Running full deployment."
fi

echo ""
echo "Beginning execution..."
echo ""

# =============================================
# Execute Selected Playbooks
# =============================================
for (( i = START_INDEX; i <= END_INDEX; i++ )); do
  print_section "${STEPS[$i]}"
  eval "${PLAYBOOKS[$i]}" || { echo "Error encountered during '${STEPS[$i]}'. Exiting."; exit 1; }
done

print_section "DEPLOYMENT COMPLETE"
echo "Deployment completed successfully!"
echo "Verify the deployment with: kubectl get pods -A"
echo "============================================="
