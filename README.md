# Atlas Node

Docker-based Xray VPN node with VLESS + Reality.

## Quick Start

```bash
./setup.sh
```

Done! Script will:
- Install Docker
- Generate keys (or use `.env` if exists)
- Start container
- Show client config

## Use Existing Keys

If you have existing keys, create `.env`:

```bash
cp .env.example .env
# Edit .env with your values
./setup.sh
```

## Firewall

```bash
sudo ufw allow 443/tcp
```

## Management

```bash
docker compose logs -f xray   # View logs
docker compose restart xray   # Restart
```

## Regenerate Keys

```bash
rm xray/config.json
./setup.sh
```
