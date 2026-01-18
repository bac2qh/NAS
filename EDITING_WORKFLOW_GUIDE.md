# Editing Workflow Guide
## Accessing Mac NAS from Windows PC for Photo/Video Editing

---

## Your Situation

- **NAS**: M1 MacBook Pro with IronWolf Pro 14TB (USB 3.2)
- **Editing PC**: Powerful Windows desktop at home
- **Files**: Large photos (RAW) and videos (up to 50GB, likely 4K/8K)
- **Question**: Edit directly from NAS or copy locally first?

---

## TL;DR - Quick Answer

**It depends on file type and network speed:**

| Content Type | Direct Edit from NAS? | Recommended Workflow |
|--------------|----------------------|----------------------|
| **Photos (RAW)** | ✅ Yes, usually fine | Direct edit via SMB (with caching) |
| **Small videos (<5GB)** | ✅ Yes | Direct edit via SMB |
| **Large videos (>10GB)** | ⚠️ Slow, not recommended | Copy to PC local drive first |
| **4K/8K editing** | ❌ No, will be sluggish | Copy to PC NVMe/SSD first |
| **Proxy workflows** | ✅ Yes | Keep proxies on NAS, edit those |
| **Exporting/rendering** | ⚠️ Possible but slower | Render to PC, then copy to NAS |

---

## Performance Bottlenecks

### Your NAS Setup Speed Limits

1. **Drive speed** (IronWolf Pro via USB 3.2):
   - Sequential read: ~400 MB/s
   - Sequential write: ~400 MB/s
   - ✅ **Not the bottleneck**

2. **Network speed** (THIS is your bottleneck):
   - **Gigabit Ethernet** (1000 Mbps): ~100-110 MB/s real-world
   - **Wi-Fi 6** (802.11ax): ~75-110 MB/s
   - **Wi-Fi 5** (802.11ac): ~40-50 MB/s
   - ⚠️ **This limits everything**

