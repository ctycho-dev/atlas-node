# Atlas Node

Docker-based VPN node using Xray-core with VLESS + Reality protocol.

## Setup

**1. Clone the repository on your VPS:**

```bash
cd /opt
git clone https://github.com/ctycho-dev/atlas-node.git
cd atlas-node
chmod +x setup.sh
```

**2. Run the setup script:**

```bash
./setup.sh
```

The script will automatically:

- Install Docker
- Install ufw firewall
- Generate Reality keys and UUID
- Configure Xray
- Open required ports (22, 443)
- Start the VPN container
- Display client connection details

**3. Copy the client config** and add it to your HAPP client.

## Client Configuration

After running setup, you'll see output like:

```
Server:      YOUR_SERVER_IP:443
UUID:        xxxxx-xxxx-xxxx-xxxx
Flow:        xtls-rprx-vision
Public Key:  xxxxxxxxxxxx
Short ID:    xxxxxxxx
SNI:         www.microsoft.com
Fingerprint: chrome
```

Enter these values in HAPP to connect.

## Management

```bash
docker compose logs -f xray    # View logs
docker compose restart xray    # Restart VPN
docker compose stop xray       # Stop VPN
docker compose up -d xray      # Start VPN
```

## Regenerate Keys

```bash
rm xray/config.json
./setup.sh
```
