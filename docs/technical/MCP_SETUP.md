# MCP Server Setup Guide

This guide helps you configure Model Context Protocol (MCP) servers for FitLog Pro development.

---

## 📋 MCP Servers to Configure

1. **Context7** - Official documentation lookup
2. **Supabase** - Database management and queries
3. **GitHub** - Repository integration and operations

---

## 🔧 Setup Instructions

### Prerequisites

- Node.js 18+ installed
- npm or yarn package manager
- Git configured
- Supabase account (for Supabase MCP)
- GitHub account (for GitHub MCP)

---

## 1. Context7 MCP Server

**Purpose**: Access official documentation for Flutter, Dart, Supabase, and other libraries.

### Installation

```bash
# Install Context7 MCP globally
npm install -g @context7/mcp-server

# Or using npx (no installation needed)
npx @context7/mcp-server
```

### Configuration

Add to your Claude Desktop `claude_desktop_config.json`:

**Location:**
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

### Verification

After restart, Context7 should appear in Claude's MCP server list. Test with:
```
"Look up Flutter Riverpod documentation"
```

---

## 2. Supabase MCP Server

**Purpose**: Manage Supabase databases, run queries, and handle authentication directly from Claude.

### Installation

```bash
# Install Supabase MCP server
npm install -g @supabase/mcp-server

# Or use npx
npx @supabase/mcp-server
```

### Get Supabase Credentials

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (or create new one: "FitLog Pro")
3. Go to **Settings** → **API**
4. Copy:
   - Project URL: `https://xxxxx.supabase.co`
   - Service Role Key: `eyJhbG...` (keep secret!)

### Configuration

Add to `claude_desktop_config.json`:

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
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "your-service-role-key"
      }
    }
  }
}
```

### Create .env File

For local development, create `.env` in project root:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**⚠️ Important**: `.env` is already in `.gitignore` - never commit credentials!

### Verification

Test Supabase connection:
```
"List tables in Supabase database"
"Create a new table called 'clients'"
```

---

## 3. GitHub MCP Server

**Purpose**: Manage GitHub repositories, issues, pull requests, and workflows.

### Installation

```bash
# Install GitHub MCP server
npm install -g @github/mcp-server

# Or use npx
npx @github/mcp-server
```

### Get GitHub Token

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Give it a name: "FitLog Pro MCP"
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
   - ✅ `read:org` (Read org and team membership)
5. Generate and copy the token (save it securely!)

### Configuration

Add to `claude_desktop_config.json`:

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
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "your-service-role-key"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@github/mcp-server"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

### Verification

Test GitHub connection:
```
"List my GitHub repositories"
"Show open issues in FitLog Pro repository"
```

---

## 📝 Complete Configuration Example

Here's your complete `claude_desktop_config.json`:

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
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "your-service-role-key"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@github/mcp-server"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_github_token"
      }
    }
  },
  "globalShortcut": "Ctrl+Space"
}
```

---

## 🎯 Usage Examples

### Context7 - Documentation Lookup

```
✅ "Show me Flutter Riverpod StateNotifier examples"
✅ "How do I use Supabase realtime subscriptions in Flutter?"
✅ "What are best practices for Go Router navigation?"
✅ "Show Drift database schema examples"
```

### Supabase - Database Operations

```
✅ "Create users table with email, role, and created_at columns"
✅ "Add Row Level Security policy for clients table"
✅ "Query all active sessions for trainer with ID xyz"
✅ "Create Supabase Edge Function for AI workout generation"
✅ "Set up Supabase Storage bucket for body photos"
```

### GitHub - Repository Management

```
✅ "Create new issue: Implement authentication flow"
✅ "Show status of CI/CD workflow"
✅ "List all open pull requests"
✅ "Create branch: feature/session-logging"
✅ "Review latest commits on main branch"
```

---

## 🔍 Verification Checklist

After configuration and restart:

- [ ] Context7 appears in MCP servers list
- [ ] Supabase appears in MCP servers list
- [ ] GitHub appears in MCP servers list
- [ ] Can query Flutter documentation via Context7
- [ ] Can list Supabase tables
- [ ] Can list GitHub repositories

---

## 🚨 Troubleshooting

### MCP Server Not Showing

1. Restart Claude Desktop completely
2. Check `claude_desktop_config.json` for syntax errors (use JSON validator)
3. Verify Node.js is installed: `node --version`
4. Check npm global path: `npm root -g`

### Context7 Not Working

```bash
# Test installation
npx @context7/mcp-server --version

# Reinstall
npm uninstall -g @context7/mcp-server
npm install -g @context7/mcp-server
```

### Supabase Connection Failed

- Verify `SUPABASE_URL` format: `https://xxxxx.supabase.co`
- Check Service Role Key (not Anon Key!)
- Ensure project is not paused in Supabase dashboard
- Test with Supabase CLI: `supabase projects list`

### GitHub Token Invalid

- Regenerate token with correct scopes
- Ensure token hasn't expired
- Test with: `curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user`

---

## 🔐 Security Best Practices

1. **Never commit tokens/keys**
   - Use `.env` files (already gitignored)
   - Store in `claude_desktop_config.json` (outside repo)

2. **Use minimum required permissions**
   - Supabase: Service Role Key only for MCP
   - GitHub: Only necessary scopes

3. **Rotate credentials regularly**
   - Generate new tokens every 90 days
   - Revoke old tokens

4. **Team collaboration**
   - Each developer uses their own tokens
   - Document setup process for onboarding

---

## 📚 Additional Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Context7 GitHub](https://github.com/context7/mcp-server)
- [Supabase MCP](https://supabase.com/docs/guides/cli/mcp)
- [GitHub MCP](https://github.com/github/mcp-server)

---

## 🎉 Next Steps

Once MCP servers are configured:

1. Test each server with verification commands
2. Create Supabase database schema for FitLog Pro
3. Initialize GitHub repository
4. Begin Phase 0 implementation with enhanced tooling!

---

**Setup Time**: ~15 minutes
**Required Restarts**: 1 (Claude Desktop)
**Difficulty**: Easy

---

Need help? Open an issue or ask in discussions!
