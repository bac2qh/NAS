# Transmission with gluetun VPN Setup Guide
## Separated VPN Container for Maximum Flexibility

---

## What is This?

**gluetun** = Lightweight VPN client container (supports 50+ VPN providers)
**Transmission** = Separate torrent client container
**Network routing** = Transmission routes ALL traffic through gluetun

**Benefits over all-in-one:**
- ✅ Can add multiple apps to same VPN (Plex, Radarr, Sonarr, etc.)
- ✅ Better separation (VPN independent of apps)
- ✅ Easier to troubleshoot (restart apps without restarting VPN)
- ✅ More flexible (swap torrent clients easily)
- ✅ Better kill switch (network-level isolation)

---

## How It Works

```
Your Setup:
┌─────────────────────────────────────────┐
│  macOS (normal network)                 │
│  ├── Tailscale ✅                       │
│  ├── SMB sharing ✅                     │
│  ├── Immich ✅                          │
│  │                                       │
│  └── Docker Containers:                 │
│      ├── gluetun (VPN container)        │
│      │   └── NordVPN tunnel             │
│      │       ↓                           │
│      └── Transmission                   │
│          └── Uses gluetun's network     │
│              ↓                           │
│         All torrent traffic encrypted   │
└─────────────────────────────────────────┘

Kill Switch:
- Transmission has NO direct network access
- Can ONLY reach internet through gluetun
- If gluetun VPN fails → Transmission has zero connectivity
- No IP leaks possible ✅
```

**Network isolation:**
```
Transmission container:
- network_mode: "service:gluetun"
- No independent network stack
- Completely dependent on gluetun
- If VPN down = No internet = Perfect kill switch ✅
```

---

## Prerequisites

- ✅ Docker Desktop installed and running
- ✅ NordVPN subscription (active account)
- ✅ Tailscale set up (optional, for remote access)
- ✅ NAS drive mounted at /Volumes/NAS_1

---

## Installation

### Step 1: Create Directory Structure

```bash
# Create folders for Transmission
mkdir -p /Volumes/NAS_1/Torrents/downloads
mkdir -p /Volumes/NAS_1/Torrents/incomplete
mkdir -p /Volumes/NAS_1/Torrents/config
mkdir -p ~/docker-apps/transmission-gluetun

# Navigate to app directory
cd ~/docker-apps/transmission-gluetun
```

### Step 2: Get NordVPN Credentials

**You need your NordVPN account credentials:**

```
Email: your-nordvpn-account-email@example.com
Password: your-nordvpn-account-password

⚠️ Use your ACCOUNT credentials (what you login to nordvpn.com with)
```

### Step 3: Create Docker Compose Configuration

```bash
# Create docker-compose.yml file
nano docker-compose.yml
```

**Paste this configuration:**

```yaml
version: "3.8"

services:
  # VPN Container (gluetun)
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun-vpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      # VPN Provider
      - VPN_SERVICE_PROVIDER=nordvpn
      - VPN_TYPE=openvpn

      # NordVPN Credentials
      - OPENVPN_USER=your-nordvpn-email@example.com
      - OPENVPN_PASSWORD=your-nordvpn-password

      # Server Selection
      - SERVER_COUNTRIES=USA
      # Or specific server: SERVER_HOSTNAMES=us9999.nordvpn.com

      # Kill Switch (built-in, always enabled)
      - FIREWALL_OUTBOUND_SUBNETS=192.168.4.0/24  # Your local network

      # DNS
      - DNS_ADDRESS=1.1.1.1

      # Health Check
      - HEALTH_VPN_DURATION_INITIAL=30s

      # Timezone
      - TZ=America/Chicago

    ports:
      # Transmission Web UI (exposed through gluetun)
      - "9091:9091"

      # Optional: HTTP control server for gluetun
      - "8000:8000"

    volumes:
      - gluetun-config:/gluetun

    restart: unless-stopped

    healthcheck:
      test: ["CMD", "/gluetun-entrypoint", "healthcheck"]
      interval: 60s
      timeout: 10s
      retries: 3

    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  # Transmission Container (routes through gluetun)
  transmission:
    image: linuxserver/transmission:latest
    container_name: transmission
    network_mode: "service:gluetun"  # ← Routes all traffic through gluetun
    depends_on:
      gluetun:
        condition: service_healthy
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago

      # Transmission Settings
      - TRANSMISSION_WEB_UI=flood-for-transmission

      # Download Settings
      - TRANSMISSION_DOWNLOAD_DIR=/downloads/completed
      - TRANSMISSION_INCOMPLETE_DIR=/downloads/incomplete

      # Privacy Settings
      - TRANSMISSION_PEER_PORT_RANDOM_ON_START=true
      - TRANSMISSION_DHT_ENABLED=false
      - TRANSMISSION_PEX_ENABLED=false
      - TRANSMISSION_LPD_ENABLED=false

      # Performance
      - TRANSMISSION_SPEED_LIMIT_UP=1000
      - TRANSMISSION_SPEED_LIMIT_UP_ENABLED=true

      # Seeding
      - TRANSMISSION_RATIO_LIMIT=2
      - TRANSMISSION_RATIO_LIMIT_ENABLED=true

    volumes:
      - /Volumes/NAS_1/Torrents/downloads:/downloads/completed
      - /Volumes/NAS_1/Torrents/incomplete:/downloads/incomplete
      - /Volumes/NAS_1/Torrents/config:/config

    restart: unless-stopped

    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  gluetun-config:
```

