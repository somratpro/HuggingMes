#!/usr/bin/env python3
from __future__ import annotations

"""Create or reuse Cloudflare Workers for Telegram & Discord proxy and Space keep-awake."""

import json
import os
import re
import secrets
import sys
import time
import urllib.request
from pathlib import Path

API_BASE = "https://api.cloudflare.com/client/v4"
ENV_FILE = Path("/tmp/huggingmes-cloudflare-proxy.env")
ENV_FILE = Path("/tmp/huggingmes-cloudflare-proxy.env")
DEFAULT_ALLOWED = [
    # Messaging & social — primary use-case for Cloudflare proxy on HF Spaces
    # (geo-restrictions on Telegram, Discord, WhatsApp, etc.)
    "api.telegram.org",
    "discord.com",
    "discordapp.com",
    "gateway.discord.gg",
    "status.discord.com",
    "slack.com",
    "api.slack.com",
    "web.whatsapp.com",
    # Social — confirmed/likely blocked by HF firewall
    "graph.facebook.com",
    "graph.instagram.com",
    "api.twitter.com",
    "api.x.com",
    # Google
    "googleapis.com",
    "google.com",
    "googleusercontent.com",
    "gstatic.com",
    # Email HTTP APIs (SMTP ports are blocked)
    "api.resend.com",
    "api.sendgrid.com",
    # NOTE: AI-provider domains (api.openai.com, api.anthropic.com, etc.) are
    # intentionally NOT included here. Proxying AI calls routes API keys through
    # the Cloudflare Worker without explicit opt-in. Users who need AI API calls
    # proxied can add specific domains via CLOUDFLARE_PROXY_DOMAINS env var.
]


def cf_request(method: str, path: str, token: str, body: bytes | None = None, content_type: str = "application/json"):
    req = urllib.request.Request(
        f"{API_BASE}{path}",
        data=body,
        method=method,
        headers={"Authorization": f"Bearer {token}", "Content-Type": content_type},
    )
    with urllib.request.urlopen(req, timeout=30) as response:
        payload = json.loads(response.read().decode("utf-8"))
    if not payload.get("success"):
        errors = payload.get("errors") or [{"message": "Unknown Cloudflare API error"}]
        raise RuntimeError(errors[0].get("message", "Unknown Cloudflare API error"))
    return payload["result"]


def slugify(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9-]+", "-", value.lower()).strip("-")
    cleaned = re.sub(r"-{2,}", "-", cleaned)
    return (cleaned or "huggingmes-proxy")[:63].rstrip("-")


def derive_worker_name() -> str:
    explicit = os.environ.get("CLOUDFLARE_WORKER_NAME", "").strip()
    if explicit:
        return slugify(explicit)
    space_host = os.environ.get("SPACE_HOST", "").strip()
    if space_host:
        return slugify(f"{space_host.replace('.hf.space', '')}-proxy")
    return "huggingmes-proxy"


