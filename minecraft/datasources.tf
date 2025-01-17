data "template_cloudinit_config" "bedrock-config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
      #cloud-config
      users:
        - default
        - name: prometheus
          shell: /bin/false
        - name: node_exporter
          shell: /bin/false

      package_update: true

      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - unzip
        - fail2ban

      fs_setup:
        - label: minecraft
          device: /dev/vdc
          filesystem: xfs
          overwrite: false

      mounts:
        - [/dev/vdc, /minecraft]

      # Enable ipv4 forwarding, required on CIS hardened machines
      write_files:
        - path: /etc/sysctl.d/enabled_ipv4_forwarding.conf
          content: |
            net.ipv4.conf.all.forwarding=1
        - path: /tmp/prometheus.yml
          content: |
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
        - path: /etc/systemd/system/prometheus.service
          content: |
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
        - path: /etc/systemd/system/node_exporter.service
          content: |
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
        - path: /etc/systemd/system/minecraft.service
          content: |
            [Unit]
            Description=STACKIT Minecraft Server
            Documentation=https://www.minecraft.net/en-us/download/server/bedrock

            [Service]
            WorkingDirectory=/minecraft
            Type=simple
            ExecStart=/bin/sh -c "LD_LIBRARY_PATH=. ./bedrock_server"
            Restart=on-failure
            RestartSec=5

            [Install]
            WantedBy=multi-user.target

      runcmd:
        - mkdir /etc/prometheus
        - mkdir /var/lib/prometheus
        - curl -sSL https://github.com/prometheus/prometheus/releases/download/v2.27.1/prometheus-2.27.1.linux-amd64.tar.gz | tar -xz
        - cp prometheus-2.27.1.linux-amd64/prometheus /usr/local/bin/
        - cp prometheus-2.27.1.linux-amd64/promtool /usr/local/bin/
        - chown prometheus:prometheus /usr/local/bin/prometheus
        - chown prometheus:prometheus /usr/local/bin/promtool
        - cp -r prometheus-2.27.1.linux-amd64/consoles /etc/prometheus
        - cp -r prometheus-2.27.1.linux-amd64/console_libraries /etc/prometheus
        - chown -R prometheus:prometheus /var/lib/prometheus
        - chown -R prometheus:prometheus /etc/prometheus/consoles
        - chown -R prometheus:prometheus /etc/prometheus/console_libraries
        - mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml
        - chown prometheus:prometheus /etc/prometheus/prometheus.yml
        - systemctl daemon-reload
        - systemctl start prometheus
        - systemctl enable prometheus

        - curl -sSL https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz | tar -xz
        - cp node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin
        - chown node_exporter:node_exporter /usr/local/bin/node_exporter
        - systemctl daemon-reload
        - systemctl start node_exporter
        - systemctl enable node_exporter

        - ufw allow ssh
        - ufw allow 5201
        - ufw allow proto udp to 0.0.0.0/0 port 19132
        - echo [DEFAULT] | sudo tee -a /etc/fail2ban/jail.local
        - echo banaction = ufw | sudo tee -a /etc/fail2ban/jail.local
        - echo [sshd] | sudo tee -a /etc/fail2ban/jail.local
        - echo enabled = true | sudo tee -a /etc/fail2ban/jail.local
        - sudo systemctl restart fail2ban
        - curl -sLSf https://minecraft.azureedge.net/bin-linux/bedrock-server-1.16.221.01.zip > /tmp/bedrock-server.zip
        - unzip -o /tmp/bedrock-server.zip -d /minecraft
        - chmod +x /minecraft/bedrock_server
        - sed -ir "s/^[#]*\s*max-players=.*/max-players=100/" /minecraft/server.properties
        - sed -ir "s/^[#]*\s*server-name=.*/server-name=stackit-minecraft/" /minecraft/server.properties
        - sed -ir "s/^[#]*\s*difficulty=.*/difficulty=normal/" /minecraft/server.properties
        - sed -ir "s/^[#]*\s*level-name=.*/level-name=STACKIT/" /minecraft/server.properties
        - sed -ir "s/^[#]*\s*level-seed=.*/level-seed=stackitminecraftrocks/" /minecraft/server.properties
        - systemctl restart minecraft.service
        - systemctl enable minecraft.service
      EOF
  }
}