**Important configuration notes:**

```yaml
# Change these to YOUR values:
OPENVPN_USER: your-nordvpn-email@example.com
OPENVPN_PASSWORD: your-nordvpn-password
FIREWALL_OUTBOUND_SUBNETS: 192.168.4.0/24  # Your home network
TZ: America/Chicago  # Your timezone

# VPN Server Selection:
SERVER_COUNTRIES: USA  # Options: US, UK, CA, DE, FR, etc.
# Or specific server:
# SERVER_HOSTNAMES: us9999.nordvpn.com

# Note: network_mode: "service:gluetun" is the KEY setting
# This routes Transmission through gluetun (kill switch enabled)
```

**Save file:** Ctrl+O, Enter, Ctrl+X

### Step 4: Configure Environment Variables (Secure Method)

**Better security - use .env file for credentials:**

```bash
# Create .env file for sensitive data
nano .env
```

**Add credentials:**
```
NORDVPN_USER=your-nordvpn-email@example.com
NORDVPN_PASS=your-nordvpn-password
LOCAL_NETWORK=192.168.4.0/24
```

**Update docker-compose.yml to use variables:**
```yaml
# In gluetun environment section:
- OPENVPN_USER=${NORDVPN_USER}
- OPENVPN_PASSWORD=${NORDVPN_PASS}
- FIREWALL_OUTBOUND_SUBNETS=${LOCAL_NETWORK}
```

**Secure the .env file:**
```bash
chmod 600 .env
echo ".env" >> .gitignore
```

### Step 5: Start Services

```bash
# Start containers
docker compose up -d

# Watch logs to verify VPN connection
docker compose logs -f gluetun

# Look for success messages:
# ✅ "VPN is running"
# ✅ "healthy"
# ✅ Country: United States (or your selection)

# Transmission starts automatically after gluetun is healthy
docker compose logs -f transmission
```

**First startup takes 1-2 minutes** (gluetun connects to VPN, then Transmission starts)

### Step 6: Verify VPN is Working

```bash
# Check gluetun's public IP (should be NordVPN)
docker exec gluetun-vpn wget -qO- ifconfig.me
# Should show NordVPN IP

# Check Transmission's public IP (should be SAME as gluetun)
docker exec transmission wget -qO- ifconfig.me
# Should show SAME NordVPN IP (proves routing works)

# Compare with your real IP
curl -s ifconfig.me
# Should be DIFFERENT (your actual ISP)

# All three IPs:
# 1. gluetun: NordVPN IP
# 2. Transmission: NordVPN IP (same as gluetun)
# 3. Your Mac: Real ISP IP (different)
```

**Check VPN location:**
```bash
docker exec gluetun-vpn wget -qO- ipinfo.io

# Should show:
# "country": "US" (or whatever you configured)
# "org": "AS174 NordVPN"
```

