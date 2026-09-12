# Setting up Rancher to manage RKE2 clusters

Rancher acts as a single control plane dashboard to provision, import, and monitor RKE2 (Rancher Kubernetes Engine 2) clusters seamlessly.

## Prerequisites

Before you begin, you'll need to have the following installed on your system:

- Docker
- Docker Compose

Although Docker is preferred, Podman and Podman Compose should work as alternatives.

To install docker, run the following commands...
  ```
  sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
  sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl start docker
  sudo systemctl enable docker
  ```

## Rancher Installation

To set up Rancher using Docker Compose, follow these steps:

1. Open ports to allow access to the services.

    ```
    sudo firewall-cmd --permanent --add-port=80/tcp --add-port=8443/tcp
    sudo firewall-cmd --reload
    ```

2. Create a docker compose file.<br><br>
    Create a file named `docker-compose.yml` with the following content...
    ```
    services:
      rancher:
        image: rancher/rancher:latest
        container_name: rancher-server
        restart: unless-stopped
        privileged: true
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - rancher_data:/var/lib/rancher

    volumes:
      rancher_data:
        driver: local
    ``` 

3. Start the Rancher app.

    ```
    docker compose up -d
    ```

4. khkkhk
   
    ```
    sudo docker logs <container_id_or_name> 2>&1 | grep "Bootstrap password:"   
    ```

    This command will start the Rancher application using the docker-compose.yml file. It will take a few minutes to complete the start up as the images are being downloaded.
