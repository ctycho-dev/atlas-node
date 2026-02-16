#!/bin/bash

# Atlas Node - One-command setup

set -e

echo "🚀 Setting up Atlas Node..."

# Install Docker if needed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com | sh
fi

# Install ufw if needed
if ! command -v ufw &> /dev/null; then
    echo "🔥 Installing ufw firewall..."
    apt update -qq && apt install -y ufw
fi

# Load .env if exists, otherwise generate
if [ -f .env ]; then
    echo "📝 Using existing .env..."
    source .env

    # Validate required vars
    if [ -z "$UUID" ] || [ -z "$REALITY_PRIVATE_KEY" ] || [ -z "$REALITY_PUBLIC_KEY" ] || [ -z "$SHORT_ID" ]; then
        echo "❌ .env is missing required fields!"
        exit 1
    fi

    REALITY_DEST=${REALITY_DEST:-www.microsoft.com:443}
    REALITY_SERVER_NAMES=${REALITY_SERVER_NAMES:-www.microsoft.com}
else
    echo "🔑 Generating keys..."
    UUID=$(uuidgen)
    KEYS=$(docker run --rm ghcr.io/xtls/xray-core:latest x25519)
    REALITY_PRIVATE_KEY=$(echo "$KEYS" | grep "PrivateKey" | awk '{print $2}')
    REALITY_PUBLIC_KEY=$(echo "$KEYS" | grep "Password" | awk '{print $2}')
    SHORT_ID=$(openssl rand -hex 8)
    REALITY_DEST=${REALITY_DEST:-www.microsoft.com:443}
    REALITY_SERVER_NAMES=${REALITY_SERVER_NAMES:-www.microsoft.com}
fi

# Write config.json
echo "📝 Writing config.json..."
cat > xray/config.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "$REALITY_DEST",
        "xver": 0,
        "serverNames": ["$REALITY_SERVER_NAMES"],
        "privateKey": "$REALITY_PRIVATE_KEY",
        "shortIds": ["$SHORT_ID"]
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

echo "✅ Config created!"

# Configure firewall
echo "🔥 Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp     # SSH (don't lock yourself out!)
    ufw allow 443/tcp    # Xray
    yes | ufw enable
    echo "✅ Firewall enabled (ports 22, 443)"
else
    echo "⚠️  ufw not found - install with: apt install -y ufw"
fi

# Start container
echo "🚀 Starting Xray..."
docker compose up -d

# Show client info
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    ✅ Ready!                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "📱 Client Config:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Server:      $SERVER_IP:443"
echo "UUID:        $UUID"
echo "Flow:        xtls-rprx-vision"
echo "Public Key:  $REALITY_PUBLIC_KEY"
echo "Short ID:    $SHORT_ID"
echo "SNI:         $REALITY_SERVER_NAMES"
echo "Fingerprint: chrome"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
