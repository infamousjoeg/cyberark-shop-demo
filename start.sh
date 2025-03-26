#!/bin/bash
# =============================================
# CyberArk Shop Deployment Setup Script
# Supports both Ubuntu Linux and MacOS environments
# =============================================

# Define paths for Ansible playbooks
ANSIBLE_DIR="ansible"
PLAYBOOK_DIR="$ANSIBLE_DIR/playbooks"

# Detect operating system and store in OS_TYPE variable
detect_os() {
  # Check for Linux vs Darwin (MacOS)
  OS_TYPE=$(uname -s)
  if [ "$OS_TYPE" = "Linux" ]; then
    # On Linux, check specifically for Ubuntu
    if [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
      OS_TYPE="Ubuntu"
      echo "Ubuntu Linux detected"
    else
      echo "Warning: This script is optimized for Ubuntu Linux. Other Linux distributions may work but are not fully tested."
      OS_TYPE="Linux"
    fi
  elif [ "$OS_TYPE" = "Darwin" ]; then
    echo "MacOS detected"
  else
    echo "Warning: Unsupported operating system. This script is optimized for Ubuntu Linux and MacOS."
  fi
}

# Function to check and install prerequisites based on OS
check_prerequisites() {
  echo "Checking prerequisites..."
  
  # Check for Ansible
  if ! command -v ansible >/dev/null 2>&1; then
    echo "Ansible is not installed. Installing..."
    if [ "$OS_TYPE" = "Ubuntu" ] || [ "$OS_TYPE" = "Linux" ]; then
      # Ubuntu-specific Ansible installation
      sudo apt update
      sudo apt install -y software-properties-common
      sudo add-apt-repository --yes --update ppa:ansible/ansible
      sudo apt install -y ansible
    elif [ "$OS_TYPE" = "Darwin" ]; then
      # MacOS-specific Ansible installation
      if command -v brew >/dev/null 2>&1; then
        brew install ansible
      else
        echo "Homebrew is not installed. Please install Homebrew first, then run this script again."
        echo "You can install Homebrew with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
      fi
    else
      echo "Unsupported OS for automatic Ansible installation. Please install Ansible manually."
      exit 1
    fi
  fi
  
  # Check for Docker
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed. Please install Docker before continuing."
    if [ "$OS_TYPE" = "Ubuntu" ]; then
      echo "You can install Docker on Ubuntu with:"
      echo "  sudo apt update"
      echo "  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common"
      echo "  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
      echo "  sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\""
      echo "  sudo apt update"
      echo "  sudo apt install -y docker-ce"
      echo "  sudo usermod -aG docker $USER"
    elif [ "$OS_TYPE" = "Darwin" ]; then
      echo "For MacOS, download Docker Desktop from: https://www.docker.com/products/docker-desktop"
    fi
    exit 1
  fi
  
  # Check for kubectl
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl is not installed. It will be installed by the Ansible playbook."
  fi
  
  echo "Prerequisites check completed."
}

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
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/kind.yml' --tags 'install, create'"
  "ansible-galaxy collection install -r '$ANSIBLE_DIR/requirements.yml' && ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/install_dependencies.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_directories.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_service_accounts.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/configure_k8s_namespaces.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/generate_manifests.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/install_venafi_components.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_cloud_integration.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_sandbox.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_unmanaged_kid.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_expiry_eddie.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_cipher-snake.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_ghost-rider.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_phantom-ca.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_mesh_apps.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/install_istio.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/deploy_mesh_apps.yml'"
)

TOTAL_STEPS=${#STEPS[@]}

# First detect the OS
detect_os

# Then run prerequisite check
check_prerequisites

# =============================================
# Display Menu Options
# =============================================
clear
print_section "CYBERARK SHOP DEPLOYMENT SETUP"
echo "Running on detected OS: $OS_TYPE"
echo ""

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
echo "Enter a number (1-$TOTAL_STEPS) to start from a specific section,"
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
  
  # Add specific environment variables based on OS if needed
  if [ "$OS_TYPE" = "Ubuntu" ]; then
    # If any Ubuntu-specific environment variables are needed
    export ANSIBLE_BECOME=true
  fi
  
  eval "${PLAYBOOKS[$i]}" || { echo "Error encountered during '${STEPS[$i]}'. Exiting."; exit 1; }
done

print_section "DEPLOYMENT COMPLETE"
echo "Deployment completed successfully!"
echo "Verify the deployment with: kubectl get pods -A"
echo "============================================="