data "template_cloudinit_config" "java-config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
      #cloud-config
      users:
        - default
        - name: prometheus
          shell: /bin/false
        - name: node_exporter
          shell: /bin/false

      package_update: true

      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - openjdk-11-jre-headless
        - fail2ban

      fs_setup:
        - label: minecraft
          device: /dev/vdc
          filesystem: xfs
          overwrite: false

      mounts:
        - [/dev/vdc, /minecraft]

      # Enable ipv4 forwarding, required on CIS hardened machines
      write_files:
        - path: /etc/sysctl.d/enabled_ipv4_forwarding.conf
          content: |
            net.ipv4.conf.all.forwarding=1
        - path: /tmp/prometheus.yml
          content: |
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
        - path: /etc/systemd/system/prometheus.service
          content: |
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
        - path: /etc/systemd/system/node_exporter.service
          content: |
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
        - path: /etc/systemd/system/minecraft.service
          content: |
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

      runcmd:
        - mkdir /etc/prometheus
        - mkdir /var/lib/prometheus
        - curl -sSL https://github.com/prometheus/prometheus/releases/download/v2.27.1/prometheus-2.27.1.linux-amd64.tar.gz | tar -xz
        - cp prometheus-2.27.1.linux-amd64/prometheus /usr/local/bin/
        - cp prometheus-2.27.1.linux-amd64/promtool /usr/local/bin/
        - chown prometheus:prometheus /usr/local/bin/prometheus
        - chown prometheus:prometheus /usr/local/bin/promtool
        - cp -r prometheus-2.27.1.linux-amd64/consoles /etc/prometheus
        - cp -r prometheus-2.27.1.linux-amd64/console_libraries /etc/prometheus
        - chown -R prometheus:prometheus /var/lib/prometheus
        - chown -R prometheus:prometheus /etc/prometheus/consoles
        - chown -R prometheus:prometheus /etc/prometheus/console_libraries
        - mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml
        - chown prometheus:prometheus /etc/prometheus/prometheus.yml
        - systemctl daemon-reload
        - systemctl start prometheus
        - systemctl enable prometheus

        - curl -sSL https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz | tar -xz
        - cp node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin
        - chown node_exporter:node_exporter /usr/local/bin/node_exporter
        - systemctl daemon-reload
        - systemctl start node_exporter
        - systemctl enable node_exporter

        - ufw allow ssh
        - ufw allow 5201
        - ufw allow proto udp to 0.0.0.0/0 port 25565
        - echo [DEFAULT] | sudo tee -a /etc/fail2ban/jail.local
        - echo banaction = ufw | sudo tee -a /etc/fail2ban/jail.local
        - echo [sshd] | sudo tee -a /etc/fail2ban/jail.local
        - echo enabled = true | sudo tee -a /etc/fail2ban/jail.local
        - sudo systemctl restart fail2ban
        - curl -sLSf https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar > /minecraft/server.jar
        - echo "eula=true" > /minecraft/eula.txt
        - sed -ir "s/^[#]*\s*max-players=.*/max-players=100/" /minecraft/server.properties
        - sed -ir "s/^[#]*\s*motd=.*/motd=STACKIT Minecraft/" /minecraft/server.properties
        - sed -ir "s/^[#]*\s*difficulty=.*/difficulty=normal:q/" /minecraft/server.properties
        - sed -ir "s/^[#]*\s*level-seed=.*/level-seed=stackitminecraftrocks/" /minecraft/server.properties
        - systemctl restart minecraft.service
        - systemctl enable minecraft.service
      EOF
  }
}