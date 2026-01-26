# Clawdbot Setup Guide for NAS

Personal AI assistant running on your M1 Mac NAS with Telegram voice messages and Tailscale remote access.

## Overview

This guide sets up Clawdbot as a personal knowledge base that you can:
- Message via Telegram from anywhere
- Send voice messages that get transcribed automatically
- Query your stored knowledge using natural language
- Access remotely via your existing Tailscale setup

## Prerequisites

### Required
- Node.js >= 22
- Telegram account
- Claude API key (Anthropic) OR Claude Pro/Max subscription (OAuth)

### Already Configured (from your NAS setup)
- Tailscale installed and authenticated
- NordVPN with split tunneling for Tailscale subnet

## Installation

### Step 1: Install Node.js 22

```bash
# Check current version
node --version

# Install Node 22 if needed
brew install node@22

# If you have an older version, link the new one
brew unlink node
brew link node@22

# Verify
node --version  # Should show v22.x.x
```

### Step 2: Install Clawdbot

```bash
# Recommended: Use the install script
curl -fsSL https://clawd.bot/install.sh | bash

# Alternative: npm global install
npm install -g clawdbot@latest
```

### Step 3: Run the Onboarding Wizard

```bash
clawdbot onboard --install-daemon
```

The wizard will guide you through:
1. **Gateway type**: Select `local`
2. **Authentication**: Choose API key or OAuth (see below)
3. **Channels**: Select Telegram
4. **Daemon**: Yes, install as background service

## Authentication Setup

### Option A: Anthropic API Key (Pay-per-use)

1. Get your API key from https://console.anthropic.com/
2. During wizard, enter the key when prompted
3. Cost: ~$15/MTok input, ~$75/MTok output for Opus 4.5

### Option B: Claude Pro/Max OAuth (Subscription)

1. Subscribe to Claude Pro ($20/mo) or Max ($100/mo) at https://claude.ai
2. During wizard, select OAuth authentication
3. Complete browser-based login flow
4. Credentials saved to `~/.clawdbot/credentials/oauth.json`

**Recommendation**: Start with API key for testing, switch to subscription if you use it heavily.

## Telegram Bot Setup

### Step 1: Create Your Bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Choose a name (e.g., "My Knowledge Bot")
4. Choose a username (must end in `bot`, e.g., `myknowledge_bot`)
5. **Save the token** - looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`

### Step 2: Configure Bot Settings in BotFather

```
/setprivacy → Disable (if you want bot to see all messages in groups)
/setjoingroups → Enable (if you want to use in group chats)
/setdescription → Your personal AI knowledge assistant
```

### Step 3: Get Your Telegram User ID

Message [@userinfobot](https://t.me/userinfobot) on Telegram - it will reply with your numeric user ID.

### Step 4: Configure Clawdbot for Telegram

Edit `~/.clawdbot/clawdbot.json`:

```json5
{
  // Agent/model configuration
  agent: {
    model: "anthropic/claude-opus-4-5"  // or claude-sonnet-4-20250514 for cheaper
  },

  // Telegram channel
  channels: {
    telegram: {
      enabled: true,
      botToken: "YOUR_BOT_TOKEN_HERE",

      // Security: Only allow messages from you
      dmPolicy: "allowlist",
      allowFrom: [
        123456789,           // Your numeric user ID
        "@your_username"     // Or your @username
      ]
    }
  }
}
```

**Alternative**: Set token via environment variable (more secure):

```bash
# Add to ~/.zshrc or ~/.bashrc
export TELEGRAM_BOT_TOKEN="your_token_here"
```

Then in config:
```json5
{
  channels: {
    telegram: {
      enabled: true,
      dmPolicy: "allowlist",
      allowFrom: [123456789]
    }
  }
}
```

## Voice Message Configuration

Voice messages are transcribed automatically. The default uses OpenAI's Whisper API, but you can configure alternatives.

### Default (OpenAI Whisper API)

Requires OpenAI API key. Add to config:

```json5
{
  // ... existing config ...

  audio: {
    transcription: {
      provider: "openai",
      model: "whisper-1"
    }
  }
}
```

Set the API key:
```bash
export OPENAI_API_KEY="your_openai_key"
```

### Alternative: Local Whisper (Free, Private)

Install whisper locally on your M1 Mac:

```bash
# Install via Homebrew
brew install openai-whisper

