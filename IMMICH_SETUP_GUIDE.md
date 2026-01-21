# Immich Setup Guide
## Self-Hosted Photo Management with Auto-Upload

---

## What is Immich?

**Immich** is a self-hosted Google Photos alternative with:
- ✅ Native iPhone app with automatic photo backup
- ✅ AI-powered organization (face recognition, object detection)
- ✅ Timeline, albums, search, sharing
- ✅ **100% private** - everything runs on your NAS
- ✅ No cloud servers, no subscriptions

**Perfect for:** Automatically backing up iPhone photos/videos to your NAS

---

## Prerequisites

- ✅ Mac NAS running macOS
- ✅ Docker Desktop installed
- ✅ Tailscale set up (for remote access)
- ✅ 16GB+ RAM recommended (M1 Mac works great)

---

## Installation

### Step 1: Install Docker Desktop

```bash
# Install Docker:
brew install --cask docker

# Launch Docker Desktop:
open /Applications/Docker.app

# Wait for Docker to start (whale icon in menu bar)
```

### Step 2: Create Immich Directory

```bash
# Create Immich folder structure:
mkdir -p /Volumes/NAS_1/Immich/{upload,thumbs,profile,video,database}
mkdir -p ~/immich-app

# Navigate to app directory:
cd ~/immich-app
```

### Step 3: Download Immich Configuration

```bash
# Download docker compose file:
curl -o docker compose.yml https://github.com/immich-app/immich/releases/latest/download/docker compose.yml

# Download environment configuration:
curl -o .env https://github.com/immich-app/immich/releases/latest/download/example.env

# Download hardware acceleration config (for M1):
curl -o hwaccel.ml.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml
```

### Step 4: Configure Immich

**Edit `.env` file:**
```bash
# Open in editor:
nano .env

# Change these lines:
UPLOAD_LOCATION=/Volumes/NAS_1/Immich/upload
IMMICH_VERSION=release

# Optional: Set timezone
TZ=America/Chicago

# Save: Ctrl+O, Enter, Ctrl+X
```

### Step 5: Start Immich

```bash
# Start all Immich services:
docker compose up -d

# Check status:
docker compose ps

# Should show:
# immich-server       running
# immich-machine-learning   running
# immich-postgres     running
# immich-redis        running
```

**Wait 2-3 minutes for services to fully start.**

### Step 6: Access Immich Web UI

```bash
# Open in browser:
open http://localhost:2283

# First-time setup:
# 1. Create admin account
#    Email: your-email@example.com
#    Password: [strong password - save in password manager]
# 2. Confirm password
# 3. Click "Sign Up"
```

---

## iPhone App Setup

### Step 7: Install Immich Mobile App

```
1. App Store → Search "Immich"
2. Install official Immich app
3. Open app
```

### Step 8: Connect to Your Server

**On home Wi-Fi (initial setup):**
```
1. Server Endpoint URL: http://192.168.4.21:2283
   (Use your Mac's local IP - find with: ipconfig getifaddr en1)

2. Email: your-email@example.com
3. Password: [admin password you created]
4. Login
```

**For remote access (via Tailscale):**
```
1. Enable Tailscale on iPhone
2. Get Mac's Tailscale IP:
   # On Mac:
   tailscale ip -4
   # Example output: 100.101.102.103

3. In Immich app settings:
   Server URL: http://100.101.102.103:2283

4. Now works from anywhere! ✅
```

### Step 9: Enable Auto-Backup

```
1. Immich app → Backup (tab at bottom)
2. Tap "Select Albums to Backup"
3. Select "Recents" (or specific albums)
4. Toggle "Background Backup" → ON

Settings to configure:
✅ Foreground/Background Backup: ON
✅ WiFi Only: ON (or OFF if you want cellular backup)
✅ Upload Original: ON (keep full quality)
✅ Include Videos: ON
✅ Ignore iCloud Assets: OFF (backup everything)
```

