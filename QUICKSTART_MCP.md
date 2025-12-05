# 🚀 Quick MCP Setup for FitLog Pro

## Problem: "No running MCP servers"

This means MCP servers need to be **registered** with Claude CLI using the command line.

## ✅ Solution (2 Steps)

### Step 1: Check if you have `.claude/.env.mcp`

```bash
dir .claude\.env.mcp
```

**If file doesn't exist:**
```bash
copy .claude\.env.mcp.example .claude\.env.mcp
notepad .claude\.env.mcp
```

Add your actual tokens:
```env
SUPABASE_ACCESS_TOKEN=sbp_your_actual_token_here
GITHUB_TOKEN=ghp_your_actual_token_here
```

**Get tokens:**
- Supabase: https://supabase.com/dashboard/account/tokens (project: cqgqzefzgcrvfnjushwk)
- GitHub: https://github.com/settings/tokens/new

### Step 2: Run the setup script

```bash
cd "c:\project\Havbit\FitLog Pro\FitLog_Pro_app"
scripts\setup_mcp_servers.bat
```

This will register 8 MCP servers:
- ✅ Context7 (documentation)
- ✅ Sequential-thinking (deep analysis)
- ✅ Magic (UI generation)
- ✅ Playwright (browser testing)
- ✅ Morphllm (code transformations)
- ✅ Serena (project memory)
- ✅ Supabase FitLog (database)
- ✅ GitHub (repository)

### Step 3: Restart VSCode

1. Close VSCode completely
2. Reopen VSCode
3. Check "Manage MCP Servers" - should show 8 servers running

## 🔍 Verify

Run in terminal:
```bash
claude mcp list
```

Should show all 8 registered servers.

## 📚 Full Documentation

See [docs/technical/MCP_SETUP_CLI.md](docs/technical/MCP_SETUP_CLI.md) for complete guide.
