#!/bin/bash
set -e

#-----------------------------------------
# Update and install basic packages
#-----------------------------------------
sudo apt update -y
sudo apt install -y wget tar apt-transport-https software-properties-common

#-----------------------------------------
# Prometheus v3.5.1 installation
#-----------------------------------------

# Create prometheus user if it doesn't exist
id prometheus &>/dev/null || sudo useradd --system --no-create-home --shell /bin/false prometheus

# Download Prometheus
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v3.5.1/prometheus-3.5.1.linux-amd64.tar.gz
tar xvf prometheus-3.5.1.linux-amd64.tar.gz
cd prometheus-3.5.1.linux-amd64

# Move binaries
sudo mv prometheus promtool /usr/local/bin/
sudo chmod +x /usr/local/bin/prometheus /usr/local/bin/promtool

# Move config and create directories
sudo mkdir -p /etc/prometheus /data
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

# Set ownership
sudo chown -R prometheus:prometheus /etc/prometheus /data
sudo chmod 755 /etc/prometheus /data

# Create Prometheus systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

#-----------------------------------------
# Node Exporter v1.10.2 installation
#-----------------------------------------

# Create node_exporter user
id node_exporter &>/dev/null || sudo useradd --system --no-create-home --shell /bin/false node_exporter

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

# Download Node Exporter
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-${ARCH}.tar.gz
tar xvf node_exporter-1.10.2.linux-${ARCH}.tar.gz

# Move binary
sudo mv node_exporter-1.10.2.linux-${ARCH}/node_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter
rm -rf node_exporter-1.10.2.linux-${ARCH}*

# Create Node Exporter systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

#-----------------------------------------
# Grafana installation
#-----------------------------------------
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update -y
sudo apt install -y grafana

# Enable and start Grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo "✅ Prometheus running on port 9090"
echo "✅ Node Exporter running on port 9100"
echo "✅ Grafana running on port 3000"
