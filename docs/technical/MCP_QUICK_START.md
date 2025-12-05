# MCP Quick Start - 5 Minutes Setup

Fast track to get Context7, Supabase, and GitHub MCP servers running.

---

## ⚡ Quick Setup (Copy-Paste Ready)

### Step 1: Locate Claude Config File

**Windows:**
```powershell
notepad %APPDATA%\Claude\claude_desktop_config.json
```

**macOS/Linux:**
```bash
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
# or
nano ~/.config/Claude/claude_desktop_config.json
```

### Step 2: Paste This Configuration

Replace entire file contents with:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    },
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server"],
      "env": {
        "SUPABASE_URL": "PASTE_YOUR_SUPABASE_URL_HERE",
        "SUPABASE_SERVICE_ROLE_KEY": "PASTE_YOUR_SERVICE_ROLE_KEY_HERE"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@github/mcp-server"],
      "env": {
        "GITHUB_TOKEN": "PASTE_YOUR_GITHUB_TOKEN_HERE"
      }
    }
  }
}
```

### Step 3: Get Your Credentials

#### Supabase (2 minutes)
1. Go to: https://supabase.com/dashboard
2. Create project: "FitLog Pro" (or use existing)
3. **Settings** → **API** → Copy:
   - Project URL: `https://xxxxx.supabase.co`
   - Service role key: `eyJhbG...`

#### GitHub (2 minutes)
1. Go to: https://github.com/settings/tokens/new
2. Name: "FitLog Pro MCP"
3. Select: ✅ `repo`, ✅ `workflow`
4. Generate → Copy token: `ghp_xxxx...`

### Step 4: Update Config & Restart

1. Replace placeholders in `claude_desktop_config.json`
2. Save file
3. **Completely restart Claude Desktop** (Quit → Reopen)

---

## ✅ Verification (30 seconds)

Ask Claude:

```
1. "What MCP servers are available?"
   → Should show: context7, supabase, github

2. "Show Flutter Riverpod documentation"
   → Tests Context7

3. "List my Supabase tables"
   → Tests Supabase

4. "List my GitHub repositories"
   → Tests GitHub
```

---

## 🎯 You're Ready!

All three MCP servers are now active. You can:

- 📚 Query official docs with Context7
- 🗄️ Manage database with Supabase MCP
- 🐙 Handle GitHub ops with GitHub MCP

**Continue to Phase 0 setup!**

---

## 🚨 Not Working?

**Context7 fails:**
```bash
# Check Node.js
node --version  # Should be 18+

# Test manually
npx @context7/mcp-server --version
```

**Supabase fails:**
- Double-check URL format: `https://xxxxx.supabase.co`
- Use **Service Role Key** (not Anon Key!)
- Project must be active (not paused)

**GitHub fails:**
- Token format: `ghp_xxxxxxxxxxxx`
- Check token hasn't expired
- Verify scopes: repo + workflow

**Still stuck?**
- Restart Claude Desktop again
- Check JSON syntax (use jsonlint.com)
- See full guide: `docs/technical/MCP_SETUP.md`

---

**Total Time**: ~5 minutes
**Difficulty**: Copy-paste easy!
