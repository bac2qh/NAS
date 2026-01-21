# Transmission + Gluetun (NordVPN) Docker Setup Guide

This guide explains how to run Transmission behind NordVPN using Gluetun in Docker.
All torrent traffic is forced through the VPN, while your host system (macOS, Tailscale, LAN, etc.) remains unaffected.

This setup provides:
- A kill switch (no leaks if VPN drops)
- Clean separation of VPN and torrent client
- Compatibility with Tailscale, SMB, Plex, Immich, etc.

---

## Architecture Overview

```
Internet
   |
[NordVPN]
   |
[Gluetun Container]  <-- VPN tunnel + firewall
   |
[Transmission Container]
```

- The host OS does NOT use NordVPN.
- Transmission can only access the internet through Gluetun.
- If Gluetun disconnects, Transmission loses connectivity.

---

## Prerequisites

- Docker + Docker Compose
- NordVPN subscription
- Basic Docker knowledge

---

## IMPORTANT: NordVPN Credentials (READ THIS)

❗ **Do NOT use your NordVPN account email/password.**

NordVPN requires **service credentials** for manual (OpenVPN/WireGuard) setups.

**Get NordVPN service credentials:**
1. Log into your Nord Account
2. Go to **Set up NordVPN manually**
3. Generate **service username** and **service password**
4. Use those credentials below

---

## Step 1: Create Working Directory

```bash
# Create working directory
mkdir -p ~/docker-apps/transmission-gluetun
cd ~/docker-apps/transmission-gluetun

# Create folders for downloads (on NAS)
mkdir -p /Volumes/NAS_1/Torrents/downloads
mkdir -p /Volumes/NAS_1/Torrents/config
```

## Step 2: Create .env File

Create a file called `.env` in the working directory (`~/docker-apps/transmission-gluetun`).

```bash
# NordVPN service credentials (NOT account email/password)
NORDVPN_USER=your_service_username
NORDVPN_PASS=your_service_password

# Optional: pick preferred server country
SERVER_COUNTRIES=United States
```

(Optional but recommended)
```bash
chmod 600 .env
echo ".env" >> .gitignore  # Keep credentials out of git
```

---

## Step 3: Docker Compose Configuration

```yaml
version: "3.8"

services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    env_file: .env
    environment:
      - VPN_SERVICE_PROVIDER=nordvpn
      - VPN_TYPE=openvpn
      - OPENVPN_USER=${NORDVPN_USER}
      - OPENVPN_PASSWORD=${NORDVPN_PASS}
      - SERVER_COUNTRIES=${SERVER_COUNTRIES}

      # OPTIONAL: allow LAN access to Transmission Web UI
      # CHANGE this to match your LAN subnet (check with: ipconfig getifaddr en1)
      - FIREWALL_OUTBOUND_SUBNETS=192.168.4.0/24

    ports:
      - 9091:9091  # Transmission Web UI

    healthcheck:
      test: ["CMD", "/gluetun-entrypoint", "healthcheck"]
      interval: 60s
      timeout: 10s
      retries: 3

    restart: unless-stopped

  transmission:
    image: lscr.io/linuxserver/transmission
    container_name: transmission
    network_mode: "service:gluetun"
    depends_on:
      gluetun:
        condition: service_healthy

    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago  # Change to your timezone
      - TRANSMISSION_WEB_UI=flood-for-transmission

    volumes:
      - /Volumes/NAS_1/Torrents/config:/config
      - /Volumes/NAS_1/Torrents/downloads:/downloads

    restart: unless-stopped
```

---

## Step 4: Start the Stack

```bash
docker compose up -d
```

Check logs:
```bash
docker logs gluetun
```

You should see:
- VPN connection established

---

## Step 5: Verify VPN Routing (IMPORTANT)

Inside Transmission container:
```bash
docker exec transmission curl ifconfig.me
```
✔ Should show a NordVPN IP

On host machine:
```bash
curl ifconfig.me
```
✔ Should show your normal ISP IP (192.168.4.201 goes through Eero router)

**If both show the same IP → STOP, something is misconfigured.**

---

## Kill Switch Verification

Stop Gluetun:
```bash
docker stop gluetun
```

Now test Transmission:
```bash
docker exec transmission ping -c 3 8.8.8.8
```

✔ This should FAIL (no network connectivity)
✔ Confirms no traffic leaks outside the VPN

Restart Gluetun:
```bash
docker start gluetun
# Wait 30 seconds for VPN to reconnect
sleep 30
docker exec transmission curl ifconfig.me  # Should show NordVPN IP again
```

---

## Accessing Transmission Web UI

From the host:
```
http://localhost:9091
```

From LAN devices:
```
http://192.168.4.201:9091  # Your Mac's IP
```

If LAN access doesn't work, double-check:
```
FIREWALL_OUTBOUND_SUBNETS
```

This must match your LAN subnet. For your network:
- `192.168.4.0/24` (your Eero router network)

Other common subnets:
- `192.168.1.0/24`
- `10.0.0.0/24`

---

## ⚠️ Port Forwarding (NordVPN Users)

❗ **NordVPN does NOT support port forwarding.**

Do NOT set:
```yaml
VPN_PORT_FORWARDING=on
VPN_PORT_FORWARDING_PROVIDER=nordvpn
```

These options are for providers like:
- ProtonVPN
- Private Internet Access
- PrivateVPN

Transmission will still work with NordVPN, just without incoming port forwarding.

---

## Optional: WireGuard (NordLynx)

Gluetun supports NordVPN over WireGuard.

You must obtain:
- WireGuard private key
- WireGuard addresses

From Nord's manual WireGuard setup page.

Example (advanced):
```yaml
- VPN_TYPE=wireguard
- WIREGUARD_PRIVATE_KEY=xxxx
- WIREGUARD_ADDRESSES=10.x.x.x/32
```

This is optional but usually faster than OpenVPN.

---

## Security Notes

- Change Transmission's default credentials (admin/admin)
- Do NOT expose port 9091 to the public internet
- Prefer accessing Transmission via Tailscale if remote access is needed
- Keep `.env` out of version control

---

## macOS + Tailscale Compatibility

This setup:
- Does NOT alter macOS routing
- Does NOT affect Tailscale
- Does NOT break SMB, Plex, Immich, etc.

NordVPN runs entirely inside Docker, isolated from the host.

---

## Summary

✅ Clean VPN isolation
✅ Kill switch enforced
✅ Works with Tailscale
✅ No host-level VPN conflicts
❌ No port forwarding with NordVPN (by design)

---

## Quick Troubleshooting

**Gluetun won't connect:**
```bash
docker logs gluetun | grep -i error
# Check service credentials are correct
```

**Transmission has no internet:**
```bash
docker compose ps gluetun
# Should show: Up (healthy)
# If not, restart: docker compose restart gluetun
```

**Can't access Web UI from LAN:**
```bash
# Check FIREWALL_OUTBOUND_SUBNETS matches your network
# Get your network: ipconfig getifaddr en1  # Ethernet (or en0 for WiFi)
# If 192.168.4.x, use: 192.168.4.0/24
# If 192.168.1.x, use: 192.168.1.0/24
```

---

## Resources

- **gluetun docs:** https://github.com/qdm12/gluetun/wiki
- **NordVPN manual setup:** https://support.nordvpn.com/hc/en-us/articles/20196094470929
- **linuxserver/transmission:** https://docs.linuxserver.io/images/docker-transmission
