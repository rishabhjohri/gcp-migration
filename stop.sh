#!/bin/bash

echo "Stopping CPU Monitoring Process..."
pkill -f monitor_cpu.sh

echo "Stopping Stress Test (if running)..."
pkill -f stress_test.sh
pkill -f stress

echo "Stopping Node.js Frontend Server..."
pkill -f node

echo "Stopping Any SSH Sessions..."
pkill -f ssh

echo "All processes stopped successfully!"