**Immich will now automatically backup new photos/videos!**

---

## External Library Setup (Existing Photos)

**Optional:** Add your existing NAS photos to Immich library

### Step 10: Add External Library

```
1. Web UI → Administration (user icon) → External Libraries
2. Click "Create External Library"
3. Name: "NAS Photos"
4. Import Paths:
   - Click "Add Path"
   - Enter: /usr/src/app/external/Photos

5. Click "Create"
6. Click "Scan Library" → Start scan

Note: Path is /usr/src/app/external/Photos because that's how
Docker maps /Volumes/NAS_1/Photos inside the container.
```

### Configure Docker Volume for External Library

**Edit docker compose.yml to add external library:**

```bash
cd ~/immich-app
nano docker compose.yml

# Find the immich-server service, add under volumes:
volumes:
  - /Volumes/NAS_1/Immich/upload:/usr/src/app/upload
  - /Volumes/NAS_1/Photos:/usr/src/app/external/Photos:ro
  # ↑ Add this line (ro = read-only)

# Save and restart:
docker compose down
docker compose up -d
```

**Now scan will include existing photos** (takes hours for large collections)

---

## Remote Access via Tailscale (Recommended)

### Why Tailscale is Best

**Secure remote access:**
- ✅ End-to-end encrypted (WireGuard)
- ✅ No port forwarding needed
- ✅ No exposing services to public internet
- ✅ Works from anywhere
- ✅ Free for personal use

**Alternative (NOT recommended):**
- ❌ Port forwarding 2283 to internet (security risk)
- ❌ Need HTTPS certificate
- ❌ Expose to attackers

### Using Immich Remotely

**From anywhere in the world:**

```
1. Enable Tailscale on iPhone/device
2. Immich app connects via Tailscale IP: http://100.x.x.x:2283
3. Upload/browse photos normally
4. Encrypted, secure, private ✅

Speed: Limited by home upload bandwidth (~20-50 Mbps typical)
      = 2.5-6 MB/s uploads from phone
```

---

## Usage

### Daily Workflow

**Automatic (no action needed):**
```
1. Take photos on iPhone
2. Connect to WiFi (or enable cellular backup)
3. Immich auto-uploads in background
4. Photos appear on NAS + in Immich web UI
```

**Browse photos:**
```
Web UI: http://localhost:2283 (at home)
        http://100.x.x.x:2283 (via Tailscale)

Features:
- Timeline view (by date)
- Search: "beach sunset 2024"
- Face recognition: Click person, see all photos
- Albums: Create albums, share links
- Map view: See where photos were taken
```

### Creating Albums

```
1. Select photos (click checkbox)
2. Click "+" → "Add to Album"
3. Create new album or add to existing
4. Albums appear in sidebar
```

### Sharing Photos

```
1. Create album
2. Click share icon
3. Generate share link
4. Share link works ONLY via Tailscale (secure)

Recipient needs:
- Tailscale connected to your network
- Or: On your local network
```

### Searching Photos

**AI-powered search:**
```
Search examples:
- "cat" → All photos with cats
- "beach" → Beach photos
- "John Smith" → All photos of that person
- "2024" → Photos from 2024
- "paris" → Photos taken in Paris
- "food" → AI detects food photos
- "portrait" → AI detects portraits
```

### Face Recognition

```
1. Photos → People (sidebar)
2. Immich shows detected faces
3. Click face → Name it
4. Immich groups all photos with that person
5. Search by name to find all their photos
```

---

## Storage & Backup

### Where Photos Are Stored

```
/Volumes/NAS_1/Immich/
├── upload/                    ← iPhone uploads here
│   ├── 2024/
│   │   ├── 01/
│   │   │   ├── 20/
│   │   │   │   ├── IMG_1234.jpg
│   │   │   │   └── VID_5678.mp4
├── thumbs/                    ← Thumbnails (generated)
├── profile/                   ← Profile pictures
├── video/                     ← Transcoded videos
└── database/                  ← PostgreSQL database

/Volumes/NAS_1/Photos/         ← Your existing photos (if external library enabled)
```

