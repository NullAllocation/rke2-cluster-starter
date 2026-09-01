### RKE2 Cluster Installation With Ansible:

**RKE2 is Rancher's enterprise-ready next-generation Kubernetes distribution.It delivers upstream‑compatible Kubernetes with built‑in security hardening, compliance‑friendly by defaults, and a simple operational model that scales cleanly from data center to edge.**

#### Example Topology:

| Name      | IP Address         |
|-----------|--------------------|
| fra-node  | 192.168.122.100    |
| Master-01 | 192.168.122.101    |
| Master-02 | 192.168.122.102    |
| Master-03 | 192.168.122.103    |
| Worker-01 | 192.168.122.104    |
| Worker-02 | 192.168.122.105    |
| Worker-03 | 192.168.122.106    |

---

#### Pre-requisits:

- 6 Ubuntu 24.04 LTS on all nodes [ 3 servers and 3 agent nodes]
- One fixed registration address: 192.168.122.100 in front of the servers.


#### Copy ssh keys to master and worker nodes:

```sh
{
declare -a NODES=(192.168.122.X 192.168.122.Y 192.168.122.Z 192.168.122.X 192.168.122.Y 192.168.122.Z)

for node in ${NODES[@]}; do
  ssh-copy-id -i ~/.ssh/id_ed25519 root@$node
done
}
```

apt install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt -install -y ansible
apt install -y ansible
ansible --version
ssh-keygen

ansible-galaxy role install lablabs.rke2


#### Install RKE2 deployment role:

```sh
ansible-galaxy install lablabs.rke2
```

#### Troubelshooting:

**If the playbbok execution hangs at 'Wait for remaining nodes to be ready', check if rke2 is installed on all machines, if not the rke2.sh script may not be running. To fix this, edit the ~/.ansible/roles/lablabs.rke2/tasks/rke2.yml by removing the Check RKE2 version task and replacing it with:**

```sh
- name: Check rke2 bin exists
  ansible.builtin.stat:
    path: "{{ rke2_bin_path }}"
  register: rke2_exists

- name: Check RKE2 version
  ansible.builtin.shell: |
    set -o pipefail
    {{ rke2_bin_path }} --version | grep -E "rke2 version" | awk '{print $3}'
  args:
    executable: /bin/bash
  changed_when: false
  register: installed_rke2_version
  when: rke2_exists.stat.exists
```
