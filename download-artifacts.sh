#!/bin/bash

# Set the RKE2 version to download
RKE2_VERSION="v1.34.6+rke2r3"
ARTIFACTS_PATH="local_artifacts"

# Create a directory for artifacts
mkdir -p $ARTIFACTS_PATH && cd $ARTIFACTS_PATH

# Download the RKE2 installation script
curl -sfL https://get.rke2.io -o rke2.sh
chmod +x rke2.sh

# Download RKE2 binaries and checksum
# For amd64 (x86_64) systems:
curl -LO https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/rke2.linux-amd64.tar.gz
curl -LO https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/sha256sum-amd64.txt

# Download the RKE2 images tarball
# This includes all container images needed by RKE2
curl -LO https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/rke2-images.linux-amd64.tar.zst
curl -LO https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/rke2-images-calico.linux-amd64.tar.zst
curl -LO https://github.com/rancher/rke2/releases/download/${RKE2_VERSION}/rke2-images-multus.linux-amd64.tar.zst

# Verify checksum
sha256sum -c sha256sum-amd64.txt --ignore-missing

echo "All artifacts downloaded successfully"
