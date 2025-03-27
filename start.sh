#!/bin/bash
# =============================================
# CyberArk Shop Deployment Setup Script
# Supports both Ubuntu Linux and MacOS environments
# Author: Joe Garcia (Original)
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

# Reordered and regrouped steps for better efficiency
# The steps are now organized by logical component groupings:
# 1. Infrastructure setup
# 2. Core components
# 3. Certificate scenarios
# 4. Identity & Secret Management
# 5. Service Mesh & Applications

# Define steps and their corresponding playbook commands
STEPS=(
  # Group A: Infrastructure Setup
  "Install & Create kind Cluster"
  "Install dependencies (venctl, jq, etc.)"
  "Create necessary directories"
  "Deploy service accounts"
  "Setup Kubernetes namespaces"
  
  # Group B: Core Components
  "Generate Venafi manifests"
  "Deploy Venafi components"
  "Setup Venafi Cloud integration"
  "Install External Secrets Operator"
  
  # Group C: Certificate Management
  "Deploy sandbox resources"
  "Create Unmanaged Kid in Nginx"
  "Create Expiry Eddie - Long Duration Cert"
  "Create Cipher-Snake - Bad Key Size"
  "Create Ghost-Rider - Orphan Cert"
  "Create Phantom-CA & Certificate"
  
  # Group D: Identity & Secret Management
  "Setup Privilege Cloud integration"
  "Setup Conjur JWT authentication"
  "Setup Workload Identity"
  
  # Group E: Service Mesh & Applications
  "Setup Configuration for Service Mesh"
  "Install Istio Service Mesh"
  "Deploy CyberArk Shop Microservice App with Firefly"
)

PLAYBOOKS=(
  # Group A: Infrastructure Setup
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/kind.yml' --tags 'install, create'"
  "ansible-galaxy collection install -r '$ANSIBLE_DIR/requirements.yml' && ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/install_dependencies.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_directories.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_service_accounts.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/configure_k8s_namespaces.yml'"
  
  # Group B: Core Components
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/generate_manifests.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/install_venafi_components.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_cloud_integration.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/install_external_secrets_operator.yml'"
  
  # Group C: Certificate Management
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_sandbox.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_unmanaged_kid.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_expiry_eddie.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_cipher-snake.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_ghost-rider.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/create_phantom-ca.yml'"
  
  # Group D: Identity & Secret Management
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_privilegecloud.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_conjur_jwt.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_workload_identity.yml'"
  
  # Group E: Service Mesh & Applications
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/setup_mesh_apps.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/install_istio.yml'"
  "ansible-playbook -i $ANSIBLE_DIR/inventory '$PLAYBOOK_DIR/deploy_mesh_apps.yml'"
)

TOTAL_STEPS=${#STEPS[@]}

# Define the index ranges for each logical group
GROUP_A_START=0
GROUP_A_END=4
GROUP_B_START=5
GROUP_B_END=8
GROUP_C_START=9
GROUP_C_END=14
GROUP_D_START=15
GROUP_D_END=17
GROUP_E_START=18
GROUP_E_END=20

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

# Grouped (Lettered) Options with more descriptive names
echo "Grouped Options:"
echo "  A) Infrastructure Setup                  -> Steps 1-5"
echo "  B) Core Components                       -> Steps 1-9"
echo "  C) Certificate Management                -> Steps 1-15"
echo "  D) Identity & Secret Management          -> Steps 1-18"
echo "  E) Full Deployment w/ Service Mesh       -> Steps 1-21 (Default)"
echo ""

# Detailed Numbered Menu with Group Annotations
echo "Detailed Steps:"
for (( i=0; i<TOTAL_STEPS; i++ )); do
  # Group assignment based on step index (0-based)
  if [ $i -le $GROUP_A_END ]; then
    group="A"
  elif [ $i -le $GROUP_B_END ]; then
    group="B"
  elif [ $i -le $GROUP_C_END ]; then
    group="C"
  elif [ $i -le $GROUP_D_END ]; then
    group="D"
  else
    group="E"
  fi
  printf "  %2d. [Group %s] %s\n" $((i+1)) "$group" "${STEPS[$i]}"
done

echo ""
echo "Enter a number (1-$TOTAL_STEPS) to start from a specific section,"
echo "or a letter (A, B, C, D, E) for a preset grouping."
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
      END_INDEX=$GROUP_A_END
      echo "Running Group A: Infrastructure Setup (Steps 1-$((GROUP_A_END+1)))."
      ;;
    B)
      END_INDEX=$GROUP_B_END
      echo "Running Group B: Core Components (Steps 1-$((GROUP_B_END+1)))."
      ;;
    C)
      END_INDEX=$GROUP_C_END
      echo "Running Group C: Certificate Management (Steps 1-$((GROUP_C_END+1)))."
      ;;
    D)
      END_INDEX=$GROUP_D_END
      echo "Running Group D: Identity & Secret Management (Steps 1-$((GROUP_D_END+1)))."
      ;;
    E)
      END_INDEX=$GROUP_E_END
      echo "Running Group E: Full Deployment w/ Service Mesh (Steps 1-$((GROUP_E_END+1)))."
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
# Track execution status for detailed reporting
declare -A step_status
for (( i = START_INDEX; i <= END_INDEX; i++ )); do
  print_section "${STEPS[$i]}"
  
  # Set OS-specific environment variables
  if [ "$OS_TYPE" = "Ubuntu" ]; then
    export ANSIBLE_BECOME=true
  fi
  
  # Execute the playbook and capture the exit status
  echo "Running: ${PLAYBOOKS[$i]}"
  eval "${PLAYBOOKS[$i]}"
  exit_status=$?
  
  # Store the result for summary reporting
  if [ $exit_status -eq 0 ]; then
    step_status[$i]="SUCCESS"
  else
    step_status[$i]="FAILED"
    echo "Error encountered during '${STEPS[$i]}'."
    
    # Ask if user wants to continue despite error
    echo -n "Continue with deployment? (y/n): "
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
      echo "Deployment aborted at step $((i+1))."
      exit 1
    fi
  fi
done

# =============================================
# Deployment Summary Report
# =============================================
print_section "DEPLOYMENT SUMMARY"
echo "Deployment completed with the following results:"
echo ""

for (( i = START_INDEX; i <= END_INDEX; i++ )); do
  status="${step_status[$i]:-SKIPPED}"
  printf "  %2d. %-40s [%s]\n" $((i+1)) "${STEPS[$i]}" "$status"
done

echo ""
print_section "DEPLOYMENT COMPLETE"
echo "Verify the deployment with: kubectl get pods -A"

# Display additional verification commands based on what was deployed
if [ $END_INDEX -ge $GROUP_B_END ]; then
  echo "Check Venafi components: kubectl get pods -n venafi-system"
fi

if [ $END_INDEX -ge $GROUP_D_END ]; then
  echo "Verify identity configuration: kubectl get secretproviderclass -A"
fi

if [ $END_INDEX -ge $GROUP_E_END ]; then
  echo "Access Service Mesh dashboard: istioctl dashboard kiali"
fi

echo "============================================="
