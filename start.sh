#!/bin/bash

# Define the path to the Ansible playbooks
ANSIBLE_DIR="ansible"
PLAYBOOK_DIR="$ANSIBLE_DIR/playbooks"

# Function to print section headers
print_section() {
  echo "============================================="
  echo "$1"
  echo "============================================="
}

# List of steps for the menu
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

# Function to display the menu and get user input
display_menu() {
  clear
  print_section "WELCOME TO THE CYBERARK SHOP DEPLOYMENT SETUP"
  echo ""
  echo "This script will execute the following steps:"
  echo ""

  for i in "${!STEPS[@]}"; do
    echo "$((i + 1)). ${STEPS[$i]}"
  done

  echo ""
  echo "Before continuing, please review and modify any necessary variables in:"
  echo "  → $PLAYBOOK_DIR/vars/vars.yml"
  echo ""
  echo "Enter a number to start from a specific section, or press [ENTER] to start from the beginning:"
  read -r START_FROM

  if [[ -z "$START_FROM" ]]; then
    START_FROM=1
  elif ! [[ "$START_FROM" =~ ^[0-9]+$ ]] || (( START_FROM < 1 || START_FROM > ${#STEPS[@]} )); then
    echo "Invalid selection. Starting from the beginning."
    START_FROM=1
  fi

  return $((START_FROM - 1))
}

# Display menu and get the starting index
display_menu
START_INDEX=$?

# Playbook commands corresponding to each step
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

# Execute the selected steps
for ((i = START_INDEX; i < ${#STEPS[@]}; i++)); do
  print_section "${STEPS[$i]}"
  eval "${PLAYBOOKS[$i]}" || exit 1
done

print_section "CYBERARK SHOP SETUP COMPLETE"
echo "All selected playbooks have been executed successfully!"
echo "You can now verify the deployment by running:"
echo ""
echo "    kubectl get pods -A"
echo ""
echo "If any issues occur, check the logs or rerun individual playbooks as needed."
echo "========================================"