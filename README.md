# cyberark-shop-demo <!-- omit in toc -->

A microservice digital store demonstration integrated with CyberArk's Identity Security Platform and Venafi's Cloud Control Plane.

## Table of Contents <!-- omit in toc -->
- [Quick Start](#quick-start)
  - [Optional](#optional)
    - [Load Docker images](#load-docker-images)
    - [Remove kind, kubectl, docker](#remove-kind-kubectl-docker)
- [Ansible kind Role](#ansible-kind-role)
  - [Usage based on Tags](#usage-based-on-tags)
    - [Example Usage](#example-usage)
- [License](#license)

## Quick Start

1. `brew install ansible`
2. `ansible-playbook ansible/kind.yml --tags "install, create"`
3. `docker ps`
4. `ansible-playbook ansible/kind.yml --tags "delete"`

### Optional

#### Load Docker images

`ansible-playbook ansible/kind.yml --tags "load"`

#### Remove kind, kubectl, docker

`ansible-playbook ansible/kind.yml --tags "clean"`

## Ansible kind Role

### Usage based on Tags

|Tag|Actions Performed|
|---|---|
|install|Installs docker, kubectl, kind|
|create|Creates kind cluster|
|load|Load docker_images from [vars](roles/kind/vars/main.yml)|
|delete|Deletes kind cluster|
|clean|Clean up docker, kubectl, kind|

#### Example Usage

`ansible-playbook ansible/kind.yml --tags "install, create, load"`

## License
[MIT](LICENSE)