### Backup Strategy

**Included in your weekly restic backup:**
```bash
# restic backs up entire NAS_1, including:
- /Volumes/NAS_1/Immich/upload (all iPhone photos)
- /Volumes/NAS_1/Immich/database (metadata, faces, albums)
- /Volumes/NAS_1/Photos (existing photos)

Weekly backup protects everything ✅
```

**Can delete from iPhone after upload:**
```
1. Verify photo uploaded (appears in Immich)
2. Delete from iPhone Photos app
3. Free up iPhone storage
4. Photo safe on NAS + weekly backup ✅
```

---

## Maintenance

### Updating Immich

```bash
cd ~/immich-app

# Pull latest version:
docker compose pull

# Restart services:
docker compose down
docker compose up -d

# Check version:
# Web UI → Administration → Server Info
```

**Update frequency:** Monthly (check GitHub releases)

### Monitoring

```bash
# Check service status:
docker compose ps

# View logs:
docker compose logs -f immich-server

# Check disk usage:
du -sh /Volumes/NAS_1/Immich/
```

### Database Maintenance

```bash
# Vacuum database (monthly):
docker exec -it immich-postgres psql -U postgres -d immich -c "VACUUM ANALYZE;"

# Check database size:
docker exec -it immich-postgres psql -U postgres -d immich -c "SELECT pg_size_pretty(pg_database_size('immich'));"
```

---

## Troubleshooting

### Immich Won't Start

```bash
# Check Docker is running:
docker ps

# If empty, start Docker Desktop
# Then:
cd ~/immich-app
docker compose up -d
```

### Can't Connect from iPhone

**On local network:**
```bash
# Check Mac's local IP:
ipconfig getifaddr en1  # For Ethernet
# Or:
ipconfig getifaddr en0  # For WiFi

# Use: http://[IP]:2283
```

**Via Tailscale:**
```bash
# Check Tailscale IP:
tailscale ip -4

# Use: http://[Tailscale-IP]:2283

# Verify Tailscale is running:
tailscale status
```

### Photos Not Uploading

**Check iPhone app:**
```
1. Backup tab → Check status
2. Settings → Background Backup: ON
3. Check WiFi/cellular settings
4. Try manual upload: Select photo → Upload
```

**Check server:**
```bash
# View upload logs:
docker compose logs -f immich-server | grep upload
```

### Slow Performance

**Initial indexing (normal):**
```
First time: Takes hours to index large library
CPU usage: High during ML processing
Temporary: Performance improves after initial scan
```

**Optimize:**
```bash
# Increase ML workers (if you have RAM):
# Edit docker compose.yml:
# Set IMMICH_WORKERS=4 (default is 2)
```

### Database Full

```bash
# Clean up old thumbnails:
docker exec -it immich-server immich-admin cleanup

# Remove duplicate assets:
docker exec -it immich-server immich-admin deduplicate
```

---

## Advanced Configuration

### HTTPS with Reverse Proxy (Optional)

**For HTTPS access (more secure):**

```bash
# Use Caddy or nginx as reverse proxy
# Example with Caddy:
brew install caddy

# Caddyfile:
immich.local {
    reverse_proxy localhost:2283
}

# Access: https://immich.local
```

### Custom Domain via Tailscale MagicDNS

```bash
# Tailscale MagicDNS (included free):
# Automatically creates hostname

# Instead of: http://100.x.x.x:2283
# Use: http://nas-mac:2283

# Enable in Tailscale admin:
# https://login.tailscale.com/admin/dns
# Enable MagicDNS
```

### Multiple Users (Family Photo Backup)

**Perfect for:** Both you and your wife backing up iPhones to same NAS with complete privacy.

