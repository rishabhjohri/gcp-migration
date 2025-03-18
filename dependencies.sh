#!/bin/bash

echo "Installing required dependencies..."
sudo apt install -y curl gnupg ca-certificates lsb-release apt-transport-https software-properties-common jq git unzip

# Install Node.js 20
echo "Adding Node.js 20 repository..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
echo "Installing Node.js..."
sudo apt install -y nodejs
echo "Verifying Node.js installation..."
node -v
npm -v

# Install htop (CPU Monitoring Tool)
echo "Installing htop..."
sudo apt install -y htop

# Install stress (For CPU Load Testing)
echo "Installing stress tool..."
sudo apt install -y stress

# Install Google Cloud SDK (Fixed Key Issue)
echo "Adding Google Cloud SDK repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /etc/apt/keyrings/cloud.google.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null

echo "Installing Google Cloud SDK..."
sudo apt update && sudo apt install -y google-cloud-sdk

# Ensure gcloud is available in PATH
export PATH=$PATH:/usr/lib/google-cloud-sdk/bin
echo 'export PATH=$PATH:/usr/lib/google-cloud-sdk/bin' >> ~/.bashrc
source ~/.bashrc

# Verify gcloud installation
echo "Verifying gcloud installation..."
gcloud --version

# Install Google Cloud Compute Engine API components
echo "Installing gcloud compute components..."
gcloud components install beta compute

echo "Installation completed successfully!"
echo "Ensure you have initialized gcloud with 'gcloud init' and configured the project."
