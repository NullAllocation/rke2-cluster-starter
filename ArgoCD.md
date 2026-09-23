# Installing ArgoCD into the RKE2 clusters

Argo CD continuously monitors running applications and compares the current, live state against the desired target state (as specified in the Git repo). This guide will provide instructions to get ArgoCD installed on to a kubernetes cluster.

## Prerequisites

Before you begin, you'll need to have access to a functional kubernetes cluster.

## ArgoCD Installation

To install ArgoCD on to the cluster, follow these steps:

1. Install ArgoCD into the cluster.<br><br>
    To install ArgoCD, you must first create a namespace to operate from.  This new namespace is where all Argo CD services and application resources will reside.  The installation of Argo CD is completed by applying the official manifests from the stable branch.
    ```
    kubectl --kubeconfig <path to cluster config yaml> create namespace argocd
    kubectl --kubeconfig <path to cluster config yaml> apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```
    **Note:** Replace `<path to cluster config yaml>` with the configuration of the target cluster. The `--kubeconfig` flag is used to allow easy switching between multiple clusters managed in one session.

2. Retrieve the initial password for the 'admin' user.<br><br>
    You can extract and decode the password directly from the Kubernetes secret using kubectl...
    ```
    kubectl --kubeconfig <path to cluster config yaml> -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ``` 
    **Note:** This password will be needed to login (Step 4).<br>
    **Note:** Replace `<path to cluster config yaml>` with the configuration of the target cluster. The `--kubeconfig` flag is used to allow easy switching between multiple clusters managed in one session.

3. Make the ArgoCD UI accessible<br><br>
    Using the `kubectl port-forward` command, we can connect to the ArgoCD's API server without exposing the service.
    ```
    kubectl --kubeconfig <path to cluster config yaml> port-forward svc/argocd-server -n argocd 8080:443
    ```
    The ArgoCD's API server can then be accessed using https://localhost:8080<br><br>
    **Note:** Replace `<path to cluster config yaml>` with the configuration of the target cluster. The `--kubeconfig` flag is used to allow easy switching between multiple clusters managed in one session.

4. Log in and change the admin password<br><br>
    Upon visiting the ArgoCD UI for the first time, you must enter the initial password that was automatically assigned during installation (Step 2).  For the 'admin' user, enter the initial password and then choose a new password to secure the application.

ArgoCD should now be ready to use.
