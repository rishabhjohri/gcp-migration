#!/bin/bash

echo "Installing required dependencies..."
sudo apt install -y curl apt-transport-https ca-certificates gnupg software-properties-common jq git unzip

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

# Install Google Cloud SDK
echo "Adding Google Cloud SDK repository..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null

echo "Importing Google Cloud public key..."
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.gpg > /dev/null
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "Installing Google Cloud SDK..."
sudo apt update && sudo apt install -y google-cloud-cli

# Ensure gcloud is available in PATH
export PATH=$PATH:/usr/lib/google-cloud-sdk/bin
echo 'export PATH=$PATH:/usr/lib/google-cloud-sdk/bin' >> ~/.bashrc
source ~/.bashrc

# Verify gcloud installation
echo "Verifying gcloud installation..."
gcloud --version

# Authenticate and set up GCP
echo "Authenticating with Google Cloud..."
gcloud auth login
gcloud config set project vcc-ass3
gcloud config set compute/zone us-central1-a

echo "Installation completed successfully!"