**How it works:**
- Single Immich instance (one installation)
- Multiple user accounts (each person gets their own)
- Same upload location (Immich manages separation internally)
- Complete privacy (wife can't see your photos, you can't see hers)
- Optional sharing via albums

#### Step 1: Create Admin Account (First User)

```
# During initial setup (Step 6):
1. Open http://localhost:2283
2. Create admin account (this is YOU):
   Email: your-email@example.com
   Password: [strong password]
   Name: Your Name
3. Click "Sign Up"
```

#### Step 2: Create Additional User Account (Wife)

```
# After admin setup:
1. Login as admin
2. Click user icon (top right) → Administration → Users
3. Click "Create User"
4. Fill in details:
   Email: wife-email@example.com
   Password: [generate strong password]
   Name: Wife's Name
   Storage quota: Unlimited (or set limit like 500GB)
5. Click "Create"
6. Give your wife her login credentials
```

#### Step 3: Connect iPhones

**Your iPhone:**
```
1. Install Immich app from App Store
2. Server URL: http://100.x.x.x:2283 (Tailscale IP)
3. Email: your-email@example.com
4. Password: your password
5. Enable auto-backup
6. Your photos upload to your private library
```

**Wife's iPhone:**
```
1. Install Immich app from App Store
2. Server URL: http://100.x.x.x:2283 (SAME server)
3. Email: wife-email@example.com
4. Password: her password
5. Enable auto-backup
6. Her photos upload to her private library
```

#### Storage Structure (Automatic)

**Single upload location in .env:**
```bash
UPLOAD_LOCATION=/Volumes/NAS_1/Immich/upload

# Immich organizes internally:
/Volumes/NAS_1/Immich/upload/
├── library/
│   ├── user_hash_1/     ← Your photos (managed by Immich)
│   └── user_hash_2/     ← Wife's photos (managed by Immich)
└── thumbs/
```

**No need to modify .env for multiple users** - default config handles it perfectly.

#### Privacy & Separation

**Complete isolation:**
- ✅ Each user sees ONLY their own photos
- ✅ Separate timelines, albums, search results
- ✅ Separate face recognition databases
- ✅ No way to accidentally see each other's photos
- ✅ Admin can manage users but NOT see their photos

**As admin, you can:**
- View storage usage per user
- Create/delete user accounts
- Reset passwords
- BUT NOT view other users' actual photos (unless shared)

#### Sharing Photos Between Users (Optional)

**Create shared album:**
```
1. User 1: Create album "Family Vacation"
2. Add photos to album
3. Click "Share" button
4. Select "wife-email@example.com" (internal share)
5. Wife can now see those specific photos in shared album
6. Other photos remain completely private
```

**Both users can contribute:**
```
1. Create shared album "Our Wedding"
2. Share with wife
3. Both upload photos to it
4. Both see all photos in that album
5. Private photos remain separate
```

#### Storage Quotas (Optional)

**Set per-user limits:**
```
Administration → Users → Edit User
Storage quota: 500 GB (or unlimited)

Useful if:
- One person takes significantly more photos
- Want to prevent filling up entire NAS
- Need to allocate space fairly
```

**Monitor usage:**
```
Administration → Users
See storage used per user:
- Your Name: 120 GB / Unlimited
- Wife's Name: 85 GB / Unlimited
```

#### Backup Strategy (All Users)

**Weekly restic backup includes ALL users:**
```bash
# Backs up:
/Volumes/NAS_1/Immich/upload  ← Both users' photos

# Database tracks ownership
# Restore preserves user separation
```

**Each user's photos protected** ✅

#### Alternative: Physical Folder Separation (Not Recommended)

**If you REALLY want separate folders on NAS:**

