#!/usr/bin/env bash
# System updates
sudo dnf update -y

# Install docker
sudo dnf install -y docker

# Run and make Docker run on every system start
sudo systemctl start docker
sudo systemctl enable docker

sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Prometheus configuration
sudo mkdir -p /etc/prometheus
sudo tee /etc/prometheus/prometheus.yml > /dev/null << 'PROMEOF'
${prometheus_config}
PROMEOF

# Grafana provisioning
sudo mkdir -p /etc/grafana/provisioning/datasources
sudo mkdir -p /etc/grafana/provisioning/dashboards

sudo tee /etc/grafana/provisioning/datasources/datasource.yaml > /dev/null << 'EOF'
${grafana_datasource}
EOF

sudo tee /etc/grafana/provisioning/dashboards/dashboard.yaml > /dev/null << 'EOF'
${grafana_dashboard_provider}
EOF

# Copy docker-compose and start
sudo tee /home/ec2-user/docker-compose.yaml > /dev/null << 'EOF'
${docker_compose}
EOF

cd /home/ec2-user && sudo docker compose up -d

