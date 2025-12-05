@echo off
REM FitLog Pro - MCP Server Registration Script
REM Run this script to register all MCP servers with Claude CLI

echo ========================================
echo FitLog Pro - MCP Server Setup
echo ========================================
echo.

REM Check if .env.mcp exists
if not exist ".claude\.env.mcp" (
    echo [ERROR] .claude\.env.mcp not found!
    echo Please create it from .claude\.env.mcp.example first
    echo.
    pause
    exit /b 1
)

echo Loading environment variables from .claude\.env.mcp...
for /f "tokens=1,2 delims==" %%a in ('type .claude\.env.mcp ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set %%a=%%b
)

echo.
echo ========================================
echo Registering Global MCP Servers
echo ========================================
echo.

echo [1/6] Registering Context7 (Documentation Lookup)...
claude mcp add --transport stdio context7 -- npx -y @upstash/context7-mcp@latest

echo [2/6] Registering Sequential-thinking (Deep Analysis)...
claude mcp add --transport stdio sequential-thinking -- npx -y sequential-thinking-mcp@latest

echo [3/6] Registering Magic (UI Generation)...
claude mcp add --transport stdio magic -- npx -y @21st-dev/magic-mcp@latest

echo [4/6] Registering Playwright (Browser Automation)...
claude mcp add --transport stdio playwright -- npx -y @executeautomation/playwright-mcp-server@latest

echo [5/6] Registering Morphllm (Code Transformations)...
claude mcp add --transport stdio morphllm -- npx -y morphllm-mcp@latest

echo [6/6] Registering Serena (Project Memory)...
claude mcp add --transport stdio serena -- npx -y serena-mcp@latest

echo.
echo ========================================
echo Registering Project-Specific MCP Servers
echo ========================================
echo.

echo [7/8] Registering Supabase FitLog (Database)...
claude mcp add --transport stdio --env SUPABASE_ACCESS_TOKEN=%SUPABASE_ACCESS_TOKEN% supabase-fitlog -- npx -y @supabase/mcp-server-supabase@latest --project-ref=cqgqzefzgcrvfnjushwk

echo [8/8] Registering GitHub (Repository Management)...
claude mcp add --transport stdio --env GITHUB_TOKEN=%GITHUB_TOKEN% github -- npx -y @modelcontextprotocol/server-github

echo.
echo ========================================
echo MCP Server Registration Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Restart VSCode completely
echo 2. Check "Manage MCP Servers" in Claude CLI
echo 3. Verify servers are running
echo.
echo To list all registered servers, run:
echo   claude mcp list
echo.
pause
