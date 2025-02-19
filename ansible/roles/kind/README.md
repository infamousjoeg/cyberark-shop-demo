kind
=========

Manages Kubernetes-in-Docker cluster deployments.

Requirements
------------

No requirements.

Role Variables
--------------

- `cluster_name` can be set to declare the name of the cluster when deployed
- `worker_nodes` can be set to increase the worker nodes deployed

Dependencies
------------

No dependencies.

Example Playbook
----------------
kind.yml
```yaml
- hosts: "{{ HOSTS | default('localhost') }}"

  roles:
   - ../roles/kind
```

`$ ansible-playbook -i localhost kind.yml --tags "install,create"`

License
-------

MIT

Author Information
------------------

Joe Garcia, Principal DevOps Solutions Engineer, CyberArk
joe dot garcia at cyberark dot com
https://github.com/infamousjoeg
