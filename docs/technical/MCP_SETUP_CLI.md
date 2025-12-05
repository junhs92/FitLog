# MCP Server Setup Guide - Claude CLI

**FitLog Pro Project-Specific MCP Configuration**

This guide explains how to set up Model Context Protocol (MCP) servers for the FitLog Pro project using Claude CLI (VSCode extension).

---

## 📋 Overview

### Hybrid Configuration Approach

FitLog Pro uses a **hybrid MCP setup**:

**Global Servers** (available for all projects):
- ✅ Context7 - Official documentation lookup
- ✅ Sequential-thinking - Deep analysis
- ✅ Magic - UI generation from 21st.dev
- ✅ Playwright - Browser automation
- ✅ Morphllm - Bulk code transformations
- ✅ Serena - Semantic understanding

**Project Servers** (FitLog Pro specific):
- 🎯 **Supabase FitLog** - Database for project `cqgqzefzgcrvfnjushwk`
- 🎯 **GitHub** - Repository management

### Benefits

- Global tools available everywhere
- FitLog Pro database isolated to this project
- Team can share config (minus secrets)
- Clean separation of concerns

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Get Credentials

#### Supabase Access Token (Required)

1. Go to https://supabase.com/dashboard/account/tokens
2. Click **"Generate New Token"**
3. Settings:
   - Name: `FitLog Pro MCP`
   - Project: Select `cqgqzefzgcrvfnjushwk`
   - Permissions: ✅ Read + ✅ Write
4. Generate and **copy the token** (starts with `sbp_`)

#### GitHub Token (Optional)

1. Go to https://github.com/settings/tokens/new
2. Token name: `FitLog Pro MCP`
3. Select scopes:
   - ✅ `repo` (Full repository access)
   - ✅ `workflow` (GitHub Actions)
4. Generate and **copy the token** (starts with `ghp_`)

### Step 2: Create Environment File

```bash
# In project root
cd "c:\project\Havbit\FitLog Pro\FitLog_Pro_app"

# Copy template
copy .claude\.env.mcp.example .claude\.env.mcp

# Edit with your actual tokens
notepad .claude\.env.mcp
```

**Edit** `.claude/.env.mcp`:
```env
SUPABASE_ACCESS_TOKEN=sbp_your_actual_token_here
GITHUB_TOKEN=ghp_your_actual_token_here
```

### Step 3: Register MCP Servers

**IMPORTANT:** Claude CLI requires explicit registration of MCP servers using the command line.

#### Option A: Automated Setup (Recommended)

Run the provided script:

```bash
cd "c:\project\Havbit\FitLog Pro\FitLog_Pro_app"
scripts\setup_mcp_servers.bat
```

This will register all 8 MCP servers automatically.

#### Option B: Manual Registration

Register each server individually:

```bash
# Global servers
claude mcp add --transport stdio context7 -- npx -y @upstash/context7-mcp@latest
claude mcp add --transport stdio sequential-thinking -- npx -y sequential-thinking-mcp@latest
claude mcp add --transport stdio magic -- npx -y @21st-dev/magic-mcp@latest
claude mcp add --transport stdio playwright -- npx -y @executeautomation/playwright-mcp-server@latest
claude mcp add --transport stdio morphllm -- npx -y morphllm-mcp@latest
claude mcp add --transport stdio serena -- npx -y serena-mcp@latest

# Project-specific servers (replace YOUR_TOKEN with actual values)
claude mcp add --transport stdio --env SUPABASE_ACCESS_TOKEN=YOUR_TOKEN supabase-fitlog -- npx -y @supabase/mcp-server-supabase@latest --project-ref=cqgqzefzgcrvfnjushwk
claude mcp add --transport stdio --env GITHUB_TOKEN=YOUR_TOKEN github -- npx -y @modelcontextprotocol/server-github
```

### Step 4: Restart Claude CLI

1. **Completely quit** VSCode
2. Reopen VSCode
3. Claude CLI will connect to the registered MCP servers

### Step 5: Verify

Ask Claude:
```
"What MCP servers are available?"
```

You should see:
- ✅ supabase-fitlog
- ✅ github
- ✅ context7 (global)
- ✅ sequential-thinking (global)
- ✅ magic (global)
- ✅ playwright (global)

---

## 📁 Configuration Files

### Project MCP Config

**File:** `.claude/mcp.json`

