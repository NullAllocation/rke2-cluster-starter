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
    sudo firewall-cmd --permanent --add-port=80/tcp --add-port=443/tcp
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
        environment:
          - HTTP_PROXY=http://ip:port
          - HTTPS_PROXY=http://ip:port
          - NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.local
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
    This command will start the Rancher application using the docker-compose.yml file. It will take a few minutes to complete the start up as the images are being downloaded.

4. Upon visiting the Rancher UI for the first time, you must enter the bootstrap password automatically assigned during installation.  To reveal this password you must search the logs for the keyword "Bootstrap Password".
   
    ```
    sudo docker logs rancher-server 2>&1 | grep "Bootstrap Password:"   
    ```    
    Enter the initial bootstrap password and choose a new password to secure the application.