### Step 7: Verify Kill Switch

**Test that Transmission has NO internet when VPN fails:**

```bash
# 1. Check current IP (should be NordVPN)
docker exec transmission wget -qO- ifconfig.me

# 2. Stop gluetun (simulates VPN failure)
docker stop gluetun-vpn

# 3. Try to reach internet from Transmission (should FAIL)
docker exec transmission wget -qO- --timeout=5 ifconfig.me
# Result: Connection timeout ✅ (no internet = kill switch working)

# 4. Restart gluetun
docker start gluetun-vpn

# 5. Wait 30 seconds for VPN reconnection

# 6. Test again (should work)
docker exec transmission wget -qO- ifconfig.me
# Result: NordVPN IP ✅ (connection restored)
```

**Kill switch confirmed:** Transmission cannot reach internet without VPN ✅

---

## Accessing Transmission Web UI

### On Local Network

**Open browser:**
```
http://localhost:9091
```

**Default credentials (linuxserver/transmission):**
```
Username: admin
Password: admin

⚠️ Change password after first login:
Settings → Authentication → Update password
```

**You'll see:**
- Flood UI (modern, mobile-friendly)
- Add torrent button
- Download speed graph
- List of active torrents

### Via Tailscale (Remote Access)

```bash
# 1. Get your Mac's Tailscale IP:
tailscale ip -4
# Example: 100.101.102.103

# 2. Open in browser:
http://100.101.102.103:9091

# 3. Login with credentials
```

---

## Using Transmission

### Adding Torrents

**Same as all-in-one version:**

```
Method 1: Upload .torrent file
Method 2: Paste magnet link
Method 3: Drop in watch folder
```

*(See main TRANSMISSION_VPN_SETUP_GUIDE.md for details)*

---

## Adding More Apps to VPN

**This is where gluetun shines!** You can add other apps to share the same VPN.

### Example: Add qBittorrent

```yaml
services:
  gluetun:
    # ... existing config
    ports:
      - "9091:9091"  # Transmission
      - "8080:8080"  # qBittorrent (add this)

  transmission:
    # ... existing config

  qbittorrent:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: "service:gluetun"  # Routes through gluetun
    depends_on:
      gluetun:
        condition: service_healthy
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
      - WEBUI_PORT=8080
    volumes:
      - /Volumes/NAS_1/Torrents/downloads:/downloads
      - /Volumes/NAS_1/Torrents/qbittorrent-config:/config
    restart: unless-stopped
```

**Now both Transmission AND qBittorrent route through same VPN!**

### Example: Add Plex for Geo-Unblocking

```yaml
services:
  gluetun:
    # ... existing config
    environment:
      - SERVER_COUNTRIES=UK  # UK content
    ports:
      - "9091:9091"   # Transmission
      - "32400:32400" # Plex (add this)

  transmission:
    # ... existing config

  plex:
    image: linuxserver/plex:latest
    container_name: plex
    network_mode: "service:gluetun"  # Routes through UK VPN
    depends_on:
      gluetun:
        condition: service_healthy
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
    volumes:
      - /Volumes/NAS_1/Plex:/config
      - /Volumes/NAS_1/Movies:/movies
      - /Volumes/NAS_1/TV:/tv
    restart: unless-stopped
```

**Now Plex appears to be in UK** (can access UK-only content)

### Example: Multiple VPN Connections

```yaml
services:
  gluetun-us:
    image: qmcgaw/gluetun
    # ... US VPN config
    ports:
      - "9091:9091"  # Transmission

  gluetun-uk:
    image: qmcgaw/gluetun
    # ... UK VPN config
    ports:
      - "32400:32400"  # Plex

  transmission:
    network_mode: "service:gluetun-us"  # Use US VPN

  plex:
    network_mode: "service:gluetun-uk"  # Use UK VPN
```

**Different apps use different VPN servers!**

---

## Maintenance

### Updating Containers

```bash
cd ~/docker-apps/transmission-gluetun

# Pull latest images
docker compose pull

# Restart with new versions
docker compose down
docker compose up -d

# Check logs
docker compose logs -f
```

