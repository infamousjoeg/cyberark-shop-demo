#!/bin/bash
set -eou pipefail

echo "+ Check if Ansible is installed"
if ! command -v ansible >/dev/null 2>&1; then
    echo "❌ Error: Ansible is not installed!"
    exit 1
else
    echo "✅ Ansible is installed: $(ansible --version | head -n 1)"
fi

# Ensure "ansible" directory exists before pushing into it
if [ ! -d "ansible" ]; then
    echo "❌ Error: 'ansible' directory not found!"
    exit 1
fi

pushd "ansible" > /dev/null

    echo "+ Installing Kubernetes-in-Docker (kind) pre-requisites"
    if ! ansible-playbook playbooks/kind.yml --tags "install"; then
        echo "❌ Error: Failed to install Kubernetes-in-Docker pre-requisites"
        exit 1
    fi

    echo "+ Creating kind cluster"
    if ! ansible-playbook playbooks/kind.yml --tags "create"; then
        echo "❌ Error: Failed to create kind cluster"
        exit 1
    fi

    echo "+ Preloading Docker images into kind cluster"
    if ! ansible-playbook playbooks/kind.yml --tags "load"; then
        echo "❌ Error: Failed to preload Docker images"
        exit 1
    fi

    echo "+ Verify/Change Configuration"
    while true; do
        read -rp "Verify/Change values in $PWD/playbooks/vars/vars.yml and press ENTER to continue..." input
        if [ -z "$input" ]; then
            break  # Exit loop and continue script
        else
            echo "Error: Just press Enter without typing anything"
        fi
    done

    echo "+ Initialize Workspace"
    if ! ansible-playbook playbooks/init.yml; then
        echo "❌ Error: Failed to initialize workspace"
        exit 1
    fi

    echo "+ Create Venafi Service Account for Discovery"
    if ! ansible-playbook playbooks/create-sa-discovery.yml; then
        echo "❌ Error: Failed to create Venafi Service Account for Discovery"
        exit 1
    fi

    echo "+ Create Venafi Service Account for Private Registry"
    if ! ansible-playbook playbooks/create-sa-registry.yml; then
        echo "❌ Error: Failed to create Venafi Service Account for Private Registry"
        exit 1
    fi

    echo "+ Create Venafi Service Account for Firefly"
    if ! ansible-playbook playbooks/create-sa-firefly.yml; then
        echo "❌ Error: Failed to create Venafi Service Account for Firefly"
        exit 1
    fi

popd > /dev/null || echo "Warning: popd failed, but script completed successfully."