# Atlas Node Setup

> Run on a fresh Ubuntu/Debian VPS with root access.

## Requirements

- Ubuntu 20.04+ or Debian 11+
- Root or sudo access

---

## 1. Run setup

```bash
chmod +x setup.sh
./setup.sh
```

The script fully automates everything:

1. Installs Docker if missing
2. Generates Reality key pair (`REALITY_PRIVATE_KEY`, `REALITY_PUBLIC_KEY`, `SHORT_ID`) and writes them to `.env`
3. Writes `xray/config.json` with the generated keys
4. Configures the firewall (opens ports 22, 443, 3000)
5. Starts Xray + the Node Agent containers
6. **Prompts you to enter a name for this node** (e.g. `Server 1 DE`)
7. Auto-generates `API_SECRET`, saves it to `.env`, and restarts containers
8. Prints a summary and a **registration token**

Example output at the end:

```
╔══════════════════════════════════════════════════════════╗
║              ✅ Atlas Node Setup Complete!               ║
╚══════════════════════════════════════════════════════════╝

📋 Node Details:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name:         Server 1 DE
Server IP:    1.2.3.4
Port:         443
Public Key:   <generated>
Short ID:     <generated>
Server Names: www.github.com
Destination:  www.github.com:443
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔑 Registration Token:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

eyJuYW1lIjogIlNlcnZlci...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

You do **not** need to create or edit `.env` manually — the script handles all of it.

---

## 2. Verify the agent is running

```
http://YOUR_VPS_IP:3000/health
```

Should return `{"status":"healthy",...}`.

---

## 3. Register in Atlas Control

Send this command to your Telegram bot:

```
/admin_add_node $REGISTRATION_TOKEN
```

`$REGISTRATION_TOKEN` is the token printed at the end of the setup script.

---

## Management

**Restart all containers:**

```bash
docker compose down && docker compose up -d
```

**Restart only Xray (apply config changes):**

```bash
docker restart xray
```

**View logs:**

```bash
# View Xray logs
docker logs xray
docker logs xray -f          # follow live
docker logs xray --tail 100  # last 100 lines

# View Node Agent logs
docker logs atlas-node-agent
docker logs atlas-node-agent -f
```
