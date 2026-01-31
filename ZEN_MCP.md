# Zen MCP Server Setup Guide

This document describes how to connect Zen MCP (now called PAL MCP) to Claude Code.

## Prerequisites

- Claude Code CLI installed
- `uvx` available (install with `pip install uv` if needed)
- API key for at least one AI provider (Gemini, OpenAI, or OpenRouter)

## Installation

### Method 1: uvx (Recommended)

The package was renamed from `zen-mcp-server` to `pal-mcp-server`. Use the correct executable name:

```bash
claude mcp add -e GEMINI_API_KEY=your_api_key -s user zen -- uvx --from "git+https://github.com/BeehiveInnovations/zen-mcp-server.git" pal-mcp-server
```

### Method 2: npx (May Have Issues)

```bash
claude mcp add -e GEMINI_API_KEY=your_api_key -s user zen -- npx zen-mcp-server-199bio
```

**Warning**: The npx method may fail with Python dependency issues.

## Common Failures and Solutions

### Failure 1: Wrong executable name

**Error:**
```
An executable named `zen-mcp-server` is not provided by package `pal-mcp-server`.
The following executables are available:
- pal-mcp-server
```

**Solution:** Use `pal-mcp-server` instead of `zen-mcp-server` as the executable name.

### Failure 2: npx Python setup fails

**Error:**
```
/home/user/.zen-mcp-server/venv/bin/python: can't open file '/home/user/.zen-mcp-server/run.py': [Errno 2] No such file or directory
```

**Solution:** Use the uvx method instead of npx.

### Failure 3: Missing required argument

**Error:**
```
error: missing required argument 'commandOrUrl'
```

**Solution:** Use `--` before the command and its arguments:
```bash
# Wrong
claude mcp add -e KEY=value zen "npx" "package"

# Correct
claude mcp add -e KEY=value zen -- npx package
```

### Failure 4: Invalid environment variable format

**Error:**
```
Invalid environment variable format: zen, environment variables should be added as: -e KEY1=value1 -e KEY2=value2
```

**Solution:** Put `-e` flag before the server name:
```bash
# Wrong
claude mcp add zen -e KEY=value -- command

# Correct
claude mcp add -e KEY=value zen -- command
```

## Verify Connection

```bash
claude mcp list
```

Expected output:
```
zen: uvx --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git pal-mcp-server - ✓ Connected
```

## Available Tools

After connecting, these tools become available:

| Tool | Description |
|------|-------------|
| `zen` | Quick AI consultation (default tool) |
| `chat` | Collaborative development discussions |
| `thinkdeep` | Extended reasoning with large context models |
| `codereview` | Professional code review |
| `precommit` | Pre-commit validation |
| `debug` | Advanced debugging assistance |
| `analyze` | Smart file and codebase analysis |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Google Gemini API key |
| `OPENAI_API_KEY` | OpenAI API key |
| `OPENROUTER_API_KEY` | OpenRouter API key (access multiple models) |
| `CUSTOM_API_URL` | Custom API endpoint (e.g., Ollama: `http://localhost:11434/v1`) |

## Remove Server

```bash
claude mcp remove zen -s user
```

## References

- [GitHub - BeehiveInnovations/pal-mcp-server](https://github.com/BeehiveInnovations/zen-mcp-server)
- [Zen MCP | Awesome MCP Servers](https://mcpservers.org/servers/jray2123/zen-mcp-server)
