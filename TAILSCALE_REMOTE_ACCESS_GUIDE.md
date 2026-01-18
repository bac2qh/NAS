# Tailscale Remote Access Guide
## Accessing Your Mac NAS from Outside Home Network

---

## Quick Answer: No Public Key Registration Needed!

**Tailscale authentication is MUCH simpler than traditional VPN/SSH:**

❌ You do NOT need to:
- Generate SSH keys
- Register public keys manually
- Configure port forwarding
- Set up DDNS
- Manage certificates

✅ You only need to:
1. Install Tailscale on each device
2. Sign in with your Google/Microsoft/GitHub account
3. All devices authenticated with your account can see each other automatically

---

## How It Works

Tailscale uses **WireGuard** with automatic key management. You authenticate with Google/Microsoft/GitHub, Tailscale handles key generation and exchange automatically. All encryption is transparent - you never see or manage keys.

---

## Step-by-Step Setup for Remote Access

### Phase 1: Set Up Mac NAS (Home)

#### 1. Install Tailscale on Mac

```bash
# Install via Homebrew
brew install --cask tailscale

# Or download from: https://tailscale.com/download
```

#### 2. Launch and Authenticate

```bash
# Open Tailscale app
open /Applications/Tailscale.app

# Click "Sign in with..."
# Choose your identity provider:
# - Google (recommended for personal use)
# - Microsoft
# - GitHub
# - Apple
# - SSO (for organizations)
```

**First-time authentication flow**:
1. Tailscale opens your web browser
2. Sign in with your chosen account (e.g., Gmail)
3. Approve Tailscale permissions
4. Browser shows "Success! Return to Tailscale app"
5. Done - your Mac is now on your Tailscale network!

#### 3. Configure Mac Tailscale Settings

```bash
# In Tailscale menu bar app → Settings:

☑ Start at login
☑ Run in background
☑ Accept routes (if you have subnet routing)
☑ Use Tailscale DNS (optional)

# Optional: Give your Mac a friendly name
# Tailscale admin panel: https://login.tailscale.com/admin/machines
# Click your Mac → Edit → Machine name: "home-nas"
```

#### 4. Note Your Mac's Tailscale IP

```bash
# Get your Tailscale IP address
tailscale ip -4

# Example output: 100.101.102.103
# This is your Mac's permanent IP on Tailscale network
```

**Write this down!** This is the IP you'll use to access your NAS remotely.

---

### Phase 2: Set Up Remote Devices

You need to install Tailscale on **every device** you want to access your NAS from:
- Windows PC (at work, traveling, etc.)
- iPhone/iPad
- Android phone/tablet
- Another Mac

#### Option A: Windows PC

```powershell
# Download from: https://tailscale.com/download/windows
# Or use winget:
winget install tailscale.tailscale

# Launch Tailscale from Start menu
# Sign in with THE SAME account you used on Mac
# (Same Google/Microsoft/GitHub account)
```

**After authentication**:
1. Tailscale icon appears in system tray
2. Click icon → You'll see your Mac listed!
3. Your PC gets its own Tailscale IP (e.g., 100.101.102.104)

**Access your NAS from Windows PC**:
```
File Explorer → Address bar:
\\100.101.102.103\Media

Or map as network drive:
Z: → \\100.101.102.103\Media
```

#### Option B: iPhone/iPad

```
1. App Store → Search "Tailscale"
2. Install Tailscale app
3. Open app → "Sign in"
4. Sign in with THE SAME account (e.g., Google)
5. Enable VPN permission when prompted
```

**Access your NAS from iPhone**:

For files:
```
Install a SMB client app:
- FE File Explorer (recommended, free)
- Documents by Readdle (free)
- FileBrowser Professional (paid, powerful)

In the app:
Server: 100.101.102.103
Username: your-mac-username
Password: your-mac-password
```

For Plex:
```
1. Open Plex app
2. Sign in to your Plex account
3. Plex automatically discovers your server via Tailscale!
```

#### Option C: Android

```
1. Google Play Store → Search "Tailscale"
2. Install Tailscale app
3. Open → "Sign in"
4. Sign in with THE SAME account
5. Enable VPN permission
```

**Access NAS**:
- Use SMB client apps (Solid Explorer, CX File Explorer, etc.)
- Server: 100.101.102.103

#### Option D: Another Mac/Linux

```bash
# macOS
brew install --cask tailscale

# Linux (Ubuntu/Debian)
curl -fsSL https://tailscale.com/install.sh | sh

# Then authenticate
tailscale up
```

---

### Phase 3: Test Remote Access

#### From Any Remote Device (Connected to Tailscale)

**Test 1: Ping your Mac NAS**
```bash
# Windows/Mac/Linux
ping 100.101.102.103

# Should see replies with <50ms latency
```