# Or via pip
pip3 install openai-whisper
```

Clawdbot auto-detects local whisper CLI and uses it if available.

### Alternative: Groq (Fast, Free Tier)

```json5
{
  audio: {
    transcription: {
      provider: "groq",
      model: "whisper-large-v3"
    }
  }
}
```

```bash
export GROQ_API_KEY="your_groq_key"
```

## Tailscale Integration (Remote Access)

Since you already have Tailscale configured, you can access Clawdbot's dashboard remotely.

### Option 1: Tailnet-Only Access (Recommended)

Access from any device on your Tailscale network:

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: {
      mode: "serve"
    },
    auth: {
      allowTailscale: true  // Use Tailscale identity for auth
    }
  }
}
```

Access via: `https://your-mac-name.tailnet-name.ts.net/`

### Option 2: Public Access via Funnel

Access from anywhere (requires password):

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: {
      mode: "funnel"
    },
    auth: {
      mode: "password",
      password: "your-secure-password"  // Or use env var
    }
  }
}
```

```bash
export CLAWDBOT_GATEWAY_PASSWORD="your-secure-password"
```

**Note**: Funnel requires Tailscale v1.38.3+ and MagicDNS enabled.

## Workspace Setup (Knowledge Base)

Clawdbot stores files and context in the workspace directory (`~/clawd` by default).

### Directory Structure

```
~/clawd/
├── AGENTS.md          # Agent behavior instructions
├── SOUL.md            # Personality/style guide
├── TOOLS.md           # Tool usage instructions
├── skills/            # Custom skills
│   └── knowledge/     # Your knowledge base skill
│       └── SKILL.md
└── knowledge/         # Store your knowledge files here
    ├── notes/
    ├── references/
    └── projects/
```

### Create a Knowledge Base Skill

Create `~/clawd/skills/knowledge/SKILL.md`:

```markdown
---
name: knowledge
description: Personal knowledge base management
user-invocable: true
---

# Knowledge Base

You have access to a personal knowledge base stored in ~/clawd/knowledge/.

## Storing Information

When the user asks you to remember something:
1. Determine the appropriate category (notes, references, projects, etc.)
2. Create or update a markdown file in the relevant directory
3. Use descriptive filenames with dates when relevant
4. Confirm what was stored and where

## Retrieving Information

When the user asks about something they've stored:
1. Search the knowledge directory for relevant files
2. Read and synthesize the information
3. Provide a clear, contextual response
4. Cite the source file if helpful

## Organization

- ~/clawd/knowledge/notes/ - Quick notes, thoughts, ideas
- ~/clawd/knowledge/references/ - Links, articles, resources
- ~/clawd/knowledge/projects/ - Project-specific information
- ~/clawd/knowledge/people/ - Contact notes, meeting notes
```

### Create Initial Directories

```bash
mkdir -p ~/clawd/knowledge/{notes,references,projects,people}
```

## Starting Clawdbot

### Manual Start (for testing)

```bash
clawdbot gateway --port 18789 --verbose
```

### Daemon Mode (recommended for NAS)

The daemon was installed during onboarding. Manage it with:

```bash
# Check status
clawdbot gateway status

# Start
clawdbot gateway start

# Stop
clawdbot gateway stop

# Restart (after config changes)
clawdbot gateway restart

# View logs
clawdbot gateway logs
```

### Verify Everything Works

```bash
# Overall status
clawdbot status

# Health check
clawdbot health

# Security audit
clawdbot security audit --deep
```

## Usage

### Telegram Commands

Send these in your Telegram chat with the bot:

| Command | Description |
|---------|-------------|
| `/status` | Show session status (model, tokens) |
| `/new` or `/reset` | Clear conversation history |
| `/compact` | Summarize and compress context |
| `/think <level>` | Set thinking depth (off/low/medium/high) |
| `/verbose on\|off` | Toggle detailed responses |

### Voice Messages

Simply send a voice message in Telegram. Clawdbot will:
1. Download the audio file
2. Transcribe using configured provider
3. Process the text as a normal message
4. Respond in text

### Example Interactions

**Storing knowledge:**
```
You: Remember that the wifi password for the cabin is "mountain2024"
Bot: Stored in ~/clawd/knowledge/notes/wifi-passwords.md
```

**Voice message (transcribed):**
```
You: [Voice] "Hey, I just had a meeting with John about the Q2 budget.
      Main points were we need to cut 15% from marketing and
      reallocate to product development."
Bot: I've saved your meeting notes to ~/clawd/knowledge/people/john-meetings.md
     with today's date. Key points recorded:
     - Q2 budget discussion
     - 15% cut from marketing
     - Reallocation to product development