Use External Libraries feature instead:
```yaml
# docker compose.yml
volumes:
  - /Volumes/NAS_1/Immich/upload:/usr/src/app/upload
  - /Volumes/NAS_1/Photos/Husband:/usr/src/app/external/Husband:ro
  - /Volumes/NAS_1/Photos/Wife:/usr/src/app/external/Wife:ro

# Then create external libraries and assign to users
# But this is MORE complex and LESS flexible than default multi-user setup
```

**Recommendation:** Use default multi-user setup (simpler, better)

#### Summary: Multi-User Setup

**Single Immich instance:**
- ✅ One installation, multiple users
- ✅ Same server URL for everyone
- ✅ Same UPLOAD_LOCATION in .env
- ✅ Complete privacy automatically enforced
- ✅ Optional sharing via albums
- ✅ All photos backed up together

**Setup time:** 5 minutes to add each user
**Perfect for:** Families, couples, roommates

---

## Performance Expectations

### Indexing Speed (M1 Mac)

```
Photos: ~100-200 per minute (with ML processing)
10,000 photos: 1-2 hours
100,000 photos: 10-20 hours

Run overnight for large collections
```

### Upload Speed (iPhone via Tailscale)

```
Limited by home upload bandwidth:
- 20 Mbps upload: ~2.5 MB/s (1GB in 7 min)
- 50 Mbps upload: ~6 MB/s (1GB in 3 min)

On local WiFi: 30-50 MB/s (much faster)
```

### Storage Usage

```
Original photos: Your actual photo size
Thumbnails: ~1-2% of original size
Database: ~100MB per 10,000 photos
Video transcodes: Varies (can disable)

Example:
100GB photos + videos
= 100GB originals
+ 1-2GB thumbnails
+ 100MB database
= ~102GB total
```

---

## Security Best Practices

### Recommended Setup

```
✅ Use Tailscale for remote access (encrypted)
✅ Strong admin password (16+ characters)
✅ Keep Immich updated (monthly)
✅ Don't expose port 2283 to internet
✅ Use HTTPS with reverse proxy (optional)
```

### What NOT to Do

```
❌ Port forward 2283 to internet (use Tailscale instead)
❌ Use weak password
❌ Share admin account (create separate users)
❌ Disable authentication
```

---

## Comparison to Alternatives

### Immich vs Google Photos

| Feature | Google Photos | Immich |
|---------|---------------|--------|
| **Privacy** | Google sees everything ❌ | 100% private ✅ |
| **Cost** | $2-10/month | Free (hardware only) ✅ |
| **Storage** | Limited by plan | Limited by NAS size ✅ |
| **Auto-upload** | ✅ | ✅ |
| **AI features** | ✅ | ✅ |
| **Sharing** | ✅ | ✅ (via Tailscale) |
| **Mobile app** | ✅ | ✅ |

### Immich vs PhotoPrism

| Feature | PhotoPrism | Immich |
|---------|------------|--------|
| **Mobile auto-upload** | ❌ No native app | ✅ Native app |
| **Maturity** | More stable | Newer, rapid development |
| **UI** | Classic web | Modern mobile-first ✅ |
| **Resource usage** | Lower | Higher |
| **Best for** | Existing collections | iPhone backup + browse |

---

## Summary

**What you get:**
- ✅ Automatic iPhone photo backup to NAS
- ✅ AI-powered organization and search
- ✅ Access from anywhere via Tailscale
- ✅ Complete privacy (no cloud)
- ✅ Google Photos experience, self-hosted

**Setup time:** 30-60 minutes
**Maintenance:** ~15 minutes/month (updates)
**Cost:** $0 (free, open source)

**Next steps:**
1. Install Docker Desktop
2. Set up Immich (follow steps above)
3. Install iPhone app
4. Enable auto-backup
5. Let it index overnight
6. Enjoy private photo management!

---

## Resources

- **Official docs:** https://immich.app/docs/overview/introduction
- **GitHub:** https://github.com/immich-app/immich
- **Discord community:** https://discord.gg/immich
- **Release notes:** https://github.com/immich-app/immich/releases