**Test 2: Access File Sharing**
```bash
# Windows File Explorer
\\100.101.102.103\Media

# macOS Finder
smb://100.101.102.103

# Linux
smb://100.101.102.103/Media
```

**Test 3: Access Plex**
```
Web browser:
http://100.101.102.103:32400/web

Should load Plex interface
```

**Test 4: SSH (if enabled)**
```bash
ssh your-username@100.101.102.103
```

---

## Tailscale vs NordVPN

**Two VPNs, different purposes**:
- **NordVPN**: Routes all internet traffic for privacy
- **Tailscale**: Routes only device-to-device traffic

Both run simultaneously. Internet → NordVPN, Your devices → Tailscale.

---

## Tailscale Free Tier Limits

**What you get for FREE**:
- ✅ Up to 100 devices
- ✅ 1 user (personal account)
- ✅ 1 tailnet (network)
- ✅ All core features (MagicDNS, subnet routing, exit nodes)
- ✅ Unlimited data transfer
- ✅ No bandwidth throttling
- ✅ No time limits

**Perfect for personal NAS use!**

**What you DON'T get** (paid plans only):
- Multiple users (for families/teams)
- Access controls/ACLs (fine-grained permissions)
- Device posture checks
- Priority support

---

## Advanced Configuration (Optional)

### Give Your Mac a Friendly Hostname

Instead of remembering `100.101.102.103`, use a name:

1. Visit https://login.tailscale.com/admin/machines
2. Find your Mac → Click "..." → Edit
3. Machine name: `home-nas`
4. Enable MagicDNS (if not already enabled)

**Now you can access via hostname**:
```bash
# Instead of: smb://100.101.102.103
# Use: smb://home-nas

# Instead of: http://100.101.102.103:32400/web
# Use: http://home-nas:32400/web

# Much easier to remember!
```

### Enable Tailscale SSH (Optional)

Tailscale can manage SSH authentication for you:

**On Mac NAS**:
```bash
# Enable Tailscale SSH
tailscale up --ssh

# Now you can SSH without passwords/keys
# From any Tailscale device:
ssh home-nas
# Automatically authenticated!
```

**Benefits**:
- No password needed
- No SSH key management
- Works from any Tailscale device
- More secure than password auth

### Set Up Subnet Routing (Advanced)

If you want to access OTHER devices on your home network via Tailscale:

**On Mac NAS** (acts as gateway):
```bash
# Enable IP forwarding
echo 'net.inet.ip.forwarding=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.inet.ip.forwarding=1

# Advertise your home subnet
tailscale up --advertise-routes=192.168.1.0/24

# Go to: https://login.tailscale.com/admin/machines
# Find your Mac → Edit → Approve subnet routes
```

**Now from remote devices**:
```bash
# Access your home router
http://192.168.1.1

# Access other devices on home network
ping 192.168.1.50

# Access network printer, smart home devices, etc.
```

**Use case**: Access your entire home network, not just the Mac NAS.

---

## Security Considerations

### Security

**Tailscale is secure**:
- WireGuard protocol, end-to-end encryption (AES-256)
- Zero-trust architecture, open source

**Tailscale sees**: Account email, device metadata
**Tailscale doesn't see**: File contents, traffic, passwords (all encrypted peer-to-peer)

### Best Practices

1. **Strong Mac password** (16+ chars) - protects SMB access
2. **Enable macOS Firewall** - Tailscale adds rules automatically
3. **Monitor devices**: `tailscale status` or https://login.tailscale.com/admin/machines
4. **Lost device?** Disable it immediately at admin panel
5. **Key expiry**: Enabled by default (180 days) - good security

---

## Troubleshooting Remote Access

### Problem: Can't see Mac NAS on Tailscale

**Check 1: Is Mac NAS connected to Tailscale?**
```bash
# On Mac
tailscale status

# Should show:
# - Your Mac's IP (100.x.x.x)
# - Other connected devices
# - Status: "Running"

# If not running:
tailscale up
```

**Check 2: Is remote device connected to Tailscale?**
```bash
# On remote device
tailscale status

# Should show your Mac listed
# If not, authentication may have failed
```

**Check 3: Are you signed in to the SAME account?**
```
Common mistake: Using different Google accounts
- Mac: signed in as personal@gmail.com
- Phone: signed in as work@company.com
❌ These are SEPARATE tailnets!

Solution: Sign out and sign in with same account
```

**Check 4: Network connectivity**
```bash
# Can you ping the Mac?
ping 100.101.102.103

# If "Request timeout":
# - Check Mac is powered on
# - Check Mac has internet connection
# - Check Mac Tailscale is running
```

---

### Problem: Can connect via Tailscale but SMB fails

**Error**: "Network path not found" or "Connection refused"

