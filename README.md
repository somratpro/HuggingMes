---
title: HuggingMes
emoji: 🪽
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7861
pinned: true
license: mit
secrets:
  - name: LLM_API_KEY
    description: "Your LLM provider API key for direct providers such as OpenRouter, Anthropic, OpenAI, Google, DeepSeek, xAI, and others."
  - name: LLM_MODEL
    description: "Model or provider model ID, such as openrouter/anthropic/claude-sonnet-4 or openai/gpt-4o."
  - name: GATEWAY_TOKEN
    description: "Strong token to secure your dashboard and API (generate: openssl rand -hex 32)."
  - name: TELEGRAM_BOT_TOKEN
    description: "Telegram bot token from @BotFather."
  - name: TELEGRAM_ALLOWED_USERS
    description: "Comma-separated list of numeric user IDs allowed to use the bot."
  - name: DISCORD_BOT_TOKEN
    description: "Discord bot token from Developer Portal."
  - name: DISCORD_CHANNEL_ID
    description: "Default Discord channel ID for bot messages."
  - name: DISCORD_GUILD_ID
    description: "Discord server (guild) ID."
  - name: DISCORD_WEBHOOK_URL
    description: "Discord webhook URL for notifications."
  - name: HF_TOKEN
    description: "Hugging Face token with write access. Used for automatic workspace backup and HF providers."
  - name: CLOUDFLARE_WORKERS_TOKEN
    description: "Cloudflare API token for automatic Worker proxy and KeepAlive setup."
---

