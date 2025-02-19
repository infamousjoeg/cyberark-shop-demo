# cyberark-shop-demo <!-- omit in toc -->

A microservice digital store demonstration integrated with CyberArk's Identity Security Platform and Venafi's Cloud Control Plane.

## Table of Contents <!-- omit in toc -->
- [Pre-Requisites](#pre-requisites)
- [Usage](#usage)
- [Ansible kind Role](#ansible-kind-role)
  - [Usage based on Tags](#usage-based-on-tags)
    - [Example Usage](#example-usage)
- [License](#license)

## Pre-Requisites

- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#selecting-an-ansible-package-and-version-to-install)
  - Kubernetes Ansible Module
    - `python3 -m pip install kubernetes`
  - Cryptography Ansible Module
    - `python3 -m pip install cryptography`
- [Venafi Control Plane](https://venafi.com/try-venafi/tls-protect-for-kubernetes/)

## Usage

`./start.sh`

This will prompt a menu for you to choose from:

```plaintext
=============================================
WELCOME TO THE CYBERARK SHOP DEPLOYMENT SETUP
=============================================

This script will execute the following steps:

1. Install & Create kind Cluster
2. Install dependencies (venctl, jq, etc.)
3. Create necessary directories
4. Deploy service accounts
5. Setup Kubernetes namespaces
6. Generate Venafi manifests
7. Deploy Venafi components
8. Setup Venafi Cloud integration
9. Deploy sandbox resources
10. Create Unmanaged Kid in Nginx
11. Create Expiry Eddie - Long Duration Cert
12. Create Cipher-Snake - Bad Key Size
13. Create Ghost-Rider - Orphan Cert
14. Create Phantom-CA & Certificate
15. Setup Istio Service Mesh Apps

Before continuing, please review and modify any necessary variables in:
  → ansible/playbooks/vars/vars.yml

Enter a number to start from a specific section, or press [ENTER] to start from the beginning:
```

## Ansible kind Role

As part of this project, an Ansible Role for managing Kubernetes-in-Docker (KinD) has been developed.

### Usage based on Tags

|Tag|Actions Performed|
|---|---|
|install|Installs docker, kubectl, kind|
|create|Creates kind cluster|
|delete|Deletes kind cluster|
|clean|Clean up docker, kubectl, kind|

#### Example Usage

`ansible-playbook ansible/kind.yml --tags "install, create"`

## License
[MIT](LICENSE)