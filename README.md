# Atlas Node

VPN server node for Atlas VPN system using Xray-core with VLESS + Reality protocol.

**Part of Atlas VPN:** This node is managed by **Atlas Control** (Telegram bot). Users create VPN configs via Telegram commands, and credentials are automatically synced to this node.

---

## Quick Setup

**1. Run the setup script:**

```bash
chmod +x setup.sh
./setup.sh
```

The script will:

- Install Docker & ufw firewall
- Generate Reality keys and save to `.env`
- Create Xray configuration with empty clients array
- Open required ports (22, 443, 3000)
- Start Xray container
- Display node registration details

**2. Add API Secret:**

The setup script creates `.env` with Reality keys. Now add the API secret:

```bash
nano .env
```

Add this line at the bottom:

```env
API_SECRET=your_generated_secret_here  # Generate with: openssl rand -hex 32
```

**3. Start all services:**

```bash
docker compose up -d
```

This starts both Xray and the Node Agent.

**4. Verify Agent is running:**

```bash
curl http://localhost:3000/health
# Should return: {"status":"healthy","timestamp":"..."}
```

**5. Register this node in Atlas Control:**

Use the Telegram bot command `/admin_add_node` and enter the details shown by setup.sh (or from `.env`):

- **HOST:** Your server IP
- **PUBLIC_KEY:** From `.env` → `REALITY_PUBLIC_KEY`
- **SHORT_IDS:** From `.env` → `SHORT_ID` (as array: `["your_short_id"]`)
- **SERVER_NAMES:** From `.env` → `REALITY_SERVER_NAMES` (as array)
- **API_SECRET:** From `.env` → `API_SECRET`

After registration, users can create VPN configs via Telegram!

---

## How It Works

```
User creates VPN via Telegram Bot
          ↓
Atlas Control generates UUID
          ↓
Atlas Control calls this Node's Agent API
          ↓
Agent updates xray/config.json with new UUIDs
          ↓
Xray restarts with updated credentials
          ↓
User receives VLESS URL + QR code
```

**No manual client configuration needed!** Users get everything via Telegram bot.

---

## Architecture

This node runs **two Docker containers**:

### 1. Xray (Port 443)

- VPN server using VLESS + Reality protocol
- Config: `xray/config.json`
- Starts with **empty clients array**
- Automatically updated when Atlas Control syncs credentials

### 2. Node Agent (Port 3000)

- Express API server
- Receives credential updates from Atlas Control
- Rewrites Xray config's clients array and restarts container
- Authenticated via `API_SECRET`

---

## Configuration

**Single `.env` File:** All configuration uses the root `.env` file:

```bash
nano .env  # Edit after setup.sh creates it
```

**Required Variables:**

```env
# Reality keys (auto-generated and saved by setup.sh)
REALITY_PRIVATE_KEY=xxx
REALITY_PUBLIC_KEY=xxx
SHORT_ID=xxx
REALITY_DEST=www.github.com:443
REALITY_SERVER_NAMES=www.github.com

# API Secret (add this manually after setup.sh completes)
API_SECRET=your_secure_random_secret_here
```

**Generate API Secret:**

```bash
openssl rand -hex 32
```

The setup script automatically creates `.env` with Reality keys. You only need to add `API_SECRET`.

Docker Compose reads this `.env` file and passes variables to containers.

---

## Management

```bash
docker compose logs -f         # View all logs
docker compose logs -f xray    # View Xray logs only
docker compose logs -f agent   # View Agent logs only
docker compose restart xray    # Restart VPN
docker compose restart agent   # Restart Agent
docker compose stop            # Stop all services
docker compose up -d           # Start all services
```

---

## Troubleshooting

### Agent not responding

```bash
# Check agent logs
docker compose logs -f agent

# Verify agent is running
docker compose ps

# Check if API_SECRET is set
docker exec atlas-node-agent env | grep API_SECRET
```

### Credentials not syncing

1. Verify API_SECRET matches in Atlas Control node registration
2. Check firewall allows port 3000 from Atlas Control IP
3. Check agent logs: `docker compose logs agent`
4. Test health endpoint: `curl http://localhost:3000/health`

### Xray not accepting connections

```bash
# Check Xray logs
docker compose logs xray

# Verify config is valid
cat xray/config.json

# Restart Xray
docker compose restart xray
```

### Regenerate Reality Keys

If you need to regenerate keys (will invalidate all existing configs):

```bash
rm xray/config.json
rm .env
./setup.sh
```

Then update the node in Atlas Control via `/admin_add_node` with new keys.

---

## Security Notes

1. **Firewall**: Restrict Agent port 3000 to Atlas Control IP only
2. **API_SECRET**: Use strong random secrets (32+ characters)
3. **Reality Keys**: Keep `REALITY_PRIVATE_KEY` secret
4. **Updates**: Keep Docker and Xray image updated

**Recommended Firewall Rules:**

```bash
# Allow SSH, HTTPS (Xray)
ufw allow 22/tcp
ufw allow 443/tcp

# Allow Agent only from Atlas Control IP
ufw allow from ATLAS_CONTROL_IP to any port 3000

ufw enable
```

---

## API Endpoints (Node Agent)

### Health Check

```
GET /health
```

Response: `{"status":"healthy","timestamp":"..."}`

### Sync Credentials (from Atlas Control)

```
POST /api/sync-credentials
Headers: X-API-Secret: <your_secret>
Body: {"uuids": ["uuid1", "uuid2", ...]}
```

Response: `{"success":true,"clientsUpdated":3,"timestamp":"..."}`

---

## Logs

```bash
# View all logs
docker compose logs -f

# View specific container
docker compose logs -f xray
docker compose logs -f agent

# Last 100 lines
docker compose logs --tail=100 agent
```

---

## Port Reference

| Port | Service        | Exposure                     |
| ---- | -------------- | ---------------------------- |
| 443  | Xray VPN       | Public                       |
| 3000 | Node Agent API | Private (Atlas Control only) |

---

## Support

For setup issues or questions, check:

- [VPN_SETUP.md](../VPN_SETUP.md) - Full Atlas VPN documentation
- Agent logs: `docker compose logs agent`
- Xray logs: `docker compose logs xray`
