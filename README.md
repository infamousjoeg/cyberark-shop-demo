# cyberark-shop-demo <!-- omit in toc -->

A microservice digital store demonstration integrated with CyberArk's Identity Security Platform and Venafi's Cloud Control Plane.

## Table of Contents <!-- omit in toc -->
- [Quick Start](#quick-start)
- [Ansible kind Role](#ansible-kind-role)
  - [Usage based on Tags](#usage-based-on-tags)
    - [Example Usage](#example-usage)
- [Ansible Playbooks](#ansible-playbooks)
  - [init.yml](#inityml)
  - [create-sa-discovery.yml](#create-sa-discoveryyml)
  - [create-sa-registry.yml](#create-sa-registryyml)
  - [create-sa-firefly.yml](#create-sa-fireflyyml)
- [License](#license)

## Quick Start

`./start.sh`

## Ansible kind Role

### Usage based on Tags

|Tag|Actions Performed|
|---|---|
|install|Installs docker, kubectl, kind|
|create|Creates kind cluster|
|load|Load docker_images from [vars](ansible/roles/kind/vars/main.yml)|
|delete|Deletes kind cluster|
|clean|Clean up docker, kubectl, kind|

#### Example Usage

`ansible-playbook ansible/kind.yml --tags "install, create, load"`

## Ansible Playbooks

### init.yml

This playbook will initialize the workspace, install or upgrade venctl, and create namespaces in the kind cluster.

Uses variables from [ansible/playbooks/vars/vars.yml]().

`ansible-playbook ansible/playbooks/init.yml`

### create-sa-discovery.yml

This playbook creates a service account in Venafi Control Plane to access discovery and adds the details to a Kubernetes Secret in kind.

Uses variables from [ansible/playbooks/vars/vars.yml]().

`ansible-playbook ansible/playbooks/create-sa-discovery.yml`

### create-sa-registry.yml

This playbook creates a service account in Venafi Control Plane to access the private image registry for Venafi and adds the details to a Kubernetes Secret in kind.

Uses variables from [ansible/playbooks/vars/vars.yml]().

`ansible-playbook ansible/playbooks/create-sa-registry.yml`

### create-sa-firefly.yml

This playbook creates a service account in Venafi Control Plane for Firefly to authenticate with and adds the details to a Kubernetes Secret in kind.

Uses variables from [ansible/playbooks/vars/vars.yml]().

`ansible-playbook ansible/playbooks/create-sa-firefly.yml`

## License
[MIT](LICENSE)