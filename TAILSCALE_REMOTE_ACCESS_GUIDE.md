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

### Enable Tailscale SSH with tmux for Remote Sessions

Tailscale can manage SSH authentication for you, and combined with tmux, you can maintain persistent sessions that survive disconnections - perfect for accessing from iPhone.

#### Step 1: Enable Tailscale SSH on Mac NAS

**On Mac NAS**:
```bash
# Enable Tailscale SSH
tailscale up --ssh

# Verify it's working
tailscale status

# You should see "Offers: ssh" or similar in the output
```

**Benefits**:
- No password needed
- No SSH key management
- Works from any Tailscale device
- More secure than password auth
- Automatic authentication via Tailscale

#### Step 2: Install and Configure tmux on Mac NAS

tmux allows you to create persistent terminal sessions that stay alive even when you disconnect.

**Install tmux**:
```bash
# Install via Homebrew
brew install tmux

# Verify installation
tmux -V
```

**Create a basic tmux configuration** (optional but recommended):
```bash
# Create tmux config file
cat > ~/.tmux.conf << 'EOF'
# Set prefix to Ctrl-a (easier on mobile keyboards)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse support (helpful for mobile)
set -g mouse on

# Increase scrollback buffer
set -g history-limit 10000

# Start window numbering at 1
set -g base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Status bar styling
set -g status-style bg=black,fg=green
set -g status-right '#[fg=cyan]%Y-%m-%d %H:%M'

# Easy config reload
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
EOF

# Load the configuration
tmux source ~/.tmux.conf
```

#### Step 3: Set Up Named tmux Sessions

Create persistent sessions for different tasks:

```bash
# Create a "nas" session for NAS management
tmux new-session -d -s nas

# Create a "backup" session for running backups
tmux new-session -d -s backup

# Create a "monitoring" session for system monitoring
tmux new-session -d -s monitoring

# List all sessions
tmux ls

# Example output:
# nas: 1 windows (created Thu Jan 25 10:30:00 2026)
# backup: 1 windows (created Thu Jan 25 10:30:05 2026)
# monitoring: 1 windows (created Thu Jan 25 10:30:10 2026)
```

#### Step 4: iPhone SSH Client Setup with Termius

**Why Termius**:
- Free tier is excellent for personal use
- Beautiful, modern UI
- Built-in SFTP for file transfers
- Snippets feature for common commands
- Port forwarding support
- Syncs hosts across devices (with premium)
- Works great with Tailscale

**Install Termius**:
```
1. Open App Store on iPhone
2. Search "Termius"
3. Download and install (free)
4. Open the app
```

**Setup your Mac NAS host in Termius**:

```
1. Open Termius app
2. Tap "Hosts" at the bottom
3. Tap "+" (top right) → "New Host"
4. Configure:
   Label: Mac NAS (or any name you like)

   Address:
   - Hostname: home-nas (if you set up MagicDNS)
           OR: 100.101.102.103 (your Mac's Tailscale IP)
   - Port: 22

   Credentials:
   - Username: your-mac-username (run 'whoami' on Mac to verify)
   - Password: Leave empty
   - Key: None (Tailscale handles authentication)

   Advanced (optional):
   - Startup snippet: tmux a || tmux new -s nas
     (This automatically attaches to tmux on connection)

5. Tap "Save" (top right)
```

**First connection**:
```
1. IMPORTANT: Ensure Tailscale app is running on iPhone first
   - Open Tailscale app
   - Verify status shows "Connected"
   - You should see your Mac listed in devices

2. Open Termius app
3. Tap "Hosts"
4. Tap your "Mac NAS" host
5. You'll be connected automatically via Tailscale!
6. Welcome to your Mac terminal on iPhone!
```

**Termius Pro Tips**:

**Use Snippets for common commands**:
```
In Termius:
1. Tap "Snippets" tab
2. Tap "+" → "New Snippet"
3. Create useful snippets like:

Name: Attach NAS Session
Command: tmux a -t nas

Name: List Tmux Sessions
Command: tmux ls

Name: Docker Status
Command: docker ps

Name: Disk Space
Command: df -h

4. When connected, tap top bar → "Snippets" → Select snippet
   Command runs instantly!
```

**Quick SFTP file transfers**:
```
1. When connected to host, tap top bar
2. Tap "SFTP" button
3. Browse your Mac's filesystem
4. Tap files to download to iPhone
5. Upload from iPhone: Tap "+" → Upload files
```

**Split screen for reference**:
```
1. Connect to Mac NAS
2. Swipe up from bottom (iPad/newer iPhones)
3. Drag Safari/Notes to side
4. View documentation while typing commands!
```

**Other good SSH apps** (alternatives if you want to try):
- **Blink Shell** ($20) - Best for power users, Mosh support
- **Prompt** ($15) - Simple and clean interface

#### Step 5: Using tmux from iPhone

**Connect to existing session**:
```bash
# SSH into your Mac (via Termius/Blink/etc)
# Then attach to a session:
tmux attach -t nas

# Or use shorthand:
tmux a -t nas
```

**Essential tmux commands for mobile**:

```bash
# List all sessions
tmux ls

# Create new session with name
tmux new -s session-name

# Attach to existing session
tmux attach -t session-name

# Detach from session (keeps it running)
Ctrl-a + d

# Switch between sessions
Ctrl-a + s    (shows session list, use arrow keys)

# Create new window in session
Ctrl-a + c

# Switch between windows
Ctrl-a + n    (next window)
Ctrl-a + p    (previous window)
Ctrl-a + 0-9  (jump to window number)

# Split pane horizontally
Ctrl-a + "

# Split pane vertically
Ctrl-a + %

# Navigate between panes
Ctrl-a + arrow keys

# Kill current session
tmux kill-session -t session-name
```

**Mobile-friendly workflow**:

```bash
# 1. SSH from iPhone
ssh home-nas

# 2. Attach to your persistent session
tmux a -t nas

# 3. Do your work (run scripts, check logs, etc.)

# 4. When done, detach (DON'T close - just detach!)
Ctrl-a + d

# 5. Exit SSH
exit

# Session keeps running! Next time you connect:
ssh home-nas
tmux a -t nas
# You're right back where you left off!
```

#### Step 6: Practical Use Cases

**Running long backup tasks**:
```bash
# SSH into Mac from iPhone
ssh home-nas

# Attach to backup session
tmux a -t backup

# Start your backup script
./scripts/backup-media.sh

# Detach and let it run
Ctrl-a + d

# Close SSH - backup continues!
# Later, reattach to check progress
```

**Monitoring system health**:
```bash
# Create a monitoring session that runs htop
tmux new -s monitor
htop

# Detach
Ctrl-a + d

# Anytime you want to check system resources:
tmux a -t monitor
```

**Managing Docker containers**:
```bash
# Create docker session
tmux new -s docker

# Watch container status
watch docker ps

# Or check logs
docker-compose logs -f immich

# Detach when done
Ctrl-a + d
```

#### Step 7: Auto-start Important Sessions (Optional)

Create a startup script to ensure your important tmux sessions are always running:

```bash
# Create startup script
cat > ~/start-tmux-sessions.sh << 'EOF'
#!/bin/bash

# Function to create session if it doesn't exist
create_session_if_missing() {
    local session_name=$1
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name"
        echo "Created tmux session: $session_name"
    fi
}

# Create essential sessions
create_session_if_missing "nas"
create_session_if_missing "backup"
create_session_if_missing "monitoring"

echo "All tmux sessions ready!"
EOF

# Make it executable
chmod +x ~/start-tmux-sessions.sh

# Run it now
~/start-tmux-sessions.sh

# Optional: Run on system startup
# Add to a launchd plist or run on login
```

#### Troubleshooting Tailscale SSH

**Problem: SSH connection refused**

```bash
# On Mac NAS, verify SSH is enabled via Tailscale
tailscale status

# Should show something like:
# Offers: ssh

# If not, re-enable:
tailscale up --ssh

# Check if SSH port is listening
sudo lsof -i :22

# Ensure Remote Login is enabled (System Settings)
sudo systemsetup -getremotelogin
# Should show: "Remote Login: On"

# If off, enable it:
sudo systemsetup -setremotelogin on
```

**Problem: Authentication fails from iPhone**

```bash
# Common issues:
# 1. Tailscale not running on iPhone
#    → Open Tailscale app, ensure "Connected"

# 2. Not signed into same Tailscale account
#    → Sign out and sign back in with same account

# 3. Mac's firewall blocking SSH
#    → System Settings → Network → Firewall
#    → Add SSH to allowed apps
```

**Problem: tmux session disappeared**

```bash
# Sessions disappear if Mac restarts
# Check tmux server status:
tmux ls

# If "no server running", create sessions again:
~/start-tmux-sessions.sh

# To prevent data loss, save work before detaching!
```

**Problem: Typing lag on iPhone**

```bash
# Use Mosh instead of SSH (if using Blink Shell)
# Mosh is better for mobile/cellular connections
brew install mosh

# Enable Mosh in Tailscale
tailscale up --ssh

# In Blink Shell, connect using:
mosh home-nas

# Mosh benefits:
# - Handles network switching (Wi-Fi to cellular)
# - Lower latency
# - Works with intermittent connections
```

#### Quick Reference Card for iPhone

**Save this for quick access**:

```bash
# Connect
ssh home-nas

# List sessions
tmux ls

# Attach to session
tmux a -t nas

# Detach (keeps session alive)
Ctrl-a d

# Create new window
Ctrl-a c

# Next/previous window
Ctrl-a n
Ctrl-a p

# Exit SSH (leaves sessions running)
exit
```

**Pro Tips for Mobile SSH**:
1. Use tmux ALWAYS - never run commands directly, always in a session
2. Name sessions descriptively (not "session1", but "docker-logs")
3. Keep one session per task type
4. Detach, don't kill - your work stays alive
5. Enable mouse mode in tmux for easier navigation on touchscreen
6. Use external keyboard with iPhone for better experience (Magic Keyboard, etc.)
7. Consider iPad + keyboard for serious remote work

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
