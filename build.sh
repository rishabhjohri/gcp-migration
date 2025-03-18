#!/bin/bash

echo "Setting up the Node.js frontend..."
mkdir -p ~/cpu-monitor/frontend
cd ~/cpu-monitor/frontend
npm init -y
npm install express socket.io

# Creating server.js
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

http.listen(3000, () => {
    console.log('Server running on port 3000');
});
EOF

mkdir -p public

# Creating index.html for frontend
cat <<EOF > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CPU Monitor</title>
    <script src="/socket.io/socket.io.js"></script>
</head>
<body>
    <h1>CPU Utilization Monitoring</h1>
    <button onclick="triggerStressTest()">Launch Computation</button>
    <button onclick="gotoGCP()">Go to Google Cloud Console</button>

    <script>
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

echo "Node.js frontend setup completed!"

# Creating stress_test.sh script
cat <<EOF > ~/cpu-monitor/stress_test.sh
#!/bin/bash
echo "Starting CPU Stress Test..."
stress --cpu 4 --timeout 60
EOF
chmod +x ~/cpu-monitor/stress_test.sh

# Creating monitor_cpu.sh script
cat <<EOF > ~/cpu-monitor/monitor_cpu.sh
#!/bin/bash

THRESHOLD=75
INSTANCE_NAME="stress-test-instance"
ZONE="us-central1-a"

while true; do
    CPU_USAGE=\$(top -bn1 | grep "Cpu(s)" | awk '{print \$2 + \$4}' | cut -d. -f1)

    echo "Current CPU Usage: \$CPU_USAGE%"

    if [ "\$CPU_USAGE" -gt "\$THRESHOLD" ]; then
        echo "CPU usage exceeded \$THRESHOLD%. Checking for cloud VM..."
        
        INSTANCE_EXISTS=\$(gcloud compute instances list --filter="name=\${INSTANCE_NAME}" --format="value(name)")

        if [ -z "\$INSTANCE_EXISTS" ]; then
            echo "Creating cloud VM..."
            gcloud compute instances create "\$INSTANCE_NAME" --zone="\$ZONE" --machine-type=e2-medium --image-family=debian-11 --image-project=debian-cloud --metadata=startup-script='sudo apt update && sudo apt install -y stress'
        fi

        echo "Migrating stress test to cloud..."
        scp ~/cpu-monitor/stress_test.sh username@"\${INSTANCE_NAME}":/home/username/
        ssh username@"\${INSTANCE_NAME}" "bash /home/username/stress_test.sh"
    fi

    sleep 5
done
EOF
chmod +x ~/cpu-monitor/monitor_cpu.sh

echo "Backend scripts created successfully!"