<!-- Badges -->
[![GitHub Stars](https://img.shields.io/github/stars/NousResearch/hermes-agent?style=flat-square)](https://github.com/NousResearch/hermes-agent)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![HF Space](https://img.shields.io/badge/🤗%20HuggingFace-Space-blue?style=flat-square)](https://huggingface.co/spaces)
[![Hermes](https://img.shields.io/badge/Hermes-Agent-indigo?style=flat-square)](https://github.com/NousResearch/hermes-agent)

**Self-hosted Hermes AI agent gateway for Hugging Face Spaces.** HuggingMes runs [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent) on HuggingFace Spaces, giving you a 24/7 personal AI assistant with a management dashboard, persistent HF Dataset backup, and automatic connectivity fixes for blocked outbound traffic. HuggingMes directly wires the startup providers listed below, and it can also use Hermes providers configured through `hermes model` or `config.yaml`.

## Table of Contents

- [✨ Features](#-features)
- [🎥 Video Tutorial](#-video-tutorial)
- [🚀 Quick Start](#-quick-start)
- [🔐 Access Control](#-access-control)
- [🤖 LLM Providers](#-llm-providers)
- [📱 Telegram Setup](#-telegram-setup)
- [🌐 Cloudflare Proxy](#-cloudflare-proxy)
- [💾 Backup & Persistence](#-backup--persistence)
- [📦 Ephemeral Package Re-install](#-ephemeral-package-re-install-optional)
- [🔑 API Key Rotation](#-api-key-rotation-optional)
- [💓 Staying Alive](#-staying-alive-recommended-on-free-hf-spaces)
- [🔐 Security & Advanced](#-security--advanced)
- [💻 Terminal Access (JupyterLab)](#-terminal-access-jupyterlab)
- [🏗️ Architecture](#-architecture)
- [🐛 Troubleshooting](#-troubleshooting)
- [🌟 More Projects](#-more-projects)

## ✨ Features

- 🧠 **Hermes Core:** Runs Hermes Agent for multi-turn chat, tools, memory, and agent workflows.
- 🔐 **Secure by Default:** Protects the dashboard and API with a single gateway token.
- 🌐 **Built-in Connectivity:** Adds Cloudflare Worker proxy support for Telegram and other blocked outbound traffic.
- 📊 **Dashboard:** Real-time view of uptime, sync health, model, provider, and agent status at `/`.
- 💾 **Persistent Backup:** Syncs chats, config, and session data to a private HF Dataset.
- ⏰ **Keep-Alive:** Can provision a cron-triggered Cloudflare Worker to keep the Space awake.
- 💻 **Terminal Out of the Box:** JupyterLab terminal at `/terminal/` auto-enabled when `GATEWAY_TOKEN` is set — no extra config needed.
- 🔄 **Self-Healing Gateway:** Gateway, dashboard, health server, and JupyterLab are all monitored and automatically restarted if they exit unexpectedly.
- 📦 **Ephemeral Package Replay:** Install packages from the terminal and they survive restarts — shell wrappers record `apt`/`pip`/`uv`/`npm`/`hermes` installs and replay them on every boot.
- 🚀 **Startup Scripts:** Run arbitrary bash at boot via `HUGGINGMES_RUN` or `HUGGINGMES_APT/PIP/NPM_PACKAGES` variables.
- 🔑 **API Key Pool Rotation:** Supply comma-separated key pools (e.g. `ANTHROPIC_API_KEYS=key1,key2`) and the first key is promoted automatically.
- 🤖 **Broad Provider Support:** Supports Hermes' native providers, direct API-key providers, OAuth providers, and custom OpenAI-compatible endpoints.

## 🎥 Video Tutorial

Watch a quick walkthrough on YouTube: [Deploying HuggingMes on HF Spaces](https://www.youtube.com/watch?v=kagB1ID-NtE).

## 🚀 Quick Start

### Step 1: Duplicate this Space

[![Duplicate this Space](https://huggingface.co/datasets/huggingface/badges/resolve/main/duplicate-this-space-xl.svg)](https://huggingface.co/spaces/somratpro/HuggingMes?duplicate=true)

### Step 2: Add Your Secrets

In your Space's **Settings → Variables and secrets**, add these under **Secrets**:

- `LLM_API_KEY` - Your provider API key for direct providers.
- `LLM_MODEL` - The model ID to use, such as `openrouter/anthropic/claude-sonnet-4`, `openai/gpt-4o`, or `google/gemini-2.5-flash`.
- `GATEWAY_TOKEN` - A strong token to secure the dashboard.
- `TELEGRAM_BOT_TOKEN` - Telegram bot token from BotFather.
- `TELEGRAM_ALLOWED_USERS` - Comma-separated numeric Telegram user IDs.
- `DISCORD_BOT_TOKEN` - Discord bot token from [Developer Portal](https://discord.com/developers/applications).
- `DISCORD_CHANNEL_ID` - Default Discord channel ID for bot messages.
- `DISCORD_GUILD_ID` - Discord server (guild) ID.
- `DISCORD_WEBHOOK_URL` - Discord webhook URL for notifications.
- `HF_TOKEN` - Hugging Face token with write access for backups and HF providers.
- `CLOUDFLARE_WORKERS_TOKEN` - Cloudflare token for outbound proxying and keep-alive automation.

### Step 3: Deploy & Run

After the Space builds, open it and click **Open Hermes UI** to access the agent interface.

## 🔐 Access Control

Hermes' built-in dashboard is wrapped by HuggingMes:

- **Dashboard:** Opening `/app/` requires `GATEWAY_TOKEN`.
- **API:** Routes under `/v1/*` require `Authorization: Bearer <GATEWAY_TOKEN>`.

## 🤖 LLM Providers

HuggingMes supports Hermes providers in two different ways:

- **Direct startup providers:** Set `LLM_API_KEY` and `LLM_MODEL`, and HuggingMes maps them during boot.
- **Hermes-native providers:** Use `hermes model` after the Space starts, or edit `config.yaml` through the Hermes UI.
- **Custom OpenAI-compatible endpoints:** Point Hermes at your own `/v1` endpoint.

### Direct startup providers

These are the providers that HuggingMes maps directly from `LLM_MODEL` and `LLM_API_KEY` at startup.

| Provider | Prefix | Example `LLM_MODEL` | Key env |
| :--- | :--- | :--- | :--- |
| OpenRouter | `openrouter/` | `openrouter/anthropic/claude-sonnet-4` | `LLM_API_KEY` -> `OPENROUTER_API_KEY` |
| Hugging Face Inference Providers | `huggingface/` or `hf/` | `huggingface/Qwen/Qwen3-235B-A22B-Thinking-2507` | `LLM_API_KEY` -> `HF_TOKEN` |
| AI Gateway / Vercel AI Gateway | `ai-gateway/` or `vercel-ai-gateway/` | `ai-gateway/openai/gpt-4o` | `LLM_API_KEY` -> `AI_GATEWAY_API_KEY` |
| Anthropic | `anthropic/` | `anthropic/claude-sonnet-4-6` | `LLM_API_KEY` -> `ANTHROPIC_API_KEY` |
| OpenAI / OpenAI Codex | `openai/` or `openai-codex/` | `openai/gpt-4o` | `LLM_API_KEY` -> `OPENAI_API_KEY` |
| Google Gemini | `google/` or `gemini/` | `google/gemini-2.5-flash` | `LLM_API_KEY` -> `GOOGLE_API_KEY` and `GEMINI_API_KEY` |
| DeepSeek | `deepseek/` | `deepseek/deepseek-chat` | `LLM_API_KEY` -> `DEEPSEEK_API_KEY` |
| Kimi / Moonshot | `kimi-coding/` or `moonshot/` | `kimi-coding/kimi-for-coding` | `LLM_API_KEY` -> `KIMI_API_KEY` |
| Kimi / Moonshot (China) | `kimi-coding-cn/` | `kimi-coding-cn/kimi-k2.5` | `LLM_API_KEY` -> `KIMI_CN_API_KEY` |
| Arcee AI | `arcee/` | `arcee/trinity-large-thinking` | `LLM_API_KEY` -> `ARCEEAI_API_KEY` |
| GMI Cloud | `gmi/` | `gmi/zai-org/GLM-5.1-FP8` | `LLM_API_KEY` -> `GMI_API_KEY` |
| MiniMax | `minimax/` | `minimax/MiniMax-M2.7` | `LLM_API_KEY` -> `MINIMAX_API_KEY` |
| MiniMax (China) | `minimax-cn/` | `minimax-cn/MiniMax-M2.7` | `LLM_API_KEY` -> `MINIMAX_CN_API_KEY` |
| Alibaba Cloud | `alibaba/` | `alibaba/qwen3.5-plus` | `LLM_API_KEY` -> `DASHSCOPE_API_KEY` |
| Alibaba Coding Plan | `alibaba-coding-plan/` | `alibaba-coding-plan/qwen3-coder-plus` | `LLM_API_KEY` -> `DASHSCOPE_API_KEY` |
| Xiaomi MiMo | `xiaomi/` | `xiaomi/mimo-v2-pro` | `LLM_API_KEY` -> `XIAOMI_API_KEY` |
| Tencent TokenHub | `tencent-tokenhub/` | `tencent-tokenhub/hy3-preview` | `LLM_API_KEY` -> `TOKENHUB_API_KEY` |
| Z.ai / GLM | `zai/`, `z-ai/`, `z.ai/`, or `glm/` | `zai/glm-5` | `LLM_API_KEY` -> `GLM_API_KEY` |
| NVIDIA NIM | `nvidia/` | `nvidia/nemotron-3-super-120b-a12b` | `LLM_API_KEY` -> `NVIDIA_API_KEY` |
| xAI / Grok | `xai/` or `grok/` | `xai/grok-4-1-fast-reasoning` | `LLM_API_KEY` -> `XAI_API_KEY` |
| Kilo Code | `kilocode/` | `kilocode/<model-id>` | `LLM_API_KEY` -> `KILOCODE_API_KEY` |
| OpenCode Zen | `opencode-zen/` | `opencode-zen/<model-id>` | `LLM_API_KEY` -> `OPENCODE_ZEN_API_KEY` |
| OpenCode Go | `opencode-go/` | `opencode-go/<model-id>` | `LLM_API_KEY` -> `OPENCODE_GO_API_KEY` |

### Hermes-native providers and OAuth flows

These providers are supported by Hermes and can be used in HuggingMes once the agent config is set through `hermes model` or `config.yaml`. HuggingMes does not auto-map them from `LLM_MODEL` at boot unless Hermes itself handles that provider.

| Provider | How to use | Notes |
| :--- | :--- | :--- |
| Nous Portal | `hermes model` | Subscription-based OAuth provider in Hermes |
| OpenAI Codex | `hermes model` | ChatGPT OAuth / Codex models |
| GitHub Copilot | `hermes model` | Uses `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, or `gh auth token` |
| GitHub Copilot ACP | `hermes model` | Spawns the Copilot CLI backend |
| Anthropic (OAuth / Claude Code) | `hermes model` | Also supports `ANTHROPIC_API_KEY` |
| Google Gemini (OAuth) | `hermes model` | Browser OAuth flow, including free-tier Gemini OAuth |
| Qwen Portal (OAuth) | `hermes model` | Alibaba Qwen portal OAuth login |
| MiniMax (OAuth) | `hermes model` | Portal login for MiniMax models |
| Hugging Face Inference Providers | `hermes model` | Unified HF provider routing with model suffixes like `:fastest` and `:cheapest` |
| AWS Bedrock | `hermes model` or `config.yaml` | Uses AWS credentials chain, not an API key |
| Ollama Cloud | `hermes model` | Managed Ollama catalog with `OLLAMA_API_KEY` |
| Arcee AI | `hermes model` | First-class Hermes provider |
| GMI Cloud | `hermes model` | First-class Hermes provider |
| Alibaba Cloud / DashScope | `hermes model` | First-class Hermes provider for Qwen models |
| Tencent TokenHub | `hermes model` | First-class Hermes provider |
| Custom endpoint | `hermes model` or `config.yaml` | Any OpenAI-compatible endpoint |

### Custom and self-hosted endpoints

HuggingMes also works with any OpenAI-compatible server. Common examples include local Ollama, LM Studio, llama.cpp / llama-server, vLLM, SGLang, LocalAI, Jan, LiteLLM, ClawRouter, Together AI, Groq, Fireworks AI, Azure OpenAI, and similar services.

Use either the Hermes model wizard or a direct `config.yaml` entry with a `base_url`, `model`, and optional API key. For local servers that do not require auth, leave the key empty.

### Recommended provider choices

- **Just want it to work:** OpenRouter or Hermes' Nous Portal.
- **Want local models:** Ollama, LM Studio, llama.cpp, vLLM, or SGLang through a custom endpoint.
- **Need cloud APIs:** OpenAI, Anthropic, Google Gemini, DeepSeek, xAI, Hugging Face, or any other direct provider above.
- **Need routing or fallback:** Use a custom endpoint such as LiteLLM or ClawRouter.

## 📱 Telegram Setup

To use Hermes via Telegram:

1. Create a bot via [@BotFather](https://t.me/BotFather): send `/newbot`, follow the prompts, and copy the bot token.
2. Find your Telegram user ID with [@userinfobot](https://t.me/userinfobot) — send it any message and it replies with your numeric user ID.
3. Add `TELEGRAM_ALLOWED_USERS` as a comma-separated list of those numeric user IDs to restrict access.
4. Add `CLOUDFLARE_WORKERS_TOKEN` if you need automatic outbound proxying for Telegram API traffic.

## 🌐 Cloudflare Proxy

Hugging Face Spaces often block outbound calls to APIs used by Telegram and some provider backends. HuggingMes can provision a Cloudflare Worker proxy automatically when you add `CLOUDFLARE_WORKERS_TOKEN`.

## 💾 Backup & Persistence *(Optional)*

Set `HF_TOKEN` with write access to enable backup. HuggingMes syncs workspace data to a private HF Dataset named `huggingmes-backup` every 600 seconds by default.

| Variable | Default | Description |
| :--- | :--- | :--- |
| `HF_TOKEN` | — | HF token with **Write** access |
| `BACKUP_DATASET_NAME` | `huggingmes-backup` | Dataset name for backup |
| `SYNC_INTERVAL` | `600` | Backup frequency in seconds |

## 📦 Ephemeral Package Re-install *(Optional)*

Install packages in the terminal and they survive Space restarts — no extra config needed. Shell wrappers record every successful `apt install`, `pip install`, `uv pip install`, `npm install -g`, and `hermes plugins install` into `workspace/startup.sh`, which is backed up and replayed automatically on next boot.

For packages you want installed from day one (before the terminal is even opened), use the startup variables:

| Variable | What to put in it |
| :--- | :--- |
| `HUGGINGMES_RUN` | Full bash script to run on every startup (multi-line, heredocs, `if` blocks all work) |
| `HUGGINGMES_APT_PACKAGES` | Space-separated apt packages to install |
| `HUGGINGMES_PIP_PACKAGES` | Space-separated Python packages to install |
| `HUGGINGMES_NPM_PACKAGES` | Space-separated npm packages to install globally |

**Example:**

```bash
HUGGINGMES_RUN="""
pip install pandas matplotlib
npm install -g tsx
sudo apt-get install -y ffmpeg
"""
```

For scripts with complex quoting, base64-encode them:

```bash
# locally
base64 -w0 setup.sh
# HF Variable
HUGGINGMES_RUN=base64:<paste-output-here>
```

## 🔑 API Key Rotation *(Optional)*

Spread requests across multiple API keys to avoid rate limits. Supply a comma-separated pool — the first key is promoted to the provider's singular env var, and Hermes picks it up automatically.

```bash
ANTHROPIC_API_KEYS=sk-ant-key1,sk-ant-key2
OPENAI_API_KEYS=sk-oai-key1,sk-oai-key2
OPENROUTER_API_KEYS=sk-or-key1,sk-or-key2
```

Supported pool vars: `OPENROUTER_API_KEYS`, `ANTHROPIC_API_KEYS`, `OPENAI_API_KEYS`, `GOOGLE_API_KEYS`, `GEMINI_API_KEYS`, `DEEPSEEK_API_KEYS`, `KIMI_API_KEYS`, `MINIMAX_API_KEYS`, `NVIDIA_API_KEYS`, `XAI_API_KEYS`, `KILOCODE_API_KEYS`, `GLM_API_KEYS`, `ARCEEAI_API_KEYS`, `DASHSCOPE_API_KEYS`, `GMI_API_KEYS`, `TOKENHUB_API_KEYS`.

## 💓 Staying Alive

With `CLOUDFLARE_WORKERS_TOKEN` set, HuggingMes can create a keep-alive worker that pings the Space's `/health` endpoint on a schedule so the free tier stays awake longer.

## 🔐 Security & Advanced *(Optional)*

| Variable | Default | Description |
| :--- | :--- | :--- |
| `GATEWAY_TOKEN` | — | Token for dashboard and API auth |
| `HF_TOKEN` | — | HF token with write access for backups and HF providers |
| `CLOUDFLARE_WORKERS_TOKEN` | — | Cloudflare API token for proxying and keep-awake |
| `SYNC_INTERVAL` | `600` | Backup frequency in seconds |
| `CLOUDFLARE_KEEPALIVE_ENABLED` | `true` | Set `false` to disable keep-awake worker |
| `TELEGRAM_MODE` | `webhook` | `webhook` or `polling` (webhook auto-configured from `SPACE_HOST`) |
| `DISCORD_BOT_TOKEN` | — | Discord bot token from Developer Portal |
| `DISCORD_CHANNEL_ID` | — | Default Discord channel ID for bot messages |
| `DISCORD_GUILD_ID` | — | Discord server (guild) ID |
| `DISCORD_WEBHOOK_URL` | — | Discord webhook URL for notifications |
| `DEV_MODE` | `true` | Set `false` to disable JupyterLab terminal at `/terminal/` |
| `JUPYTER_TOKEN` | *(uses `GATEWAY_TOKEN`)* | Override terminal password (optional) |
| `WEBHOOK_URL` | — | Endpoint for POST JSON restart notifications |
| `GATEWAY_RESTART_DELAY` | `5` | Seconds between gateway restart attempts |
| `GATEWAY_MAX_RESTARTS` | `0` (unlimited) | Maximum gateway restart count before container exits |

## 💻 Terminal Access (JupyterLab)

HuggingMes includes a JupyterLab terminal at `/terminal/` for direct shell access to the container — useful for running `hermes` commands, inspecting files, installing packages, and debugging. Enabled by default when `GATEWAY_TOKEN` is set.

### Setup

The terminal is **on by default** — no extra configuration needed. Click **Open Terminal →** on the dashboard, then log in with your `GATEWAY_TOKEN`.

To disable it, set `DEV_MODE=false`. To use a separate terminal password, set `JUPYTER_TOKEN` to a different value.

> **Security:** JupyterLab grants full shell access to the container. The terminal will not start if no `GATEWAY_TOKEN` is set.

### What you can do

- Run `hermes` CLI commands directly
- Browse and edit files in the workspace
- Install Python packages with `pip` or `uv pip`
- Check logs, inspect config, debug issues

## 💻 Local Development

```bash
docker compose up --build
# Dashboard: http://localhost:7861
# Hermes App: http://localhost:7861/app/
```

## 🏗️ Architecture

- **Dashboard (`/`)**: Real-time management and monitoring.
- **Hermes App (`/app/`)**: Secure proxied access to the Hermes UI.
- **API (`/v1/*`)**: Proxied OpenAI-compatible agent API.
- **Terminal (`/terminal/`)**: JupyterLab terminal (auto-enabled when `GATEWAY_TOKEN` is set; set `DEV_MODE=false` to disable).
- **Health Check (`/health`)**: Readiness probe for HF and keep-alive.
- **Sync Engine**: Python background task for HF Dataset persistence.

## 🐛 Troubleshooting

- **Telegram bot not responding:** Ensure `CLOUDFLARE_WORKERS_TOKEN` is set and check logs for the proxy setup step.
- **Authentication failed:** Clear browser cookies or use an incognito window if `GATEWAY_TOKEN` changed.
- **Data not persisting:** Ensure `HF_TOKEN` has write access.
- **Provider not showing up:** If it is a Hermes-native provider, run `hermes model` and complete the provider-specific setup there. If it is a custom endpoint, verify the `base_url` exposes `/v1/models` or `/v1/chat/completions`.
- **Space keeps sleeping:** Add `CLOUDFLARE_WORKERS_TOKEN` to enable automatic keep-awake monitoring.

## 🌟 More Projects

Similar projects by [@somratpro](https://github.com/somratpro) — all free, one-click deploy on HF Spaces:

| Project | What it runs | HF Space | GitHub |
| :--- | :--- | :--- | :--- |
| **HuggingFlow** | DeerFlow — deep research agent | [Space](https://huggingface.co/spaces/somratpro/HuggingFlow) | [Repo](https://github.com/somratpro/HuggingFlow) |
| **Hugging8n** | n8n — workflow & automation platform | [Space](https://huggingface.co/spaces/somratpro/Hugging8n) | [Repo](https://github.com/somratpro/hugging8n) |
| **HuggingClaw** | OpenClaw — Claude Code in the browser | [Space](https://huggingface.co/spaces/somratpro/HuggingClaw) | [Repo](https://github.com/somratpro/huggingclaw) |
| **HuggingClip** | Paperclip — AI agent orchestration platform | [Space](https://huggingface.co/spaces/somratpro/HuggingClip) | [Repo](https://github.com/somratpro/huggingclip) |
| **HuggingPost** | Postiz — social-media scheduler | [Space](https://huggingface.co/spaces/somratpro/HuggingPost) | [Repo](https://github.com/somratpro/huggingpost) |

---
*Made with ❤️ by [@somratpro](https://github.com/somratpro)*