def render_worker(secret_value: str, allowed_targets: list[str], allow_proxy_all: bool) -> str:
    return f"""addEventListener("fetch", (event) => {{
  event.respondWith(handleRequest(event.request));
}});

const PROXY_SHARED_SECRET = {json.dumps(secret_value)};
const ALLOW_PROXY_ALL = {"true" if allow_proxy_all else "false"};
const ALLOWED_TARGETS = {json.dumps(allowed_targets)};

function isAllowedHost(hostname) {{
  const normalized = String(hostname || "").trim().toLowerCase();
  if (!normalized) return false;
  if (ALLOW_PROXY_ALL) return true;
  return ALLOWED_TARGETS.some((domain) => normalized === domain || normalized.endsWith(`.${{domain}}`));
}}

async function handleRequest(request) {{
  const url = new URL(request.url);
  const queryTarget = url.searchParams.get("proxy_target");
  const targetHost = request.headers.get("x-target-host") || queryTarget;

  const autoForwardedPath = (
    url.pathname.startsWith("/bot") ||
    url.pathname.startsWith("/file/bot") ||
    url.pathname.startsWith("/discord/")
  );

  if (PROXY_SHARED_SECRET) {{
    const providedSecret = request.headers.get("x-proxy-key") || url.searchParams.get("proxy_key") || "";
    if (providedSecret !== PROXY_SHARED_SECRET && !(autoForwardedPath && !targetHost)) {{
      return new Response("Unauthorized: Invalid proxy key", {{ status: 401 }});
    }}
  }}

  let targetBase = "";
  if (targetHost) {{
    if (!isAllowedHost(targetHost)) {{
      return new Response(`Forbidden: Host ${{targetHost}} is not allowed.`, {{ status: 403 }});
    }}
    targetBase = `https://${{targetHost}}`;
  }} else if (url.pathname.startsWith("/bot") || url.pathname.startsWith("/file/bot")) {{
    targetBase = "https://api.telegram.org";
  }} else if (url.pathname.startsWith("/discord/")) {{
    targetBase = "https://discord.com";
  }} else {{
    return new Response("Invalid request: No target host provided.", {{ status: 400 }});
  }}

  const cleanSearch = new URLSearchParams(url.search);
  cleanSearch.delete("proxy_target");
  cleanSearch.delete("proxy_key");
  const searchStr = cleanSearch.toString();
  const targetUrl = targetBase + url.pathname + (searchStr ? `?${{searchStr}}` : "");

  const headers = new Headers(request.headers);
  for (const header of ["cf-connecting-ip", "cf-ray", "cf-visitor", "host", "x-real-ip", "x-target-host", "x-proxy-key"]) {{
    headers.delete(header);
  }}

  try {{
    return await fetch(new Request(targetUrl, {{
      method: request.method,
      headers,
      body: request.body,
      redirect: "follow",
    }}));
  }} catch (error) {{
    return new Response(`Proxy Error: ${{error.message}}`, {{ status: 502 }});
  }}
}}
"""


def write_env(proxy_url: str, proxy_secret: str) -> None:
    ENV_FILE.write_text(
        f'export CLOUDFLARE_PROXY_URL="{proxy_url}"\nexport CLOUDFLARE_PROXY_SECRET="{proxy_secret}"\n',
        encoding="utf-8",
    )
    ENV_FILE.chmod(0o600)


def resolve_account_and_subdomain(api_token: str) -> tuple[str, str]:
    account_id = os.environ.get("CLOUDFLARE_ACCOUNT_ID", "").strip()
    if not account_id:
        accounts = cf_request("GET", "/accounts", api_token)
        if not accounts:
            raise RuntimeError("No Cloudflare account is available for this token.")
        account_id = accounts[0]["id"]

    subdomain_info = cf_request("GET", f"/accounts/{account_id}/workers/subdomain", api_token)
    subdomain = (subdomain_info or {}).get("subdomain", "").strip()
    if not subdomain:
        raise RuntimeError("Cloudflare Workers subdomain is not configured. Enable workers.dev first.")
    return account_id, subdomain


def main() -> int:
    existing_url = os.environ.get("CLOUDFLARE_PROXY_URL", "").strip()
    existing_secret = os.environ.get("CLOUDFLARE_PROXY_SECRET", "").strip()
    api_token = os.environ.get("CLOUDFLARE_WORKERS_TOKEN", "").strip()

    if existing_url:
        write_env(existing_url, existing_secret)

    if not api_token:
        return 0

    try:
        account_id, subdomain = resolve_account_and_subdomain(api_token)

        if not existing_url:
            allowed_raw = os.environ.get("CLOUDFLARE_PROXY_DOMAINS", "").strip()
            allow_proxy_all = allowed_raw == "*"
            extra = [] if allow_proxy_all else [v.strip() for v in allowed_raw.split(",") if v.strip()]
            allowed = list(dict.fromkeys(DEFAULT_ALLOWED + extra))
            worker_name = derive_worker_name()
            proxy_secret = existing_secret or secrets.token_urlsafe(24)

            cf_request(
                "PUT",
                f"/accounts/{account_id}/workers/scripts/{worker_name}",
                api_token,
                body=render_worker(proxy_secret, allowed, allow_proxy_all).encode("utf-8"),
                content_type="application/javascript",
            )
            cf_request(
                "POST",
                f"/accounts/{account_id}/workers/scripts/{worker_name}/subdomain",
                api_token,
                body=json.dumps({"enabled": True, "previews_enabled": True}).encode("utf-8"),
            )
            write_env(f"https://{worker_name}.{subdomain}.workers.dev", proxy_secret)

        return 0
    except Exception as exc:
        print(f"Cloudflare proxy setup failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
