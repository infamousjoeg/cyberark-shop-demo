# CyberArk Shop Demo

A microservice digital store demonstration integrated with CyberArk's Identity Security Platform and Venafi's Cloud Control Plane. This repository provides a complete demo environment that showcases secure service-to-service authentication, certificate management, and secret handling.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Supported Platforms](#supported-platforms)
- [Installation](#installation)
- [Usage](#usage)
- [Component Breakdown](#component-breakdown)
- [Ansible KinD Role](#ansible-kind-role)
- [Certificate Management Scenarios](#certificate-management-scenarios)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Overview

The CyberArk Shop Demo creates a complete microservices environment integrated with:

- **CyberArk's Identity Security Platform** - For secret management and access control
- **Venafi's Cloud Control Plane** - For certificate lifecycle management
- **Istio Service Mesh** - For secure service-to-service communication

The demo showcases real-world security patterns including:
- Non-human identity security
- Certificate lifecycle management
- Secret rotation and access
- Workload identity
- Service mesh security

## Architecture

The demo deploys a Kubernetes-in-Docker (KinD) cluster with several components:

1. **Base Infrastructure**
   - KinD Kubernetes cluster
   - Venafi Control Plane integration
   - CyberArk Conjur Cloud integration

2. **Certificate Management**
   - Certificate Managers
   - Approver Policies
   - Venafi Firefly

3. **Service Mesh**
   - Istio service mesh
   - Microservice applications
   - mTLS communication

4. **Demonstration Scenarios**
   - Various certificate scenarios (good and bad)
   - Secret access patterns
   - Workload identity

## Supported Platforms

This demo has been tested and is fully supported on:

- **Ubuntu Linux** (18.04 LTS, 20.04 LTS, 22.04 LTS)
- **MacOS** (Catalina, Big Sur, Monterey, Ventura)

## Prerequisites

### General Requirements

- Docker
- Internet connection (for pulling required images)
- CyberArk Secrets Manager/Conjur Cloud account
- Venafi Control Plane account

### Ubuntu-specific Requirements

```bash
# Install base dependencies
sudo apt update
sudo apt install -y curl git

# Install Docker (if not already installed)
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### MacOS-specific Requirements

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker (or download Docker Desktop from docker.com)
brew install docker
```

## Installation

1. Clone this repository:

```bash
git clone https://github.com/yourusername/cyberark-shop-demo.git
cd cyberark-shop-demo
```

2. Configure settings in the variables file:

```bash
cp ansible/playbooks/vars/vars.template.yml ansible/playbooks/vars/vars.yml
```

Edit the `vars.yml` file with your personal configuration details:
- Venafi API key and zone information
- CyberArk credentials and zone information
- Resource naming preferences

3. Run the installation script:

```bash
./start.sh
```

This script will automatically:
- Detect your operating system (Ubuntu or MacOS)
- Install necessary dependencies
- Configure and deploy the entire demo environment

## Usage

The `start.sh` script provides an interactive menu that allows you to:

- Deploy the complete environment
- Deploy only specific components
- Start from any specific step

```
=============================================
CYBERARK SHOP DEPLOYMENT SETUP
=============================================

Grouped Options:
  A) Deploy KinD Cluster Only               -> Step 1
  B) Deploy (A) & Venafi Components          -> Steps 1-8
  C) Deploy (A), (B) & TLS Protect for K8s    -> Steps 1-14
  D) Deploy (A), (B), (C) & Workload Identity  -> Steps 1-17 (Default)

Detailed Steps:
   1. [Group A] Install & Create kind Cluster
   2. [Group B] Install dependencies (venctl, jq, etc.)
   3. [Group B] Create necessary directories
   ...
```

## Component Breakdown

### 1. KinD Cluster

A local Kubernetes cluster running inside Docker containers, providing a lightweight environment for the demo.

### 2. Venafi Components

- **Certificate Manager**: Automates certificate lifecycle
- **Venafi Control Plane**: External certificate authority integration
- **Venafi Firefly**: Dynamic certificate policy enforcement

### 3. CyberArk Integration

- **Conjur Cloud**: Cloud-based secrets management
- **External Secrets Operator**: Kubernetes integration for secrets
- **JWT Authentication**: Secure identity verification

### 4. Service Mesh

- **Istio**: Service mesh for secure communication
- **Kiali**: Service mesh visualization
- **Prometheus/Grafana**: Monitoring and metrics

### 5. Demo Applications

- **Microservices Demo**: Sample application with multiple services
- **Certificate Scenarios**: Various certificate configurations for testing and demonstration

## Ansible KinD Role

The project includes a custom Ansible role for managing Kubernetes-in-Docker (KinD) clusters.

### Usage by Tags

| Tag | Actions Performed |
|-----|-------------------|
| install | Installs docker, kubectl, kind |
| create | Creates kind cluster |
| delete | Deletes kind cluster |
| clean | Clean up docker, kubectl, kind |

### Example Usage

```bash
ansible-playbook ansible/kind.yml --tags "install, create"
```

## Certificate Management Scenarios

The demo includes several certificate scenarios to demonstrate different aspects of certificate management:

1. **Unmanaged Kid**: Self-signed certificate not managed by Venafi
2. **Expiry Eddie**: Long-duration certificate demonstration (1 year)
3. **Cipher-Snake**: Certificate with bad key size (1024-bit)
4. **Ghost-Rider**: Orphaned certificate example
5. **Phantom-CA**: Custom CA certificate demonstration

These scenarios help demonstrate certificate-related security risks and proper management practices.

## Troubleshooting

### Common Issues

#### Docker Permission Issues (Ubuntu)

If you encounter permission issues with Docker:

```bash
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
```

#### KinD Cluster Creation Fails

Ensure you have enough resources allocated to Docker:
- At least 4GB of available memory
- At least 2 CPU cores

#### Venafi Authentication Issues

Verify your API key is correct and has the necessary permissions.

#### Conjur/CyberArk Connection Issues

Ensure your subdomain and credentials are correctly configured in `vars.yml`.

## License

[MIT](LICENSE)