**Update frequency:** Monthly

### Monitoring

**Check status:**
```bash
# All containers running?
docker compose ps

# Should show:
# NAME           STATUS              PORTS
# gluetun-vpn    Up (healthy)       0.0.0.0:9091->9091/tcp
# transmission   Up                 (none - uses gluetun network)

# View gluetun logs
docker compose logs -f gluetun

# View Transmission logs
docker compose logs -f transmission

# Check VPN status
docker exec gluetun-vpn wget -qO- ipinfo.io | grep country
```

**Check VPN health:**
```bash
# gluetun health endpoint
curl http://localhost:8000/v1/publicip/ip
# Should return NordVPN IP

# Health check status
docker inspect gluetun-vpn | grep -A 10 Health
```

### Restart Containers

```bash
# Restart everything
docker compose restart

# Restart only gluetun (Transmission auto-restarts)
docker compose restart gluetun

# Restart only Transmission (keeps VPN running)
docker compose restart transmission

# Full restart (reload config)
docker compose down
docker compose up -d
```

---

## Troubleshooting

### VPN Won't Connect

**Check gluetun logs:**
```bash
docker compose logs gluetun | grep -i error

# Common errors:
# "authentication failed" → Wrong credentials
# "cannot resolve host" → Network issue
# "no servers found" → Wrong country code
```

**Try different VPN protocol:**
```yaml
# In docker-compose.yml gluetun section:
- VPN_TYPE=openvpn  # Try openvpn first
# Or:
- VPN_TYPE=wireguard  # Faster but may need token
```

**Try specific server:**
```yaml
# Instead of SERVER_COUNTRIES:
- SERVER_HOSTNAMES=us9999.nordvpn.com
# Find servers at: https://nordvpn.com/servers/tools/
```

### Can't Access Transmission Web UI

**Check gluetun is healthy:**
```bash
docker compose ps

# gluetun should show: Up (healthy)
# If unhealthy, check logs:
docker compose logs gluetun
```

**Verify port mapping:**
```bash
# Check port is exposed by gluetun
docker port gluetun-vpn
# Should show: 9091/tcp -> 0.0.0.0:9091
```

**Check Transmission is running:**
```bash
docker compose ps transmission

# If not running:
docker compose logs transmission
```

### Transmission Can't Connect to Internet

**This is the kill switch working!** Verify VPN is up:

```bash
# Check gluetun status
docker compose ps gluetun
# Should be: Up (healthy)

# If unhealthy, restart:
docker compose restart gluetun

# Wait 30 seconds for VPN connection

# Check Transmission can now reach internet:
docker exec transmission wget -qO- ifconfig.me
```

### Slow Download Speeds

**Check VPN connection:**
```bash
# Test speed from gluetun
docker exec gluetun-vpn wget -O /dev/null http://speedtest.tele2.net/100MB.zip

# Should get 10-50 MB/s depending on server
```

**Try different VPN server:**
```yaml
# Change in docker-compose.yml:
- SERVER_COUNTRIES=CA  # Try Canada, Netherlands, etc.
# Restart:
docker compose down && docker compose up -d
```

**Try WireGuard (faster):**
```yaml
- VPN_TYPE=wireguard
- WIREGUARD_PRIVATE_KEY=...  # Get from NordVPN
- WIREGUARD_ADDRESSES=10.5.0.2/16
```

### gluetun Keeps Restarting

**Check health check:**
```bash
docker compose logs gluetun | grep -i health

# If health check failing:
# - VPN may not be connecting
# - Check credentials
# - Check server availability
```

**Disable health check temporarily:**
```yaml
# In docker-compose.yml gluetun section:
# Comment out or remove healthcheck section
# healthcheck:
#   test: ...

# Restart
docker compose down && docker compose up -d
```

### Local Network Access Issues

**Can't access from home network:**

```yaml
# Verify FIREWALL_OUTBOUND_SUBNETS includes your network:
- FIREWALL_OUTBOUND_SUBNETS=192.168.4.0/24

# Find your network:
ipconfig getifaddr en0  # Your Mac IP
# If 192.168.1.x, use: 192.168.1.0/24
# If 10.0.0.x, use: 10.0.0.0/24

# Update in docker-compose.yml and restart
```

