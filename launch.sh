#!/bin/bash

# Authenticate GCP
echo "Authenticating Google Cloud SDK..."
gcloud auth login
gcloud config set project vcc-ass3

# Start CPU monitoring script
echo "Starting CPU Monitoring..."
bash ~/cpu-monitor/monitor_cpu.sh &

# Start the frontend
echo "Launching Node.js frontend..."
cd ~/cpu-monitor/frontend
node server.js &
