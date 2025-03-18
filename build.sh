#!/bin/bash
set -e  # Exit on any error

echo "Setting up the Node.js frontend..."
NODE_DIR="$HOME/cpu-monitor/frontend"
SCRIPT_DIR="$HOME/cpu-monitor"

# Create frontend directory and initialize Node.js project
mkdir -p "$NODE_DIR"
cd "$NODE_DIR"
npm init -y
npm install express socket.io chart.js

# Creating server.js with real-time CPU monitoring
cat <<EOF > server.js
const express = require('express');
const { exec } = require('child_process');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);

app.use(express.static('public'));

app.get('/stress-test', (req, res) => {
    exec('bash ../stress_test.sh', (error, stdout, stderr) => {
        if (error) {
            console.error(\`Error: \${error.message}\`);
            return res.status(500).send('Error running stress test');
        }
        res.send('Stress test triggered');
    });
});

app.get('/gcp-console', (req, res) => {
    res.redirect('https://console.cloud.google.com');
});

// Function to get CPU usage
function getCpuUsage() {
    return new Promise((resolve) => {
        exec("top -bn1 | grep 'Cpu(s)' | awk '{print \$2 + \$4}'", (error, stdout, stderr) => {
            if (error) {
                console.error(\`Error fetching CPU usage: \${stderr}\`);
                resolve(0);
            } else {
                resolve(parseFloat(stdout));
            }
        });
    });
}

// Emit CPU utilization data every second
setInterval(async () => {
    const cpuUsage = await getCpuUsage();
    io.emit('cpuData', cpuUsage);
}, 1000);

http.listen(3000, '0.0.0.0', () => {
    console.log('Server running on http://localhost:3000');
});
EOF

mkdir -p public

# Creating index.html with real-time CPU graph
cat <<EOF > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CPU Utilization Monitoring</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="/socket.io/socket.io.js"></script>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; }
        canvas { max-width: 600px; margin: 20px auto; }
        button { padding: 10px 20px; margin: 10px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>CPU Utilization Monitoring</h1>
    <canvas id="cpuChart"></canvas>
    <button onclick="triggerStressTest()">Launch Computation</button>
    <button onclick="gotoGCP()">Go to Google Cloud Console</button>

    <script>
        const ctx = document.getElementById('cpuChart').getContext('2d');
        const cpuChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'CPU Utilization (%)',
                    data: [],
                    borderColor: 'blue',
                    borderWidth: 2,
                    fill: false
                }]
            },
            options: {
                scales: {
                    y: { beginAtZero: true, max: 100 }
                }
            }
        });

        const socket = io();
        socket.on('cpuData', (cpuUsage) => {
            if (cpuChart.data.labels.length > 30) {
                cpuChart.data.labels.shift();
                cpuChart.data.datasets[0].data.shift();
            }
            const currentTime = new Date().toLocaleTimeString();
            cpuChart.data.labels.push(currentTime);
            cpuChart.data.datasets[0].data.push(cpuUsage);
            cpuChart.update();
        });

        function triggerStressTest() {
            fetch('/stress-test')
                .then(response => response.text())
                .then(data => alert(data));
        }

        function gotoGCP() {
            window.location.href = '/gcp-console';
        }
    </script>
</body>
</html>
EOF

echo "✅ Node.js frontend setup completed!"

# Creating stress_test.sh script
cat <<EOF > "$SCRIPT_DIR/stress_test.sh"
#!/bin/bash
echo "Starting CPU Stress Test..."
stress --cpu 4 --timeout 60
EOF
chmod +x "$SCRIPT_DIR/stress_test.sh"

# Creating monitor_cpu.sh script
cat <<EOF > "$SCRIPT_DIR/monitor_cpu.sh"
#!/bin/bash

THRESHOLD=75
INSTANCE_NAME="stress-test-instance"
ZONE="us-central1-a"

while true; do
    CPU_USAGE=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}' | cut -d. -f1)

    echo "Current CPU Usage: \$CPU_USAGE%"

    if [ "\$CPU_USAGE" -gt "\$THRESHOLD" ]; then
        echo "🔥 CPU usage exceeded \$THRESHOLD%. Checking for cloud VM..."
        
        INSTANCE_EXISTS=\$(gcloud compute instances list --filter="name=\$INSTANCE_NAME" --format="value(name)")

        if [[ -z "\$INSTANCE_EXISTS" ]]; then
            echo "🚀 Creating cloud VM..."
            gcloud compute instances create "\$INSTANCE_NAME" --zone="\$ZONE" --machine-type=e2-medium --image-family=debian-11 --image-project=debian-cloud --metadata=startup-script='sudo apt update && sudo apt install -y stress'
        fi

        echo "🌍 Getting external IP of the cloud VM..."
        EXTERNAL_IP=\$(gcloud compute instances describe "\$INSTANCE_NAME" --zone="\$ZONE" --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

        if [[ -z "\$EXTERNAL_IP" ]]; then
            echo "❌ Failed to retrieve external IP. Exiting..."
            exit 1
        fi

        echo "🔄 Migrating stress test to cloud (\$EXTERNAL_IP)..."

        # Ensure SSH key is set up for access
        gcloud compute config-ssh

        # Copy and execute stress test remotely
        gcloud compute scp "$SCRIPT_DIR/stress_test.sh" "\$INSTANCE_NAME:~/"
        gcloud compute ssh "\$INSTANCE_NAME" --zone="\$ZONE" --command="bash ~/stress_test.sh"
    fi

    sleep 5
done
EOF
chmod +x "$SCRIPT_DIR/monitor_cpu.sh"

echo "✅ Backend scripts created successfully!"
