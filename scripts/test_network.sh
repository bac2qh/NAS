#!/bin/bash

# Network connectivity test script for NAS setup
# Tests VPN configuration, file sharing, and remote access

echo "======================================"
echo "  NAS Network Configuration Test"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Local IP Address
echo "1. Local IP Address:"
IP_WIFI=$(ipconfig getifaddr en0 2>/dev/null)
IP_ETH=$(ipconfig getifaddr en1 2>/dev/null)

if [ -n "$IP_WIFI" ]; then
    echo "   Wi-Fi: $IP_WIFI"
fi
if [ -n "$IP_ETH" ]; then
    echo "   Ethernet: $IP_ETH"
fi
if [ -z "$IP_WIFI" ] && [ -z "$IP_ETH" ]; then
    echo -e "   ${RED}✗ No local IP found${NC}"
fi
echo ""

# 2. NordVPN Status
echo "2. NordVPN Status:"
# NordVPN doesn't have direct CLI on macOS
if pgrep -x "NordVPN" > /dev/null; then
    echo -e "   ${GREEN}✓ NordVPN app is running${NC}"
    echo "   Check app for connection status and 'Invisible on LAN' setting"
else
    echo -e "   ${RED}✗ NordVPN app not running${NC}"
fi
echo ""

# 3. Tailscale Status
echo "3. Tailscale Status:"
if command -v tailscale &> /dev/null; then
    if tailscale status &> /dev/null; then
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
        echo -e "   ${GREEN}✓ Tailscale connected${NC}"
        echo "   Tailscale IP: $TAILSCALE_IP"
        tailscale status | head -5 | sed 's/^/   /'
    else
        echo -e "   ${YELLOW}⚠ Tailscale installed but not connected${NC}"
    fi
else
    echo -e "   ${RED}✗ Tailscale not installed${NC}"
fi
echo ""

# 4. Routing Table
echo "4. Routing Table (key routes):"
echo "   Default route (should go via NordVPN):"
netstat -nr | grep -E "^default" | head -1 | sed 's/^/   /'
if [ -n "$TAILSCALE_IP" ]; then
    echo "   Tailscale route:"
    netstat -nr | grep -E "100\." | head -1 | sed 's/^/   /'
fi
echo ""

# 5. Connectivity Tests
echo "5. Network Connectivity Tests:"

# Test local router
echo -n "   Local router (192.168.1.1): "
if ping -c 1 -W 1 192.168.1.1 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -n "   Trying 10.0.0.1: "
    if ping -c 1 -W 1 10.0.0.1 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo -e "   ${YELLOW}Check NordVPN 'Invisible on LAN' setting${NC}"
    fi
fi

# Test Tailscale connectivity
if [ -n "$TAILSCALE_IP" ]; then
    echo -n "   Tailscale self ($TAILSCALE_IP): "
    if ping -c 1 -W 1 $TAILSCALE_IP > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAIL${NC}"
    fi
fi

# Test internet via NordVPN
echo -n "   Internet (via NordVPN): "
if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi
echo ""

# 6. File Sharing Services
echo "6. File Sharing Services:"

echo -n "   SMB (File Sharing): "
if ps aux | grep -i smbd | grep -v grep > /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
    # Check if listening on port 445
    if sudo lsof -i :445 > /dev/null 2>&1; then
        echo "      Listening on port 445"
    fi
else
    echo -e "${RED}✗ Not Running${NC}"
    echo -e "   ${YELLOW}Enable in System Settings → Sharing → File Sharing${NC}"
fi
echo ""

# 7. Media Server
echo "7. Media Server:"

echo -n "   Plex Media Server: "
if ps aux | grep -i "Plex Media Server" | grep -v grep > /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
    echo "      Local: http://localhost:32400/web"
    if [ -n "$TAILSCALE_IP" ]; then
        echo "      Remote: http://$TAILSCALE_IP:32400/web"
    fi
else
    echo -e "${YELLOW}⚠ Not Running${NC}"
fi

echo -n "   Jellyfin: "
if ps aux | grep -i jellyfin | grep -v grep > /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
    echo "      Local: http://localhost:8096"
    if [ -n "$TAILSCALE_IP" ]; then
        echo "      Remote: http://$TAILSCALE_IP:8096"
    fi
else
    echo "   Not installed/running"
fi
echo ""

# 8. Drive Mounts
echo "8. Storage Drives:"
if df -h | grep -iE "NAS_Primary" > /dev/null; then
    echo -e "   ${GREEN}✓ Primary NAS drive mounted${NC}"
    df -h | grep -iE "NAS_Primary" | awk '{print "      " $1 " - " $5 " used - " $4 " available"}'
else
    echo -e "   ${YELLOW}⚠ Primary NAS drive not found${NC}"
    echo "   Searched for: NAS_Primary"
fi

if df -h | grep -iE "NAS_Backup" > /dev/null; then
    echo -e "   ${GREEN}✓ Backup drive mounted${NC}"
    df -h | grep -iE "NAS_Backup" | awk '{print "      " $1 " - " $5 " used - " $4 " available"}'
else
    echo "   ℹ Backup drive not mounted"
fi
echo ""

# 9. Security Status
echo "9. Security Status:"

echo -n "   FileVault: "
if fdesetup status | grep -q "On"; then
    echo -e "${GREEN}✓ Enabled${NC}"
else
    echo -e "${YELLOW}⚠ Disabled${NC}"
    echo -e "   ${YELLOW}Recommend enabling in System Settings → Security${NC}"
fi

echo -n "   Firewall: "
if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
    echo -e "${GREEN}✓ Enabled${NC}"
else
    echo -e "${YELLOW}⚠ Disabled${NC}"
    echo -e "   ${YELLOW}Recommend enabling in System Settings → Network → Firewall${NC}"
fi
echo ""

# Summary
echo "======================================"
echo "  Test Summary"
echo "======================================"

ISSUES=0

# Check critical issues
if [ -z "$IP_WIFI" ] && [ -z "$IP_ETH" ]; then
    echo -e "${RED}✗ No network connection${NC}"
    ((ISSUES++))
fi

if ! pgrep -x "NordVPN" > /dev/null; then
    echo -e "${YELLOW}⚠ NordVPN not running${NC}"
    ((ISSUES++))
fi

if ! command -v tailscale &> /dev/null || ! tailscale status &> /dev/null; then
    echo -e "${YELLOW}⚠ Tailscale not connected${NC}"
    ((ISSUES++))
fi

if ! ps aux | grep -i smbd | grep -v grep > /dev/null; then
    echo -e "${RED}✗ File Sharing not enabled${NC}"
    ((ISSUES++))
fi

if ! df -h | grep -iE "NAS_Primary" > /dev/null; then
    echo -e "${YELLOW}⚠ Primary NAS drive not mounted${NC}"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All critical services operational${NC}"
    echo ""
    echo "You can access your NAS at:"
    if [ -n "$IP_WIFI" ]; then
        echo "  Local: smb://$IP_WIFI"
    elif [ -n "$IP_ETH" ]; then
        echo "  Local: smb://$IP_ETH"
    fi
    if [ -n "$TAILSCALE_IP" ]; then
        echo "  Remote: smb://$TAILSCALE_IP"
    fi
else
    echo ""
    echo "Found $ISSUES issue(s). Review messages above."
fi

echo ""
echo "======================================"