3. **Mac NAS overhead**:
   - SMB serving + macOS overhead
   - Realistic: 70-90% of network max speed
   - If Mac is under load (you're using it), performance drops

### Real-World Speed Examples

**Gigabit Ethernet (best case: ~100 MB/s)**:
- Copy 50GB video: ~8-10 minutes
- Copy 1GB of RAW photos (20 files): ~10-15 seconds
- Stream 4K video: Possible but with buffering
- Stream 8K video: Will stutter

**Wi-Fi 5 (typical: ~40-50 MB/s)**:
- Copy 50GB video: ~20-25 minutes
- Copy 1GB of RAW photos: ~20-30 seconds
- Stream 4K video: Occasional buffering
- Edit large files: Frustrating experience

---

## Workflow Recommendations by Content Type

### 1. Photo Editing (Lightroom, Photoshop, Capture One)

**File sizes**: 50-100 MB per RAW file

**✅ RECOMMENDED: Direct editing from NAS (with smart caching)**

**Why it works**:
- Photo editors use smart caching (load previews first)
- You're typically working on one photo at a time
- 50-100 MB loads in <1 second over gigabit
- Most operations happen in RAM after initial load

**Best practices**:

#### Windows PC Setup
```bash
# 1. Map NAS as network drive
# Open File Explorer → This PC → Map network drive
# Drive letter: Z:
# Folder: \\192.168.1.100\Media\Photos
# Check: "Reconnect at sign-in"
# Check: "Connect using different credentials" (if needed)

# 2. Configure your photo editor for network performance
```

#### Adobe Lightroom Classic Settings
```
Edit → Preferences → Performance:
- Camera Raw Cache: 50GB (on local PC SSD)
- Video Cache: 25GB (on local PC SSD)
- Smart Previews: Generate for all photos

File Handling:
- Build 1:1 Previews: On import
- Preview Quality: High
```

**Lightroom Workflow**:
1. **Import** from NAS to Lightroom catalog
2. **Generate Smart Previews** (creates local cached copies)
3. **Edit** using Smart Previews (works offline, fast)
4. **Export** final images to local PC, then copy to NAS

**Benefit**: You can disconnect from NAS and keep editing!

#### Photoshop Setup
```
Edit → Preferences → Performance:
- Scratch Disk: Local PC SSD (NOT network drive)
- History States: 50
- Cache Levels: 8

Edit → Preferences → File Handling:
- Disable "Save in Background" (can cause network issues)
```

**Photoshop Workflow**:
1. **Open** RAW from NAS (Z:\Photos\)
2. Photoshop loads into RAM (~1-2 seconds)
3. **Edit** normally (all in RAM)
4. **Save** back to NAS (Ctrl+S)
5. Use "Save As" to create copies on local PC if needed

**Verdict**: ✅ **Works well for photos, even over network**

---

### 2. Video Editing (Premiere, DaVinci Resolve, Final Cut)

**File sizes**: 5GB - 50GB per video, 4K/8K footage

**❌ NOT RECOMMENDED: Direct editing large videos from NAS**

**Why it doesn't work well**:
- Video editing requires constant streaming
- 4K/8K needs 200-500 MB/s for smooth scrubbing
- Your network: 100 MB/s max (not enough)
- Result: Stuttering, dropped frames, frustration

**⚠️ EXCEPTION**: Works OK for:
- 1080p or lower resolution
- Proxy workflows (see below)
- Final viewing/archiving

#### Option 1: Copy-Edit-Sync Workflow (Recommended for Large Files)

**Best for**: 4K/8K footage, large projects

```
WORKFLOW:
1. [NAS] Store all original footage
2. [PC] Copy current project to fast local NVMe/SSD
3. [PC] Edit locally (full speed)
4. [PC] Export final video
5. [NAS] Copy final exports back to NAS for archiving
6. [PC] Delete local project files when done
```

**Windows PC Setup**:

```powershell
# Create a "current projects" folder on fast local drive
# Example: C:\VideoProjects\CurrentEdit\

# PowerShell script to sync from NAS
# File: sync_from_nas.ps1

$SOURCE = "\\192.168.1.100\Media\Videos\RawFootage\2024-Project\"
$DEST = "C:\VideoProjects\CurrentEdit\2024-Project\"

# Copy to local PC
robocopy $SOURCE $DEST /E /MT:8 /Z

# After editing, sync back finals only
$FINALS = "C:\VideoProjects\CurrentEdit\2024-Project\Exports\"
$NAS_ARCHIVE = "\\192.168.1.100\Media\Videos\Finals\"
robocopy $FINALS $NAS_ARCHIVE /E /MT:8
```

**Pros**: Full speed (3000+ MB/s), no network dependency, smooth 8K scrubbing
**Cons**: Needs local storage, manual copy operations
**Storage**: 1TB PC NVMe for active projects, NAS for archive

---

#### Option 2: Proxy Workflow (Best Balance)

**Best for**: When you want to "work from NAS" but need performance

**How it works**:
1. Store original 4K/8K footage on NAS
2. Create low-res proxies (1080p or 720p)
3. Edit using proxies (much smaller, streams fine)
4. Conform to originals for final export

**Adobe Premiere Pro Proxy Workflow**:

```
1. Import 4K/8K footage from NAS into project
2. Right-click clips → Proxy → Create Proxies
3. Settings:
   - Format: H.264 (QuickTime)
   - Resolution: 1920x1080 or 1280x720
   - Bitrate: 10-15 Mbps
   - Location: Local PC SSD
4. Premiere auto-generates proxies (takes time initially)
5. Edit using proxies (Toggle: Button in Program Monitor)
6. Export: Premiere uses original 4K/8K files from NAS
```

**DaVinci Resolve Proxy Workflow**:

```
1. Import clips from NAS
2. Right-click → Generate Optimized Media
3. Settings:
   - Format: ProRes Proxy (Mac) or DNxHR LB (Windows)
   - Resolution: Half or Quarter
   - Location: Local cache folder
4. Playback → Proxy Mode → Use Optimized Media
5. Deliver: Uses original files from NAS
```

**Proxy file sizes**:
- Original 4K: 50GB
- Proxy 1080p: 3-5GB (10x smaller!)
- Network can handle proxies easily

**Pros**: Originals on NAS, smooth editing, uses full-quality for export
**Cons**: Time to generate proxies, needs local cache space
**Best for**: 4K/8K editing from NAS

---

### 3. Real-Time Performance Test

**Before committing to a workflow, TEST YOUR NETWORK SPEED:**

#### Test 1: Network Speed Between PC and Mac NAS

**On Windows PC**:

```powershell
# Create a 1GB test file on your PC
fsutil file createnew C:\testfile.bin 1073741824

# Copy to NAS and measure speed
Measure-Command {
    Copy-Item C:\testfile.bin \\192.168.1.100\Shared\testfile.bin
}

# Calculate speed (TotalSeconds should be ~10 sec for 100 MB/s)
# Speed (MB/s) = 1024 / TotalSeconds

# Copy back from NAS to PC
Measure-Command {
    Copy-Item \\192.168.1.100\Shared\testfile.bin C:\testfile_back.bin
}

# Clean up
Remove-Item C:\testfile.bin
Remove-Item C:\testfile_back.bin
Remove-Item \\192.168.1.100\Shared\testfile.bin
```

**Interpret results**:
- **100+ MB/s**: ✅ Good! Photos work great, 1080p video OK
- **50-100 MB/s**: ⚠️ Photos OK, video needs proxies
- **<50 MB/s**: ❌ Poor, copy large files locally first

#### Test 2: Actual Video Playback

**Test on Windows PC**:
1. Map NAS drive: `\\192.168.1.100\Media`
2. Navigate to a 4K video file on NAS
3. Open in VLC Media Player
4. Try scrubbing timeline back and forth
5. Check for stuttering or buffering

**If it stutters**: Network too slow for direct editing

---

## Optimizing Network Performance

### 1. Use Ethernet (Not Wi-Fi)

**Both Mac NAS and Windows PC should use Ethernet**

**For Mac NAS**:
- Connect via USB-C to Gigabit Ethernet adapter
- Or use built-in Ethernet (if available)
- Disable Wi-Fi when using Ethernet

**For Windows PC**:
- Use motherboard Ethernet port
- Ensure NIC is gigabit capable
- Check: Device Manager → Network Adapters → Properties → Link Speed: 1 Gbps

**Speed improvement**: 2-3x faster than Wi-Fi

---

### 2. Network Infrastructure

**Router/Switch Requirements**:
- ✅ Gigabit switch (1000 Mbps)
- ❌ Avoid: Fast Ethernet (100 Mbps) - too slow
- Consider: 2.5 Gbps or 10 Gbps for future (requires compatible NICs)

**Optimal setup**:
```
[Mac NAS] --Ethernet--> [Gigabit Switch] <--Ethernet-- [Windows PC]
                              |
                         [Router/Internet]
```

---

### 3. SMB Performance Tuning

#### On Mac NAS

Create optimization script:

```bash
# File: ~/Scripts/optimize_smb_performance.sh

#!/bin/bash

# ⚠️ ⚠️ ⚠️ CRITICAL SECURITY WARNING ⚠️ ⚠️ ⚠️
# Disabling SMB signing removes encryption and authentication protections!
# ONLY do this on a PRIVATE, TRUSTED home network completely isolated from internet.
# Anyone on your network could potentially intercept file transfers.
# If you connect this Mac to public Wi-Fi, RE-ENABLE signing immediately!
# To re-enable: sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smbd SigningEnabled -bool true

# Disable SMB signing for maximum speed (DANGEROUS - read warning above!)
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smbd SigningEnabled -bool false

# Set SMB minimum protocol version (SMB3 is faster)
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smbd MinProtocolVersion -int 3

# Increase SMB buffer sizes
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smbd MaxBufferSize -int 65536

# Restart SMB service
sudo launchctl kickstart -k system/com.apple.smbd

echo "SMB optimized for performance"
```

**⚠️ Security note**: Disabling SMB signing reduces security. Only do this on trusted home networks.

#### On Windows PC

**Optimize SMB client**:

```powershell
# Run as Administrator in PowerShell

# Ensure SMB3 is enabled (faster than SMB2)
Set-SmbClientConfiguration -EnableMultiChannel $true

# Disable SMB signing for performance (trusted network only)
Set-SmbClientConfiguration -RequireSecuritySignature $false

# Increase network buffer sizes
Set-SmbClientConfiguration -FileInfoCacheLifetime 30
Set-SmbClientConfiguration -DirectoryCacheLifetime 30

# Restart SMB client
Restart-Service -Name LanmanWorkstation -Force
```

**Expected improvement**: 10-20% faster transfers

---

### 4. Upgrade Path: Faster Networking

If you find gigabit too slow:

**Option A: 2.5 Gbps Ethernet**
- Cost: ~$50-100 for adapters/switch
- Speed: 2.5x faster (250 MB/s real-world)
- Good for: 4K editing from NAS

**Option B: 10 Gbps Ethernet**
- Cost: ~$200-500 (NICs + switch)
- Speed: 10x faster (800-900 MB/s real-world)
- Good for: 8K editing, professional workflows
- **Note**: Mac USB-C to 10GbE adapters exist (~$200)

**Option C: Thunderbolt Direct Connection**
- Mac to PC via Thunderbolt cable
- Speed: 40 Gbps (Thunderbolt 4)
- Complex setup, requires compatible hardware
- Usually not worth it for NAS use case

---

## Recommended Workflows by Scenario

### Scenario 1: Photographer (RAW Photos)

**Setup**:
- ✅ Work directly from NAS via SMB
- Use Lightroom Smart Previews
- Generate 1:1 previews on import

**Daily Workflow**:
1. Import photos from camera to PC
2. Copy to NAS: `Z:\Photos\2024\Jan\Shoot01\`
3. Import to Lightroom from NAS location
4. Generate Smart Previews (automatic)
5. Edit using Smart Previews (can work offline)
6. Export finals to: `C:\Exports\`
7. Copy finals back to NAS: `Z:\Photos\Finals\2024\`

**Storage**:
- NAS: All RAW originals + finals
- PC: Lightroom catalog + Smart Previews cache

---

### Scenario 2: Casual Video Editor (1080p, <5GB files)

**Setup**:
- ✅ Work directly from NAS via SMB
- Keep project files local
- Export to NAS when done

**Daily Workflow**:
1. Import footage from camera to PC
2. Copy to NAS: `Z:\Videos\RawFootage\2024\Project01\`
3. Open Premiere/Resolve
4. Import from NAS location
5. Edit (may have occasional buffering)
6. Export to: `C:\Exports\Project01_Final.mp4`
7. Copy final to NAS: `Z:\Videos\Finals\`
8. Keep project files on PC temporarily

**Works well for**:
- 1080p footage
- Short projects (<30 minutes)
- Not too many tracks/effects

---

### Scenario 3: Serious Video Editor (4K/8K, 10GB+ files)

**Setup**:
- ❌ Don't work directly from NAS
- ✅ Use Proxy workflow OR
- ✅ Copy-edit-archive workflow

#### Option A: Proxy Workflow

**Daily Workflow**:
1. Import 4K/8K to NAS: `Z:\Videos\RawFootage\2024\BigProject\`
2. Import to editing software from NAS
3. Generate proxies to: `C:\VideoProjects\ProxyCache\BigProject\`
4. Edit using proxies (smooth, fast)
5. Export (uses original 4K/8K from NAS automatically)
6. Copy final to: `Z:\Videos\Finals\BigProject_Final.mp4`

**Storage needed**:
- PC: ~500GB for proxy cache
- NAS: All originals + finals

#### Option B: Local Editing Workflow

**Daily Workflow**:
1. Copy current project from NAS to PC NVMe:
   ```powershell
   robocopy "\\192.168.1.100\Media\Videos\RawFootage\BigProject" "C:\VideoProjects\BigProject" /E /MT:8
   ```
2. Edit locally (full speed)
3. Export final: `C:\VideoProjects\BigProject\Exports\`
4. Copy final to NAS:
   ```powershell
   robocopy "C:\VideoProjects\BigProject\Exports" "\\192.168.1.100\Media\Videos\Finals\BigProject" /E
   ```
5. Archive: Copy entire project to NAS
   ```powershell
   robocopy "C:\VideoProjects\BigProject" "\\192.168.1.100\Media\Videos\Archive\BigProject" /E
   ```
6. Delete local project:
   ```powershell
   Remove-Item -Recurse -Force "C:\VideoProjects\BigProject"
   ```

**Storage needed**:
- PC: 1-2TB NVMe for active projects
- NAS: Archive everything

---

### Scenario 4: Mixed Photo + Video (Your Likely Use Case)

**Setup**:
- Photos: Work from NAS
- Videos: Proxy or local editing

**Folder structure on NAS**:
```
/Volumes/NAS_Primary/Media/
├── Photos/
│   ├── RAW/
│   │   ├── 2024/
│   │   │   ├── January/
│   │   │   └── February/
│   └── Finals/
│       └── 2024/
├── Videos/
│   ├── RawFootage/
│   │   └── 2024/
│   ├── Projects/ (optional, if storing project files)
│   └── Finals/
│       └── 2024/
└── Assets/
    ├── Music/
    ├── SFX/
    └── LUTs/
```

**PC folder structure**:
```
C:\
├── VideoProjects\
│   ├── CurrentEdit\  (active projects)
│   └── ProxyCache\   (proxy files)
└── Exports\          (temporary export location)

D:\  (Optional fast storage for photos)
├── LightroomCache\
└── PhotoshopScratch\
```

---

## Software-Specific Tips

### Adobe Lightroom Classic

```
Performance Optimizations:
1. Catalog location: Local PC SSD
2. Camera Raw Cache: Local PC SSD, 50GB
3. Smart Previews: Always generate
4. Preview Quality: High or Medium
5. Preview Size: 2540 pixels (for 4K displays)

Network Considerations:
- Works well over gigabit network
- Ensure "Build 1:1 Previews" on import
- Use Smart Previews for disconnected editing
```

### Adobe Premiere Pro

```
Performance Optimizations:
1. Project files: Local PC SSD
2. Media Cache: Local PC SSD, 50GB
3. Scratch Disks: Local PC SSD (NOT network)
4. Use proxies for 4K+ footage from NAS

Project Settings:
- Playback Resolution: 1/2 or 1/4 during editing
- Renderer: GPU Acceleration (CUDA/Metal)
- Proxy: H.264 1080p or 720p
```

### DaVinci Resolve

```
Performance Optimizations:
1. Database: Local PC
2. Cache: Local PC SSD, 50GB
3. Optimized Media: Local PC (proxies)
4. Render cache: Local PC

Playback Settings:
- Playback → Timeline Proxy Mode → Half Resolution
- Playback → Render Cache → Smart
- Use Optimized Media for 4K+ from NAS
```

### Capture One

```
Performance Optimizations:
1. Catalog: Local PC SSD
2. Cache: Local PC SSD, 25GB
3. Processing: 100% previews on import

Network Considerations:
- Works well over gigabit
- Use Sessions (not Catalogs) if working from NAS
- Generate 100% previews immediately
```

---

## Troubleshooting Network Editing Issues

### Problem: Video playback stutters from NAS

**Diagnosis**:
```powershell
# Check network speed
ping 192.168.1.100 -n 100
# Should show: <1ms latency, 0% packet loss

# Test sustained throughput
# Copy a large file and measure speed
```

**Solutions**:
1. ✅ Switch from Wi-Fi to Ethernet
2. ✅ Use proxy workflow
3. ✅ Copy files locally for editing
4. ✅ Upgrade to 2.5 Gbps network

---

### Problem: Files take forever to open in Photoshop

**Diagnosis**:
- Large PSD files over network are slow
- Check if Scratch Disk is set to network (bad!)

**Solutions**:
```
1. Edit → Preferences → Performance
   - Set Scratch Disk to local PC SSD
2. Edit → Preferences → File Handling
   - Disable "Save in Background"
3. Consider: Open, then "Save As" copy to local drive for heavy editing
```

---

### Problem: Lightroom catalog is slow

**Diagnosis**:
- Catalog stored on network drive (terrible performance!)

**Solution**:
```
1. File → Catalog Settings → General
   - Check catalog location
   - Should be: C:\Users\[You]\Pictures\Lightroom\
2. If on network:
   - Export catalog as LRCAT file
   - Import to local PC location
```

---

### Problem: Random disconnections from NAS

**Possible causes**:
1. Mac going to sleep (check power settings)
2. Network timeout settings
3. SMB version mismatch

**Solutions**:

**On Mac**:
```bash
# Prevent disk sleep
sudo pmset -a disksleep 0

# Prevent system sleep when plugged in
sudo pmset -c sleep 0

# Use Amphetamine app to keep awake when NAS drives mounted
```

**On Windows PC**:
```powershell
# Increase SMB timeout
Set-SmbClientConfiguration -SessionTimeout 300

# Keep network adapter alive
# Control Panel → Network Adapter Properties → Power Management
# Uncheck "Allow computer to turn off this device"
```

---

## Recommended Workflow

**Photos**: Edit directly from NAS via SMB
- Use Lightroom Smart Previews
- Requires Gigabit Ethernet
- Works well for RAW files

**Videos**: Use proxy workflow for 4K/8K
- Keep originals on NAS
- Edit with proxies on PC SSD
- Or copy large projects to PC NVMe, edit, then archive

**Network**: Both Mac and PC via Gigabit Ethernet (2.5 Gbps for 4K editing)

**Storage**:
- NAS (14TB): All originals + finals
- PC SSD (500GB-1TB): Proxies, cache
- PC NVMe (1TB): Active video editing

---

## Summary

- **Photos**: ✅ Edit directly from NAS
- **Small videos (<5GB)**: ✅ May work, test first
- **Large videos (>10GB, 4K/8K)**: ⚠️ Use proxies or copy locally

**Test your network speed first**, then adjust workflow based on actual performance.

---

## Quick Decision Matrix

| Your Situation | Recommendation |
|---------------|----------------|
| Editing RAW photos (50-100MB) | ✅ Direct from NAS |
| Editing 1080p video (<5GB) | ✅ Direct from NAS (may buffer) |
| Editing 4K video (10-50GB) | ⚠️ Proxy workflow recommended |
| Editing 8K video (50GB+) | ❌ Copy to PC NVMe first |
| Have fast Ethernet (1Gbps+) | More options work directly |
| On Wi-Fi only | ❌ Copy large files locally |
| PC has limited storage (<500GB free) | ✅ Must use proxy workflow |
| PC has plenty of storage (1TB+ free) | ✅ Copy-edit-archive workflow |

Run the network speed test, try direct editing, and adjust based on your experience!