```

**Retrieving knowledge:**
```
You: What's the cabin wifi password?
Bot: The wifi password for the cabin is "mountain2024"
     (from ~/clawd/knowledge/notes/wifi-passwords.md)
```

## Complete Configuration Example

Here's a full `~/.clawdbot/clawdbot.json` for your setup:

```json5
{
  // Model configuration
  agent: {
    model: "anthropic/claude-sonnet-4-20250514"  // Good balance of cost/capability
  },

  // Workspace
  agents: {
    defaults: {
      workspace: "~/clawd"
    }
  },

  // Gateway settings
  gateway: {
    bind: "loopback",
    port: 18789,
    tailscale: {
      mode: "serve"  // Tailnet-only access
    },
    auth: {
      allowTailscale: true
    }
  },

  // Telegram channel
  channels: {
    telegram: {
      enabled: true,
      // Token via TELEGRAM_BOT_TOKEN env var
      dmPolicy: "allowlist",
      allowFrom: [
        123456789  // Replace with your Telegram user ID
      ],
      // Optional: streaming responses
      streamMode: "partial"
    }
  },

  // Audio/voice settings
  audio: {
    transcription: {
      maxBytes: 20971520  // 20MB limit
    }
  },

  // Session behavior
  sessions: {
    scope: "per-sender",
    reset: {
      policy: "idle",
      idleMinutes: 1440  // Reset after 24h idle
    }
  }
}
```

## Autostart on Boot

The daemon should already autostart. To verify:

```bash
# Check launchd service (macOS)
launchctl list | grep clawdbot

# If not running, load it
launchctl load ~/Library/LaunchAgents/com.clawdbot.gateway.plist
```

## Troubleshooting

### Bot doesn't respond

```bash
# Check gateway is running
clawdbot gateway status

# Check logs for errors
clawdbot gateway logs

# Verify Telegram token
clawdbot doctor
```

### Voice messages not transcribing

```bash
# Check if whisper is available locally
which whisper

# Or verify OpenAI API key is set
echo $OPENAI_API_KEY

# Check audio processing logs
clawdbot gateway logs | grep -i audio
```

### Can't access dashboard remotely

```bash
# Verify Tailscale is running
tailscale status

# Check Tailscale serve status
tailscale serve status

# Ensure NordVPN split tunneling includes Tailscale
# (100.64.0.0/10 should be in split tunnel list)
```

### Gateway won't start

```bash
# Validate configuration
clawdbot doctor

# Fix common issues automatically
clawdbot doctor --fix

# Check for port conflicts
lsof -i :18789
```

## Security Notes

1. **Token Security**: Never commit `clawdbot.json` with tokens to git. Use environment variables instead.

2. **Allowlist**: Always use `dmPolicy: "allowlist"` with your user ID to prevent strangers from using your bot.

3. **Tailscale**: Prefer `serve` mode over `funnel` for dashboard access - it's restricted to your tailnet.

4. **Workspace**: The bot can read/write files in `~/clawd`. Don't store sensitive credentials there.

## Maintenance

### Update Clawdbot

```bash
npm update -g clawdbot@latest
clawdbot gateway restart
```

### Backup Knowledge Base

Add to your existing restic backup or:

```bash
# Manual backup
cp -r ~/clawd ~/clawd-backup-$(date +%Y%m%d)
```

### Monitor Usage

```bash
# Check token usage
clawdbot status

# Detailed session info
clawdbot status --all
```

## Quick Reference

| Task | Command |
|------|---------|
| Start gateway | `clawdbot gateway start` |
| Stop gateway | `clawdbot gateway stop` |
| Check status | `clawdbot status` |
| View logs | `clawdbot gateway logs` |
| Health check | `clawdbot health` |
| Fix issues | `clawdbot doctor --fix` |
| Open dashboard | `clawdbot dashboard` |
| Security audit | `clawdbot security audit --deep` |

## Resources

- [Official Documentation](https://docs.clawd.bot)
- [Getting Started](https://docs.clawd.bot/start/getting-started)
- [Telegram Channel](https://docs.clawd.bot/channels/telegram)
- [Tailscale Integration](https://docs.clawd.bot/gateway/tailscale)
- [Skills Guide](https://docs.clawd.bot/tools/skills)
- [Configuration Reference](https://docs.clawd.bot/gateway/configuration)
- [Discord Community](https://discord.gg/clawd)
- [GitHub Repository](https://github.com/clawdbot/clawdbot)
