# Setting up RKE2 cluster with high availability

This guide will walk you through the process of setting up a RKE2 cluster with Ansible, in high availability mode. RKE2 is Rancher's enterprise-ready next-generation Kubernetes distribution.  It delivers upstream‑compatible Kubernetes with built‑in security hardening, compliance‑friendly by defaults, and a simple operational model that scales cleanly from data center to edge.

## Prerequisites

Before you begin, you will need to have a machine to orchestrate this process. Once you have idenitfied that machine, you'll need to have the following tools installed on the system:

- Ansible 2.21.3
  
The next requirement is the cluster. You will need to obtain 7 machines for the cluster.  Although this guide uses 7, the minimum is 5. You can adjust the number of agent nodes as needed. The specifications of those machines shall be as follows...
- 1 machine for RKE2 registration. Will serve as an external load balancer
  - OS: Rocky Linux 9
  - Memory: 2GB minimum
  - Storage: 10GB minimum
- 3 machines for RKE2 servers
  - OS: Rocky Linux 9
  - Memory: 4GB minimum (8GB recommended)
  - Storage: 30GB minimum
- 3 machines for agents.  The required resources for the agents will ultimately depend on the planned workload.
  - OS: Rocky Linux 9
  - Memory: 8GB (or what to appropiate for the work load)
  - Storage: 100GB (or what to appropiate for the work load)

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

## Installation

To set up RKE2 using Ansible playbooks, follow these steps:

1. Edit the 'inventory.ini' file:
   
    With the IP addresses of the target cluster host in hand, update the inventory file.  Replace the IP addresses in the file with the IP addresses of your host. If needed, you may add more workers to the workers section.  However, in order to ensure high availability and robustness of the cluster, there must be 3 masters nodes.

2. Create certificates for use by the RKE2 registration server:

    The RKE2 registration server is the way a user will interact with the cluster.  The external communication requires TLS certificates.  Existing certificates can be used, however if self signed certificates are required for testing/development reasons, use the following commands.

    ```
    bash create-certs.sh
    ```

    This command should produce two certificate files in the 'certs' folder.

3. Download RKE2 artifact for "air gapped" installations:
   
    Some environments present challenges during installation due to internet restrictions.  Setting up a RKE2 cluster involves a lot of downloads and communication with internet servers. A solution for installing in internet restricted environments is to download the artifacts prior to installation and then copy them to the nodes. 

    ```
    bash download-artifacts.sh
    ```
    This command should produce a 'local_artifacts' folder containing RKE2 artifacts to distribute to the cluster's nodes.  This should help when installing in environments in which external internet access is limited

4. Start the Keycloak application:

    ```
    docker compose up -d
    ```

   This command will start the Keycloak application using the `docker-compose.yml` file.  It will take a few minutes to complete the start up as the images are being downloaded.

5. Access the Keycloak web interface:

   Open a web browser and navigate to `https://<ENV_KC_HOSTNAME>:8443/admin`<br>
   ... where <ENV_KC_HOSTNAME> is the value assigned in the .env file.

    You should see the Keycloak login page.  Edge, Brave, and Chromium browsers have been verified to work.

   Note: The first time you access the web interface, you'll need to accept the self-signed SSL certificate.

6. Log in to the Keycloak web interface:

   Use the default administrator credentials to log in:

   - Username: admin
   - Password: admin

## Testing the installation

To verify the Keycloak instance is functional, follow these steps:

1. Now that you are signed in as an administrator, import the test realm included in this repository.
   - Expand the realm list in the upper left and select the 'Create Realm' button.
   - In the form, browse to the file 'testing/test.realm' and select the 'Create' button.

   A realm named 'test' should now exist in the realm list.

2. Start a session using the included credential file.
   - Create a new session and grab a token from the Keycloak instance by entering the following text at the command prompt.
    ```
    sh testing/keycloak-login.sh testing/keycloak-cred.json
    ```
   - The result should be a json object that is similar to the following json.
    ```
    {"access_token":"YUJ5anFzIn0.eyJleHAiOjE3MzE3MDgxMDksImlY29tIn0.nvDP5HJ-oPZRjSlEBxHyY37qzf39wykU3VapULtcA","expires_in":300,"refresh_expires_in":1800,"refresh_token":"<data>","token_type":"Bearer","not-before-policy":0,"session_state":"27aba1a8-eb77-424b-95d5-96010432e3e0","scope":"profile email"}
    ```
If these two steps were successful, the Keycloak instance is functioning.  Visit the [Securing Apps](https://www.keycloak.org/securing-apps/overview) resource to get detailed instructions on configuring the Keycloak to secure you particular application or service.


------------------------------------------------------------------
--------------------------------------------------------------------


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