**Check 1: Is File Sharing enabled on Mac?**
```bash
# System Settings → General → Sharing → File Sharing
# Must be enabled!

# Check SMB is running:
ps aux | grep smbd
```

**Check 2: Are folders shared?**
```bash
# System Settings → Sharing → File Sharing → Shared Folders
# Add /Volumes/NAS_Primary/Media
```

**Check 3: Test with correct credentials**
```bash
# Windows:
\\100.101.102.103\Media
Username: your-mac-username
Password: your-mac-password

# Use Mac SHORT username, not full name
# Check with: whoami
```

**Check 4: Firewall blocking SMB?**
```bash
# On Mac, check firewall allows SMB
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps

# Add SMB if blocked:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/smbd
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /usr/sbin/smbd
```

---

### Problem: Tailscale works at home but not remotely

**Possible cause**: NAT traversal issues

**Check**: Visit https://login.tailscale.com/admin/machines
- Click your Mac → "Details"
- Look for "DERP" relay indicator
- If using DERP relay, connection is working but routing through Tailscale servers (slightly slower but functional)

**Solution**: Usually works fine via DERP relay
- If speed is critical, ensure both devices have public IPs or configure port forwarding (advanced)

---

### Problem: Slow performance over Tailscale

**Expected speeds**:
- Direct peer-to-peer: 50-200 Mbps (depends on your internet upload speed)
- Via DERP relay: 20-100 Mbps

**Check your upload speed** (this is the bottleneck):
```bash
# Visit: https://speedtest.net
# Check UPLOAD speed (not download)

# Your remote access speed ≈ home upload speed
```

**If your home upload is 20 Mbps**:
- Max remote access speed: ~20 Mbps (2.5 MB/s)
- Copy 1GB file: ~7 minutes
- Stream 1080p: Fine
- Stream 4K: Possible but may buffer
- Edit 50GB video remotely: Not practical

**Solutions**:
1. **Upgrade home internet** (fiber, higher upload speeds)
2. **Use proxy workflow** for video editing (copy proxies only)
3. **Copy large files when on-site**, access remotely for playback only
4. **Compress files** before remote transfer

---

### Problem: Tailscale conflicts with NordVPN

**Symptom**: Can't access internet or Tailscale when both are active

**Solution**: Configure NordVPN split tunneling (already covered in main guide)
```bash
# NordVPN settings:
# Split Tunneling → Add exceptions:
# - 100.64.0.0/10 (Tailscale subnet)

# This tells NordVPN: "Don't route Tailscale traffic through VPN"
# Internet → NordVPN
# Device-to-device → Tailscale
```

---

## Usage Examples

**From office**: Connect Tailscale, access `\\home-nas\Media`. Works through most firewalls (uses port 443).

**From phone (4G/5G)**: Enable Tailscale app, use SMB client or Plex app. Speed limited by home upload bandwidth.

**From public Wi-Fi**: Connect NordVPN + Tailscale for double protection. Both encrypt your traffic.

**From abroad**: Works globally. Performance depends on internet speeds (yours + home).

---

## Quick Reference

### Essential Commands

```bash
# Check Tailscale status
tailscale status

# Get your Tailscale IP
tailscale ip -4

# Reconnect Tailscale
tailscale up

# Disconnect Tailscale
tailscale down

# View Tailscale logs (troubleshooting)
tailscale netcheck

# Check connectivity to specific device
ping 100.101.102.103

# SSH via Tailscale (if enabled)
ssh home-nas
```

### Essential URLs

- **Admin panel**: https://login.tailscale.com/admin/machines
- **Download page**: https://tailscale.com/download
- **Documentation**: https://tailscale.com/kb/
- **Status page**: https://status.tailscale.com/

### Your Tailscale Network Info

**Fill this out after setup**:

```
Mac NAS Tailscale IP: 100.___.___.___ (run: tailscale ip -4)
Mac NAS Hostname: home-nas (or custom name)

SMB Access:
- Local: smb://192.168.1.___ or smb://macbook-name.local
- Remote: smb://100.___.___.___  or smb://home-nas

Plex Access:
- Local: http://192.168.1.___:32400/web
- Remote: http://100.___.___.___:32400/web  or http://home-nas:32400/web

SSH Access (if enabled):
- ssh home-nas  or  ssh 100.___.___.___
```

---

## Setup Summary

**On Mac NAS**: Install Tailscale, sign in with Google/Microsoft/GitHub, note IP
**On Remote Devices**: Install Tailscale, sign in with SAME account
**To Access**: Use `smb://100.x.x.x` or `smb://home-nas`

**Key Benefits**:
- No public key management (automatic)
- Simple authentication (Google/etc.)
- Works with NordVPN (configure split tunneling)
- End-to-end encrypted
- Free for personal use (100 devices)
- Works on all platforms

Much simpler than traditional VPN - no port forwarding, no DDNS, no key management.
