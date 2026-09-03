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

![RKE2 Cluster](images/RKE2_Cluster.webp)

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

    This command should produce a 'local_artifacts' folder containing RKE2 artifacts to distribute to the cluster's nodes.  This should help when installing in environments in which external internet access is limited.

4. Prepare the cluster nodes for Ansible:

    Ansible will need to execute commands against the cluster nodes.  We setup certificate-based logins using the host key of the ansible controller host, therefore logins from the ansible controller host are password-less.  In addition, the host file is modified to reference all cluster nodes by names and IP addresses.

    ```
    bash setup-nodes.sh -i inventory.ini -p <passwd>
    ```

5. Run the playbook:

    Ansible will need to execute commands against the cluster nodes.

    ```
    ansible-playbook playbook.yaml -i inventory.ini
    ```

   Note: The first time you access the web interface, you'll need to accept the self-signed SSL certificate.

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