---

## Advanced Configuration

### Port Forwarding (Optional)

**Some VPN providers support port forwarding for better torrent performance:**

```yaml
# gluetun environment (if provider supports it):
- VPN_PORT_FORWARDING=on
- VPN_PORT_FORWARDING_PROVIDER=nordvpn  # Not all providers support this

# gluetun will automatically forward a port
# Check which port:
docker compose logs gluetun | grep "port forwarded"
```

**Note:** NordVPN doesn't support port forwarding. Consider Mullvad or ProtonVPN for this feature.

### Custom DNS

```yaml
# In gluetun environment:
- DNS_ADDRESS=1.1.1.1,1.0.0.1  # Cloudflare
# Or:
- DNS_ADDRESS=9.9.9.9  # Quad9
# Or:
- DNS_ADDRESS=8.8.8.8  # Google
```

### HTTP Control Server

**gluetun includes HTTP API for monitoring:**

```bash
# Public IP
curl http://localhost:8000/v1/publicip/ip

# Port forwarded (if enabled)
curl http://localhost:8000/v1/openvpn/portforwarded

# Status
curl http://localhost:8000/v1/openvpn/status
```

---

## Comparison: gluetun vs All-in-One

| Feature | gluetun + Transmission | haugene/transmission-openvpn |
|---------|----------------------|----------------------------|
| **Kill switch** | ✅ Network-level (best) | ✅ Built-in |
| **Add more apps** | ✅ Easy | ❌ Need separate container |
| **VPN flexibility** | ✅ 50+ providers | ✅ Many providers |
| **Troubleshooting** | ✅ Separate logs | ❌ Combined logs |
| **Resource usage** | Slightly higher (2 containers) | Lower (1 container) |
| **Complexity** | Moderate | Simple |
| **Swap torrent client** | ✅ Easy | ❌ Need different image |
| **Port forwarding** | ✅ Better support | Limited |
| **Best for** | Multiple VPN apps | Single torrent client |

---

## Integration with NAS Services

### Included in restic Backups

**Your weekly backup includes Torrents:**

```bash
# restic backs up entire /Volumes/NAS_1, including:
/Volumes/NAS_1/Torrents/downloads  ← Completed downloads
/Volumes/NAS_1/Torrents/config     ← Transmission settings
```

### Works with Immich, SMB, Tailscale

**No conflicts:**
- ✅ gluetun VPN isolated to containers only
- ✅ macOS network unaffected
- ✅ Tailscale works normally
- ✅ SMB file sharing unaffected
- ✅ Immich works normally

---

## Summary

**What you get:**
- ✅ Private torrenting through NordVPN
- ✅ Superior kill switch (network-level isolation)
- ✅ Can add more apps to same VPN easily
- ✅ Better troubleshooting (separate containers)
- ✅ No conflicts with Tailscale/SMB/Immich

**Setup time:** 20-30 minutes
**Maintenance:** Update monthly, verify VPN periodically
**Flexibility:** Can add Plex, Radarr, Sonarr, etc. to same VPN

**When to use this over all-in-one:**
- ✅ Plan to add more services later
- ✅ Want maximum flexibility
- ✅ Want best kill switch implementation
- ✅ Want to swap torrent clients easily

**Next steps:**
1. Create directory structure
2. Set up docker-compose.yml
3. Add NordVPN credentials
4. Start containers
5. Verify VPN working
6. Verify kill switch
7. Access web UI
8. Add your first torrent

---

## Resources

- **gluetun docs:** https://github.com/qdm12/gluetun/wiki
- **linuxserver/transmission:** https://docs.linuxserver.io/images/docker-transmission
- **NordVPN support:** https://support.nordvpn.com
- **Docker compose docs:** https://docs.docker.com/compose/

**Need help?**
- Check gluetun logs: `docker compose logs gluetun`
- Check Transmission logs: `docker compose logs transmission`
- Verify VPN: `docker exec gluetun-vpn wget -qO- ifconfig.me`
- Test kill switch: Stop gluetun and verify Transmission has no internet
- Test from browser: http://localhost:9091