```json
{
  "mcpServers": {
    "supabase-fitlog": {
      "command": "cmd",
      "args": [
        "/c",
        "npx",
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--project-ref=cqgqzefzgcrvfnjushwk"
      ],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "${SUPABASE_ACCESS_TOKEN}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Notes:**
- Project ID `cqgqzefzgcrvfnjushwk` is hard-coded
- Environment variables loaded from `.claude/.env.mcp`
- Windows-compatible with `cmd /c` wrapper

### Environment Template

**File:** `.claude/.env.mcp.example` (committed to repo)

Template for team members to create their own `.env.mcp` file.

**File:** `.claude/.env.mcp` (gitignored, you create this)

Your actual credentials - **never commit this file!**

---

## 🎯 Usage Examples

### Supabase FitLog Pro

#### Create Tables
```
"Create a users table with id, email, role, and created_at columns"
```

#### Query Data
```
"Show all clients for trainer with ID xyz"
```

#### Manage RLS Policies
```
"Create RLS policy so trainers can only see their own clients"
```

#### Set Up Storage
```
"Create storage bucket for body photos with public access"
```

#### Edge Functions
```
"Create Edge Function for AI workout generation"
```

### GitHub

#### Repository Management
```
"Show repository status"
"List open pull requests"
"Create issue: Implement authentication flow"
```

#### Branch Operations
```
"Create branch: feature/session-logging"
"Show recent commits on main"
```

#### Workflow Status
```
"Check CI/CD workflow status"
"Show latest build results"
```

### Global Servers (Already Available)

#### Context7 - Documentation
```
"Show Flutter Riverpod StateNotifier documentation"
"How do I use Supabase realtime in Flutter?"
"What are Go Router best practices?"
```

#### Sequential-thinking - Deep Analysis
```
"Analyze the authentication flow architecture"
"Debug why session logging is slow"
```

#### Magic - UI Generation
```
"Generate login screen with email/password fields"
"Create client card component"
```

---

## 🔧 Troubleshooting

### MCP Servers Not Showing

**Problem:** Servers don't appear in Claude's MCP list

**Solutions:**
1. **Completely restart VSCode** (quit, not just reload window)
2. Check `.claude/mcp.json` syntax (use JSON validator)
3. Verify Node.js installed: `node --version` (need 18+)
4. Check environment file exists: `.claude/.env.mcp`

### Supabase Connection Failed

**Problem:** Supabase MCP not connecting

**Solutions:**
1. Verify token in `.env.mcp` starts with `sbp_`
2. Check project ID is `cqgqzefzgcrvfnjushwk`
3. Ensure token has read+write permissions
4. Confirm project not paused in Supabase dashboard
5. Test token: Open Supabase dashboard with same account

### GitHub Connection Failed

**Problem:** GitHub MCP not working

**Solutions:**
1. Verify token starts with `ghp_`
2. Check token has `repo` and `workflow` scopes
3. Ensure token hasn't expired
4. Regenerate token if needed

### Environment Variables Not Loading

**Problem:** `${VARIABLE}` not replaced with actual value

**Solutions:**
1. Ensure `.env.mcp` exists (not just `.env.mcp.example`)
2. Check file format matches template exactly
3. No quotes around values in `.env.mcp`
4. Restart Claude CLI after creating/editing `.env.mcp`

### First Run Slow

**Problem:** MCP servers take long time on first use

**This is normal!**
- npx downloads packages on first run
- Subsequent runs are fast (packages cached)
- Wait 30-60 seconds for initial connection

---

## 🔐 Security Best Practices

### 1. Never Commit Secrets

✅ **Do commit:**
- `.claude/mcp.json` (config with placeholders)
- `.claude/.env.mcp.example` (template)

❌ **Never commit:**
- `.claude/.env.mcp` (actual credentials)
- `.claude/mcp.local.json` (local overrides)

Already gitignored ✅

### 2. Use Project-Specific Tokens

- Don't reuse personal access tokens
- Create dedicated tokens for FitLog Pro
- Use minimum required permissions

### 3. Rotate Credentials Regularly

- Regenerate tokens every 90 days
- Revoke old tokens after rotation
- Update `.env.mcp` with new tokens

### 4. Team Collaboration

Each team member should:
1. Get their own Supabase/GitHub tokens
2. Create their own `.env.mcp` file
3. Never share tokens via chat/email

---

## 📊 Configuration Overview

```
FitLog Pro MCP Setup
├── Global (~/.claude/.mcp.json)
│   ├── context7          → Documentation
│   ├── sequential        → Deep analysis
│   ├── magic             → UI generation
│   ├── playwright        → Browser testing
│   ├── morphllm          → Code transforms
│   └── serena            → Semantic search
│
└── Project (.claude/mcp.json)
    ├── supabase-fitlog   → Database (cqgqzefzgcrvfnjushwk)
    └── github            → Repository management
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] `.claude/mcp.json` exists
- [ ] `.claude/.env.mcp` created with actual tokens
- [ ] `.claude/.env.mcp` in .gitignore
- [ ] Restarted Claude CLI
- [ ] MCP servers show in Claude interface
- [ ] Can query Context7: "Show Flutter docs"
- [ ] Can query Supabase: "List tables in FitLog Pro"
- [ ] Can query GitHub: "Show repository"

---

## 🎓 Next Steps

With MCP servers configured, you can:

### Phase 0 - Database Setup
```
"Create users table with email, password_hash, role, created_at"
"Create clients table linked to trainers"
"Create sessions table with exercise data"
"Set up RLS policies for trainer access"
"Create storage bucket for body photos"
```

### Development Workflow
```
"Show Riverpod StateNotifier best practices"  (Context7)
"Analyze current authentication flow"         (Sequential)
"Generate login screen component"              (Magic)
"Create feature/auth branch"                   (GitHub)
"Test login form in browser"                   (Playwright)
```

### Repository Management
```
"Create issue for Phase 0 tasks"
"Show open pull requests"
"Check CI/CD status"
```

---

## 📚 Additional Resources

- [MCP Protocol Docs](https://modelcontextprotocol.io/)
- [Supabase MCP Server](https://github.com/supabase/mcp-server-supabase)
- [GitHub MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/github)
- [Context7 Documentation](https://github.com/upstash/context7)

---

## 🆘 Getting Help

**Issues with MCP Setup:**
1. Check this guide first
2. Review error messages carefully
3. Verify credentials are correct
4. Try restarting Claude CLI
5. Open issue in FitLog Pro repository

**Questions:**
- Ask Claude: "Help me debug MCP server connection"
- Check global MCP config: `c:/Users/junny/.claude/.mcp.json`
- Verify Node.js: `node --version`

---

**Setup Time:** ~5 minutes
**Difficulty:** Easy (copy-paste config + get tokens)
**Last Updated:** December 2024

---

🎉 **You're ready to build FitLog Pro with enhanced MCP capabilities!**
