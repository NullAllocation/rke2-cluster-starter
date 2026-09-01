# Setting up a RKE2 cluster with high availability

This guide will walk you through the process of setting up a RKE2 cluster with Ansible, in high availability mode. RKE2 is Rancher's enterprise-ready next-generation Kubernetes distribution.  <br>These instructions were developed with Rocky 9 using the "minimum server" installation option.  As these cluster's nodes are scoped to RKE2 functionally, there is no need to use the other installation options that are intended for general purpose use and are bloated.

## Prerequisites

Before you begin, you will need a machine to orchestrate the cluster installation process.  That machine will be referred to as the controller in the guide.  Once you have identified that machine, you'll need to have the following tools installed on it:

- python3 and python3-pip
  - netaddr
- ansible
- kubectl
- git (to clone this repository)

Executing the following commands will install the needed tools on the controller...
  ```
  sudo dnf install -y epel-release createrepo
  sudo dnf install -y python3 python3-pip
  sudo dnf install -y ansible git
  pip3 install netaddr

  cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
  [kubernetes]
  name=Kubernetes
  baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
  enabled=1
  gpgcheck=1
  gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
  EOF
  sudo dnf install -y kubectl --disableexcludes=kubernetes  
  ``` 
<br>The next requirement is the cluster. This guide will use seven nodes so you will need to obtain 7 machines for the cluster.  The specifications of those machines shall be as follows...
- 1 machine for RKE2 gateway. This machine will load balance access across the multiple nodes.
  - OS: Rocky Linux 9
  - Memory: 2GB minimum
  - Storage: 10GB minimum
- 3 machines for RKE2 control plane nodes
  - OS: Rocky Linux 9
  - Memory: 4GB minimum (8GB recommended)
  - Storage: 30GB minimum
- 3 machines for agent workers.  The required resources for the agents will ultimately depend on the planned workload.
  - OS: Rocky Linux 9
  - Memory: 8GB (or what is appropriate for the intended workload)
  - Storage: 100GB (or what is appropriate for the intended workload)

**Note:**    Although this guide uses 7 machines, the minimum is 5 (1 gateway, 3 masters and 1 agent). You can adjust the number of agent nodes as needed.  In order to adjust the size of your cluster, just edit the `inventory.ini` file to add/remove resources in the `workers` section.<br><br>
**Note:**    It is recommended to keep the root password the same across all cluster machines until after the RKE2 installation.  For production environments, choose a strong password for these machines.

#### Example Topology:

![RKE2 Cluster](images/RKE2_Cluster.webp)

## Installation

To set up a RKE2 cluster using Ansible playbooks, follow these steps:

1. Edit the 'inventory.ini' file:
   
    With the IP addresses of the target cluster host in hand, update the inventory file.  Replace the IP addresses in the file with the IP addresses of your host. If needed, you may add more host machines to the `workers` section.  However, in order to ensure high availability and robustness of the cluster, there must be at least 3 masters nodes.

    ```
    vi inventory.ini
    ```

2. Create certificates for use by the hosted applications:

    In addition to handling the API traffic, the RKE2 gateway server will handle interactions with hosted applications.  Secured web traffic will require TLS certificates.  Existing certificates can be used, however if self signed certificates are required for testing/development reasons, use the following commands.

    ```
    bash create-certs.sh
    ```

    This command should produce two certificate files in the 'certs' folder. If you already have certificates for your applications, replace the generated files with your certificate files... changing the names to match.<br><br>
**Note:** The certificates can also be changed after the cluster is created by logging into the gateway server and editing the haproxy configuration file.

3. Download RKE2 artifacts for "air-gapped" installations:
   
    Some environments present challenges during installation due to internet restrictions.  Setting up a RKE2 cluster involves a lot of downloads and communication with internet servers. A solution for installing in internet restricted environments is to download the artifacts to the controller prior to installation, and then copy them to the internet restricted nodes. 

    ```
    bash download-artifacts.sh
    ```

    This command should produce a 'local_artifacts' folder containing RKE2 artifacts to distribute to the cluster's nodes.  This should help when installing in environments in which external internet access is limited.

4. Prepare the cluster nodes for Ansible:

    Ansible will need to execute commands against the cluster nodes.  We setup certificate-based logins using the host key of the controller host, therefore logins from the controller are password-less.  The key that Ansible will use is specified by the `ansible_ssh_private_key_file` property in the `inventory.ini` file.  If the specified key does not exist, it will be created. 

    ```
    bash setup-nodes.sh -i inventory.ini -p <root password of the machines>
    ```
    **Note:** The `ansible_ssh_private_key_file` property's default value of `/root/.ssh/id_ed25519` is standard and works well, so there is usually no need to change it.
5. Run the playbook:

    ```
    ansible-playbook playbook.yaml -i inventory.ini
    ```

   The total running time of this playbook varies based on the infrastructure.

## Testing the RKE2 cluster

To verify the RKE2 cluster is functional, follow these steps:

1. Check that control plane components and worker nodes are in a `Ready` state.

    ```
    # Check node status
    kubectl --kubeconfig ~/rke2.yaml get nodes -o wide

    # Check system pods (coredns, metrics-server, rke2-coredns, etc.)
    kubectl --kubeconfig ~/rke2.yaml get pods -A -o wide

    # Check control plane components
    kubectl --kubeconfig ~/rke2.yaml get componentstatuses
    ```

2. Deploy a simple Nginx application to test pod scheduling, service exposure, and internal DNS.

    ```
    # Create a namespace and deploy Nginx
    kubectl --kubeconfig ~/rke2.yaml create namespace test-app
    kubectl --kubeconfig ~/rke2.yaml create deployment nginx --image=nginx -n test-app
    kubectl --kubeconfig ~/rke2.yaml expose deployment nginx --port=80 --type=ClusterIP -n test-app

    # Verify pods are running
    kubectl --kubeconfig ~/rke2.yaml get pods -n test-app

    # Test internal connectivity from another pod
    kubectl --kubeconfig ~/rke2.yaml run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -n test-app -- \
      curl -s http://nginx.test-app.svc.cluster.local | head -n 5
    ```
