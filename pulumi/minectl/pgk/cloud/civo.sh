#!/bin/bash

tee /tmp/server.properties <<EOF
#Minecraft server properties
broadcast-rcon-to-ops=true
view-distance=10
enable-jmx-monitoring=false
server-ip=
resource-pack-prompt=
rcon.port=25575
gamemode=survival
server-port=25565
allow-nether=true
enable-command-block=false
enable-rcon=false
sync-chunk-writes=true
enable-query=false
op-permission-level=4
prevent-proxy-connections=false
resource-pack=
entity-broadcast-range-percentage=100
level-name=world
rcon.password=
player-idle-timeout=0
motd=A Minecraft Server
query.port=25565
force-gamemode=false
rate-limit=0
hardcore=false
white-list=false
broadcast-console-to-ops=true
pvp=true
spawn-npcs=true
spawn-animals=true
snooper-enabled=true
difficulty=easy
function-permission-level=2
network-compression-threshold=256
text-filtering-config=
require-resource-pack=false
spawn-monsters=true
max-tick-time=60000
enforce-whitelist=false
use-native-transport=true
max-players=20
resource-pack-sha1=
spawn-protection=16
online-mode=true
enable-status=true
allow-flight=false
max-world-size=29999984
EOF

tee /tmp/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
EOF
tee /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
tee /etc/systemd/system/minecraft.service <<EOF
[Unit]
Description=STACKIT Minecraft Server
Documentation=https://www.minecraft.net/en-us/download/server

[Service]
WorkingDirectory=/minecraft
Type=simple
ExecStart=/usr/bin/java -Xmx2G -Xms2G -jar server.jar nogui
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
apt-get install -y apt-transport-https ca-certificates curl openjdk-16-jre-headless fail2ban

useradd prometheus -s /bin/false
useradd node_exporter -s /bin/false


mkdir /etc/prometheus
mkdir /var/lib/prometheus
curl -sSL https://github.com/prometheus/prometheus/releases/download/v2.27.1/prometheus-2.27.1.linux-amd64.tar.gz | tar -xz
cp prometheus-2.27.1.linux-amd64/prometheus /usr/local/bin/
cp prometheus-2.27.1.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
cp -r prometheus-2.27.1.linux-amd64/consoles /etc/prometheus
cp -r prometheus-2.27.1.linux-amd64/console_libraries /etc/prometheus
chown -R prometheus:prometheus /var/lib/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml
chown prometheus:prometheus /etc/prometheus/prometheus.yml
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

curl -sSL https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz | tar -xz
cp node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin
chown node_exporter:node_exporter /usr/local/bin/node_exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

ufw allow ssh
ufw allow 5201
ufw allow proto udp to 0.0.0.0/0 port 25565
echo [DEFAULT] | sudo tee -a /etc/fail2ban/jail.local
echo banaction = ufw | sudo tee -a /etc/fail2ban/jail.local
echo [sshd] | sudo tee -a /etc/fail2ban/jail.local
echo enabled = true | sudo tee -a /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
mkdir /minecraft
curl -sLSf https://launcher.mojang.com/v1/objects/0a269b5f2c5b93b1712d0f5dc43b6182b9ab254e/server.jar > /minecraft/server.jar
echo "eula=true" > /minecraft/eula.txt
mv /tmp/server.properties /minecraft/server.properties
sed -ir "s/^[#]*\s*max-players=.*/max-players=100/" /minecraft/server.properties
sed -ir "s/^[#]*\s*motd=.*/motd=STACKIT Minecraft/" /minecraft/server.properties
sed -ir "s/^[#]*\s*difficulty=.*/difficulty=normal:q/" /minecraft/server.properties
sed -ir "s/^[#]*\s*level-seed=.*/level-seed=stackitminecraftrocks/" /minecraft/server.properties
systemctl restart minecraft.service
systemctl enable minecraft.service