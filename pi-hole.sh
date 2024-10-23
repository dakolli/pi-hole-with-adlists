#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install docker if not installed
if ! command -v docker &> /dev/null; then
    apt-get update
    apt-get install -y docker.io
fi

# Install pip3 and pihole5-list-tool
apt-get install -y python3-pip
pip3 install pihole5-list-tool --upgrade

# Install expect
apt-get install -y expect

# Stop and disable systemd-resolved to free up port 53
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Configure NetworkManager
if [ -f "/etc/NetworkManager/NetworkManager.conf" ]; then
    sed -i 's/#dns=default/dns=default/' /etc/NetworkManager/NetworkManager.conf
    systemctl restart NetworkManager
fi

# Create directory for Pi-hole
PIHOLE_DIR="/opt/pihole"
mkdir -p "$PIHOLE_DIR"
cd "$PIHOLE_DIR"

# Generate random password
PIHOLE_PASSWORD=$(openssl rand -base64 24)

# Create docker-compose.yml
cat > docker-compose.yml <<EOF
version: "3"
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    environment:
      TZ: 'America/Chicago'
      WEBPASSWORD: ${PIHOLE_PASSWORD}
      FTLCONF_LOCAL_IPV4: '0.0.0.0'
      PIHOLE_DNS_: '9.9.9.9;149.112.112.112'
      DNSSEC: 'true'
      DNSMASQ_LISTENING: 'all'
      DNSMASQ_USER: 'root'
    volumes:
      - './etc-pihole:/etc/pihole'
    cap_add:
      - NET_ADMIN
      - NET_BIND_SERVICE
    restart: unless-stopped
EOF

# Stop any existing container
docker compose down -v 2>/dev/null || true
rm -rf "${PIHOLE_DIR}/etc-pihole"
mkdir -p "${PIHOLE_DIR}/etc-pihole"

# Start Pi-hole
docker compose up -d

# Wait for container to start and DNS to be running
echo "Waiting for Pi-hole to start..."
for i in $(seq 1 30); do
    if docker exec pihole pihole status | grep -q "FTL is listening on port 53"; then
        echo "Pi-hole is running with DNS service active!"
        break
    fi
    sleep 3
    echo -n "."
done

# Save password
echo "$PIHOLE_PASSWORD" > ./password.txt
chmod 600 ./password.txt

echo "Pi-hole setup complete!"
echo "Admin interface: http://localhost/admin"
echo "Password: $PIHOLE_PASSWORD"
echo "Password has been saved to ./password.txt"

# Create expect script to automate pihole5-list-tool
cat > setup_lists.exp <<'EOF'
#!/usr/bin/expect -f
set timeout -1

spawn pihole5-list-tool
expect "Use Docker-ized config?"
send "y\r"
expect "Options:"
send "1\r"
expect "Blocklist action:"
send "a\r"
expect "Where are the block lists coming from?"
send "1\r"
expect "Add 44 block lists?"
send "y\r"
expect "Are you finished?"
send "n\r"

expect "Options:"
send "2\r"
expect "Allowlist action:"
send "a\r"
expect "Where are the allowlists coming from?"
send "1\r"
expect "Add 335 white lists?"
send "y\r"
expect "Are you finished?"
send "y\r"
expect "Update Gravity for immediate effect?"
send "y\r"
expect eof
EOF

chmod +x setup_lists.exp

# Run the expect script
./setup_lists.exp

echo "Setup complete! Please check the web interface and verify your lists."
