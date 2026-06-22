// ── Model Catalogs ──
const MODEL_CATALOGS = {
  "LLM_MODEL": {
    "Anthropic": [
      "anthropic/claude-opus-4-7",
      "anthropic/claude-opus-4-6",
      "anthropic/claude-sonnet-4-6",
      "anthropic/claude-sonnet-4-5",
      "anthropic/claude-haiku-4-5",
      "anthropic/claude-haiku-3-5"
    ],
    "Gemini": [
      "gemini/gemini-2.5-pro-preview-06-05",
      "gemini/gemini-2.5-flash-preview-05-20",
      "gemini/gemini-2.5-flash",
      "gemini/gemini-2.0-flash",
      "gemini/gemini-1.5-pro",
      "gemini/gemini-1.5-flash",
      "google/gemini-2.5-flash",
      "google/gemini-2.0-flash"
    ],
    "OpenAI": [
      "openai/gpt-4.1",
      "openai/gpt-4.1-mini",
      "openai/gpt-4o",
      "openai/gpt-4o-mini",
      "openai/o3",
      "openai/o4-mini",
      "openai/o3-mini"
    ],
    "OpenRouter": [
      "openrouter/anthropic/claude-opus-4-7",
      "openrouter/anthropic/claude-sonnet-4-6",
      "openrouter/anthropic/claude-haiku-4-5",
      "openrouter/openai/gpt-4o",
      "openrouter/openai/o3",
      "openrouter/google/gemini-2.5-flash",
      "openrouter/google/gemini-2.5-pro",
      "openrouter/meta-llama/llama-4-maverick",
      "openrouter/deepseek/deepseek-r1",
      "openrouter/deepseek/deepseek-chat-v3-5",
      "openrouter/mistralai/mistral-large"
    ],
    "DeepSeek": [
      "deepseek/deepseek-chat",
      "deepseek/deepseek-reasoner"
    ],
    "xAI": [
      "xai/grok-3",
      "xai/grok-3-mini",
      "xai/grok-2"
    ],
    "HuggingFace": [
      "huggingface/meta-llama/Llama-3.3-70B-Instruct",
      "huggingface/meta-llama/Llama-3.1-70B-Instruct",
      "huggingface/Qwen/Qwen2.5-72B-Instruct",
      "huggingface/mistralai/Mistral-7B-Instruct-v0.3",
      "huggingface/google/gemma-2-27b-it"
    ],
    "Moonshot / Kimi": [
      "moonshot/moonshot-v1-128k",
      "kimi-coding/kimi-k2-0711-preview",
      "kimi-coding-cn/kimi-k2-0711-preview"
    ],
    "Alibaba": [
      "alibaba/qwen-max",
      "alibaba/qwen-plus",
      "alibaba/qwen-turbo"
    ],
    "Minimax": [
      "minimax/minimax-01",
      "minimax-cn/minimax-01"
    ],
    "NVIDIA": [
      "nvidia/meta/llama-3.1-70b-instruct",
      "nvidia/meta/llama-3.3-70b-instruct"
    ],
    "GLM / ZAI": [
      "zai/glm-4-plus",
      "glm/chatglm-turbo"
    ],
    "Vercel AI Gateway": [
      "vercel-ai-gateway/anthropic/claude-sonnet-4-6",
      "vercel-ai-gateway/openai/gpt-4o"
    ],
    "Custom / OpenAI-compatible": [
      "custom"
    ]
  }
};

// ── Icons per group ──
const ICONS = {
  "All":       "🌐",
  "Core":      "⚡",
  "Backup":    "💾",
  "Telegram":  "📱",
  "Discord":   "🎮",
  "Terminal":  "💻",
  "Providers": "🔑",
  "Cloudflare":"☁️",
  "Advanced":  "⚙️",
  "Custom Env":"🔧"
};

// ── Field definitions ──
// tag: "critical" | "credential" | "feature" | "optional" | "advanced" | "build"
const FIELDS = [
  // ── Core ──
  {
    "g": "Core", "icon": "⚡",
    "k": "GATEWAY_TOKEN",
    "lbl": "Gateway token — protects the Hermes web UI",
    "type": "password", "secret": 1, "common": 1, "tag": "critical"
  },
  {
    "g": "Core", "icon": "⚡",
    "k": "LLM_MODEL",
    "lbl": "Default model (provider/model-name format)",
    "type": "model", "options_key": "LLM_MODEL",
    "ph": "gemini/gemini-2.5-flash", "common": 1, "tag": "critical"
  },
  {
    "g": "Core", "icon": "⚡",
    "k": "LLM_API_KEY",
    "lbl": "API key for the chosen provider",
    "type": "password", "secret": 1, "common": 1, "tag": "credential"
  },

  // ── Backup ──
  {
    "g": "Backup", "icon": "💾",
    "k": "HF_TOKEN",
    "lbl": "HuggingFace token — enables state backup to a private dataset",
    "type": "password", "secret": 1, "common": 1, "tag": "credential"
  },
  {
    "g": "Backup", "icon": "💾",
    "k": "BACKUP_DATASET_NAME",
    "lbl": "Name of the HF dataset used for backups",
    "type": "text", "ph": "huggingmes-backup", "common": 1, "tag": "optional"
  },
  {
    "g": "Backup", "icon": "💾",
    "k": "SYNC_INTERVAL",
    "lbl": "Backup sync interval (seconds)",
    "type": "number", "ph": "600", "tag": "optional"
  },

  // ── Telegram ──
  {
    "g": "Telegram", "icon": "📱",
    "k": "TELEGRAM_BOT_TOKEN",
    "lbl": "Telegram bot token from @BotFather",
    "type": "password", "secret": 1, "common": 1, "tag": "credential"
  },
  {
    "g": "Telegram", "icon": "📱",
    "k": "TELEGRAM_ALLOWED_USERS",
    "lbl": "Allowed Telegram user IDs (comma-separated)",
    "type": "text", "ph": "123456789,987654321", "common": 1, "tag": "feature"
  },
  {
    "g": "Telegram", "icon": "📱",
    "k": "TELEGRAM_MODE",
    "lbl": "Telegram update mode",
    "type": "select",
    "options": ["webhook", "polling"],
    "ph": "webhook", "tag": "optional"
  },
  {
    "g": "Telegram", "icon": "📱",
    "k": "TELEGRAM_WEBHOOK_URL",
    "lbl": "Override webhook URL (auto-detected from SPACE_HOST if blank)",
    "type": "text", "ph": "https://your-space.hf.space/telegram", "tag": "optional"
  },
  {
    "g": "Telegram", "icon": "📱",
    "k": "TELEGRAM_BASE_URL",
    "lbl": "Custom Telegram API base URL (for proxies)",
    "type": "text", "ph": "https://proxy.example.com/bot", "tag": "optional"
  },

  // ── Discord ──
  {
    "g": "Discord", "icon": "🎮",
    "k": "DISCORD_BOT_TOKEN",
    "lbl": "Discord bot token from Developer Portal",
    "type": "password", "secret": 1, "common": 1, "tag": "credential"
  },
  {
    "g": "Discord", "icon": "🎮",
    "k": "DISCORD_CHANNEL_ID",
    "lbl": "Default Discord channel ID for bot messages",
    "type": "text", "ph": "123456789012345678", "common": 1, "tag": "feature"
  },
  {
    "g": "Discord", "icon": "🎮",
    "k": "DISCORD_GUILD_ID",
    "lbl": "Discord server (guild) ID",
    "type": "text", "ph": "123456789012345678", "tag": "optional"
  },
  {
    "g": "Discord", "icon": "🎮",
    "k": "DISCORD_WEBHOOK_URL",
    "lbl": "Discord webhook URL for notifications",
    "type": "text", "ph": "https://discord.com/api/webhooks/...", "tag": "optional"
  },

  // ── Terminal ──
  {
    "g": "Terminal", "icon": "💻",
    "k": "DEV_MODE",
    "lbl": "Enable JupyterLab terminal (on by default)",
    "type": "toggle", "ph": "true", "common": 1, "tag": "feature"
  },
  {
    "g": "Terminal", "icon": "💻",
    "k": "JUPYTER_TOKEN",
    "lbl": "Override terminal password (defaults to GATEWAY_TOKEN)",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Terminal", "icon": "💻",
    "k": "JUPYTER_ROOT_DIR",
    "lbl": "JupyterLab root directory",
    "type": "text", "ph": "/opt/data/workspace", "tag": "optional"
  },

  // ── Providers ──
  {
    "g": "Providers", "icon": "🔑",
    "k": "ANTHROPIC_API_KEY",
    "lbl": "Anthropic API key",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "OPENAI_API_KEY",
    "lbl": "OpenAI API key",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "GOOGLE_API_KEY",
    "lbl": "Google / Gemini API key",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "GEMINI_API_KEY",
    "lbl": "Gemini API key (alias for GOOGLE_API_KEY)",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "OPENROUTER_API_KEY",
    "lbl": "OpenRouter API key",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "DEEPSEEK_API_KEY",
    "lbl": "DeepSeek API key",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "XAI_API_KEY",
    "lbl": "xAI (Grok) API key",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "HERMES_INFERENCE_PROVIDER",
    "lbl": "Force Hermes inference provider (overrides auto-detect)",
    "type": "select",
    "options": ["auto", "anthropic", "openai", "gemini", "openrouter", "huggingface", "custom", "deepseek", "xai"],
    "ph": "auto", "tag": "advanced"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "CUSTOM_BASE_URL",
    "lbl": "Custom OpenAI-compatible base URL",
    "type": "text", "ph": "https://your-api.example.com/v1", "tag": "feature"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "CUSTOM_API_KEY",
    "lbl": "API key for the custom provider",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "CUSTOM_PROVIDER",
    "lbl": "Provider name for custom endpoints",
    "type": "text", "ph": "custom", "tag": "advanced"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "CUSTOM_MODEL_CONTEXT_LENGTH",
    "lbl": "Context length for custom model",
    "type": "number", "ph": "131072", "tag": "advanced"
  },
  {
    "g": "Providers", "icon": "🔑",
    "k": "CUSTOM_MODEL_MAX_TOKENS",
    "lbl": "Max output tokens for custom model",
    "type": "number", "ph": "8192", "tag": "advanced"
  },

  // ── Cloudflare ──
  {
    "g": "Cloudflare", "icon": "☁️",
    "k": "CLOUDFLARE_WORKERS_TOKEN",
    "lbl": "Cloudflare Workers API token (for Telegram & Discord proxy setup)",
    "type": "password", "secret": 1, "tag": "credential"
  },
  {
    "g": "Cloudflare", "icon": "☁️",
    "k": "CLOUDFLARE_PROXY_URL",
    "lbl": "Cloudflare proxy URL for Telegram & Discord (if already deployed)",
    "type": "text", "ph": "https://your-worker.your-subdomain.workers.dev", "tag": "feature"
  },
  {
    "g": "Cloudflare", "icon": "☁️",
    "k": "CLOUDFLARE_PROXY_DEBUG",
    "lbl": "Enable Cloudflare proxy debug logging",
    "type": "toggle", "ph": "false", "tag": "advanced"
  },

  // ── Advanced ──
  {
    "g": "Advanced", "icon": "⚙️",
    "k": "WEBHOOK_URL",
    "lbl": "URL to POST a JSON notification on gateway (re)start",
    "type": "text", "ph": "https://...", "tag": "optional"
  },
  {
    "g": "Advanced", "icon": "⚙️",
    "k": "SPACE_PRIVACY",
    "lbl": "Override Space privacy detection (public/private) — skips HF API call",
    "type": "select", "options": ["public", "private"], "ph": "public", "tag": "advanced"
  },
  {
    "g": "Advanced", "icon": "⚙️",
    "k": "GATEWAY_READY_TIMEOUT",
    "lbl": "Seconds to wait for gateway API port before failing",
    "type": "number", "ph": "120", "tag": "advanced"
  },
  {
    "g": "Advanced", "icon": "⚙️",
    "k": "API_SERVER_PORT",
    "lbl": "Hermes gateway internal API port",
    "type": "number", "ph": "8642", "tag": "advanced"
  },
  {
    "g": "Advanced", "icon": "⚙️",
    "k": "DASHBOARD_PORT",
    "lbl": "Hermes dashboard internal port",
    "type": "number", "ph": "9119", "tag": "advanced"
  },
  {
    "g": "Advanced", "icon": "⚙️",
    "k": "HERMES_BACKGROUND_NOTIFICATIONS",
    "lbl": "Background process notification level",
    "type": "select",
    "options": ["result", "progress", "none"],
    "ph": "result", "tag": "optional"
  },
  {
    "g": "Advanced", "icon": "⚙️",
    "k": "TELEGRAM_WEBHOOK_SECRET",
    "lbl": "Secret token for Telegram webhook validation (auto-generated if blank)",
    "type": "password", "secret": 1, "tag": "credential"
  }
];

// ── Runtime (shared with HuggingClaw env-builder) ──

const BUNDLE_KEY = 'HUGGINGMES_ENV_BUNDLE';

const $ = id => document.getElementById(id);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
}[c]));
const safeKey = k => /^[A-Z_][A-Z0-9_]*$/.test(k) && ![BUNDLE_KEY, 'ENV_BUNDLE'].includes(k);

function encodeBundle(obj) {
  const j = JSON.stringify(obj);
  let b = '';
  for (const x of new TextEncoder().encode(j)) b += String.fromCharCode(x);
  return btoa(b).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function decodeBundle(raw) {
  try {
    raw = String(raw || '').trim();
    if (!raw) return {};
    if (raw.includes(BUNDLE_KEY + '=')) raw = raw.split(BUNDLE_KEY + '=').pop().trim();
    if ((raw.startsWith('"') && raw.endsWith('"')) || (raw.startsWith("'") && raw.endsWith("'"))) raw = raw.slice(1, -1);
    if (raw.startsWith('{')) return JSON.parse(raw);
    const p = raw + '='.repeat((4 - raw.length % 4) % 4);
    const b = atob(p.replace(/-/g, '+').replace(/_/g, '/'));
    const bytes = Uint8Array.from(b, c => c.charCodeAt(0));
    return JSON.parse(new TextDecoder().decode(bytes));
  } catch { return {}; }
}

function parseEnv(text) {
  text = String(text || '').trim();
  if (!text) return {};
  if (text.startsWith('{') || /^[A-Za-z0-9_-]{20,}$/.test(text) || text.includes(BUNDLE_KEY + '=')) {
    return decodeBundle(text);
  }
  const out = {};
  for (let line of text.split(/\r?\n/)) {
    line = line.trim();
    if (!line || line.startsWith('#')) continue;
    if (line.startsWith('export ')) line = line.slice(7).trim();
    const i = line.indexOf('=');
    if (i < 1) continue;
    const key = line.slice(0, i).trim();
    let val = line.slice(i + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) val = val.slice(1, -1);
    if (safeKey(key)) out[key] = val;
  }
  return out;
}

function showToast(msg = 'Copied!') {
  const t = $('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 1500);
}

let activeGroup = 'All';
let customCount = 0;
const GROUPS = ['All', ...[...new Set(FIELDS.map(f => f.g))], 'Custom Env'];

function renderSidebar() {
  const sb = $('sidebar');
  sb.innerHTML = '<div class="sb-label">Groups</div>';
  GROUPS.forEach(g => {
    const btn = document.createElement('button');
    btn.className = 'nav-btn' + (activeGroup === g ? ' active' : '');
    btn.dataset.group = g;
    const id = 'nc_' + g.replace(/\W/g, '_');
    btn.innerHTML = `<span class="nav-icon">${ICONS[g] || '📁'}</span><span class="nav-label">${esc(g)}</span><span class="nav-count" id="${id}">0</span>`;
    btn.onclick = () => { activeGroup = g; renderSidebar(); filter(); };
    sb.appendChild(btn);
  });
}

function renderOptionsHTML(field) {
  if (field.options_key === 'LLM_MODEL') {
    const groups = MODEL_CATALOGS.LLM_MODEL || {};
    return Object.entries(groups).map(([group, items]) => {
      const options = items.map(v => `<option value="${esc(v)}">${esc(v)}</option>`).join('');
      return `<optgroup label="${esc(group)}">${options}</optgroup>`;
    }).join('');
  }
  const src = field.options || MODEL_CATALOGS[field.options_key] || [];
  if (Array.isArray(src)) return src.map(v => `<option value="${esc(v)}">${esc(v)}</option>`).join('');
  return '';
}

function defaultValueFor(field) {
  if (field.type === 'toggle') {
    const on = String(field.ph ?? '').toLowerCase();
    return ['1', 'true', 'yes', 'on', 'enabled'].includes(on) ? 'true' : 'false';
  }
  if (field.type === 'select') return String(field.ph ?? '');
  return '';
}

function valueControlHTML(field) {
  const key = esc(field.k);
  const placeholder = esc(field.ph || field.lbl || '');
  const isSecret = !!field.secret;
  const isTextarea = field.type === 'textarea';
  const hasPicker = !!field.options_key || Array.isArray(field.options);
  const inputType = isSecret ? 'password' : (field.type === 'number' ? 'number' : 'text');

  let control = '';
  if (field.type === 'toggle') {
    const initial = defaultValueFor(field);
    control = `<div class="toggle-shell" data-toggle-row="1" data-field="${key}">
      <input type="hidden" data-key="${key}" value="${initial}">
      <button type="button" class="tog ${initial === 'true' ? 'on' : ''}" data-toggle="${key}">${initial === 'true' ? 'On' : 'Off'}</button>
    </div>`;
  } else if (isTextarea) {
    control = `<textarea data-key="${key}" placeholder="${placeholder}" spellcheck="false"></textarea>`;
  } else {
    control = `<input type="${inputType}" data-key="${key}" placeholder="${placeholder}" spellcheck="false"/>`;
  }

  if (!hasPicker) return control;

  return `<div class="picker-shell" data-picker-shell="${key}" data-picker-mode="single">
    <div class="picker-row">
      <select class="picker-select" data-pick-for="${key}" aria-label="${esc(field.lbl || field.k)} presets">
        <option value="">Choose preset…</option>
        ${renderOptionsHTML(field)}
        <option value="__custom__">Custom…</option>
      </select>
      <button type="button" class="mini-btn" data-custom-for="${key}">+ Custom</button>
      <button type="button" class="mini-btn" data-clear-for="${key}">Clear</button>
    </div>
    ${control}
  </div>`;
}

function tagBadgeHTML(f) {
  const t = f.tag || (f.secret ? 'credential' : 'optional');
  return `<span class="badge badge-${t}">${t}</span>`;
}

function cardHTML(f) {
  const tagStr = (f.tag || '') + ' ' + (f.secret ? 'credential' : '') + ' ' + (f.g + ' ' + f.k + ' ' + (f.lbl || '')).toLowerCase();
  return `<div class="env-card" data-row data-group="${esc(f.g)}" data-tag="${esc(f.tag || '')}" data-search="${esc(tagStr.toLowerCase())}">
    <div class="card-top">
      <input type="checkbox" class="card-check" data-check="${esc(f.k)}" ${f.common ? 'data-common="1"' : ''} ${f.tag === 'critical' ? 'data-critical="1"' : ''}>
      <div class="card-info">
        <div class="card-key">${esc(f.k)}</div>
        <div class="card-lbl">${esc(f.lbl || '')}</div>
      </div>
      ${tagBadgeHTML(f)}
    </div>
    <div class="card-input">${valueControlHTML(f)}</div>
  </div>`;
}

function addCustomRow(key = '', val = '', enabled = false) {
  const id = customCount++;
  const row = document.createElement('div');
  row.className = 'custom-row';
  row.dataset.customRow = id;
  row.dataset.enabled = enabled ? '1' : '0';
  row.innerHTML = `
    <input data-ck="${id}" placeholder="CUSTOM_ENV_NAME" value="${esc(key)}">
    <input data-cv="${id}" placeholder="value" value="${esc(val)}">
    <button class="tog${enabled ? ' on' : ''}">${enabled ? 'On' : 'Off'}</button>`;
  $('customRows').appendChild(row);
  row.querySelectorAll('input').forEach(el => el.addEventListener('input', refresh));
  row.querySelector('button').onclick = () => {
    const on = row.dataset.enabled !== '1';
    row.dataset.enabled = on ? '1' : '0';
    row.querySelector('button').textContent = on ? 'On' : 'Off';
    row.querySelector('button').classList.toggle('on', on);
    refresh();
  };
}

function getFieldValueInput(key) { return document.querySelector(`[data-key="${CSS.escape(key)}"]`); }

function setFieldValue(key, value) {
  const el = getFieldValueInput(key);
  if (el) el.value = value ?? '';
}

function appendCsvValue(existing, next) {
  const parts = String(existing || '').split(',').map(s => s.trim()).filter(Boolean);
  const val = String(next || '').trim();
  if (!val) return parts.join(', ');
  if (!parts.includes(val)) parts.push(val);
  return parts.join(', ');
}

function collect() {
  const obj = {};
  document.querySelectorAll('[data-key]').forEach(el => {
    const key = el.dataset.key;
    if (!key || !safeKey(key)) return;
    const chk = document.querySelector(`[data-check="${CSS.escape(key)}"]`);
    if (!chk || !chk.checked) return;
    const val = String(el.value ?? '').trim();
    if (val) obj[key] = val;
  });
  document.querySelectorAll('[data-custom-row]').forEach(row => {
    const id = row.dataset.customRow;
    const key = (row.querySelector(`[data-ck="${id}"]`)?.value || '').trim();
    const val = (row.querySelector(`[data-cv="${id}"]`)?.value || '').trim();
    if (row.dataset.enabled === '1' && safeKey(key) && val) obj[key] = val;
  });
  return obj;
}

function generateBundle() {
  const obj = collect();
  const keys = Object.keys(obj).sort();
  const bundle = keys.length ? encodeBundle(Object.fromEntries(keys.map(k => [k, obj[k]]))) : '';
  $('bundleOut').value = bundle;
  $('envLineOut').value = bundle ? `${BUNDLE_KEY}=${bundle}` : '';
}

function refresh() {
  // Refresh summary + counts — does NOT auto-regenerate bundle (requires explicit button click)
  const obj = collect();
  const keys = Object.keys(obj).sort();
  const s = $('summary');
  if (keys.length) {
    s.innerHTML = `<strong>${keys.length}</strong> variable${keys.length > 1 ? 's' : ''} selected<div class="sum-keys">${keys.map(k => `<span class="sum-key">${esc(k)}</span>`).join('')}</div>`;
  } else {
    s.innerHTML = 'No variables selected yet.';
  }
  updateCounts();
}

function markSelected() {
  document.querySelectorAll('[data-row]').forEach(r => r.classList.toggle('selected', !!r.querySelector('[data-check]')?.checked));
}

function updateCounts() {
  document.querySelectorAll('[id^="nc_"]').forEach(el => el.textContent = '0');
  const byGrp = {};
  document.querySelectorAll('[data-check]:checked').forEach(ch => {
    const g = ch.closest('[data-row]')?.dataset.group;
    if (g) byGrp[g] = (byGrp[g] || 0) + 1;
  });
  const custOn = document.querySelectorAll('[data-custom-row][data-enabled="1"]').length;
  const total = Object.values(byGrp).reduce((a, b) => a + b, 0) + custOn;
  const allEl = document.getElementById('nc_All'); if (allEl) allEl.textContent = total;
  Object.entries(byGrp).forEach(([g, c]) => {
    const el = document.getElementById('nc_' + g.replace(/\W/g, '_'));
    if (el) el.textContent = c;
  });
  const custEl = document.getElementById('nc_Custom_Env'); if (custEl) custEl.textContent = custOn;
}

function filter() {
  const q = $('search').value.trim().toLowerCase();
  document.querySelectorAll('.sec[data-section]').forEach(sec => {
    const grp = sec.dataset.section;
    const gMatch = activeGroup === 'All' || activeGroup === grp;
    if (!gMatch) { sec.classList.add('sec-hidden'); return; }
    let any = false;
    sec.querySelectorAll('[data-row]').forEach(card => {
      const m = !q || card.dataset.search.includes(q);
      card.classList.toggle('hidden', !m);
      if (m) any = true;
    });
    sec.classList.toggle('sec-hidden', !any);
  });
  const cs = $('customSec');
  if (cs) cs.style.display = (activeGroup === 'All' || activeGroup === 'Custom Env') ? '' : 'none';
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.toggle('active', b.dataset.group === activeGroup));
}

function clearForm() {
  document.querySelectorAll('[data-check]').forEach(c => c.checked = false);
  document.querySelectorAll('[data-key]').forEach(el => {
    if (el.closest('[data-toggle-row]')) {
      el.value = 'false';
      const btn = el.closest('.toggle-shell')?.querySelector('[data-toggle]');
      if (btn) { btn.textContent = 'Off'; btn.classList.remove('on'); }
      return;
    }
    el.value = '';
  });
  $('customRows').innerHTML = '';
  customCount = 0;
  addCustomRow();
}

function applyObj(obj, replace = false) {
  if (replace) clearForm();
  for (const [key, val] of Object.entries(obj || {})) {
    if (!safeKey(key)) continue;
    const inp = getFieldValueInput(key);
    const chk = document.querySelector(`[data-check="${CSS.escape(key)}"]`);
    if (inp && chk) {
      inp.value = val;
      chk.checked = true;
      const btn = inp.closest('[data-toggle-row]')?.querySelector('[data-toggle]');
      if (btn) {
        const on = String(val).trim().toLowerCase() === 'true';
        btn.textContent = on ? 'On' : 'Off';
        btn.classList.toggle('on', on);
        inp.value = on ? 'true' : 'false';
      }
    } else {
      addCustomRow(key, val, true);
    }
  }
  markSelected(); filter(); refresh();
}

function autoCheck(key) {
  const chk = document.querySelector(`[data-check="${CSS.escape(key)}"]`);
  if (chk && !chk.checked) { chk.checked = true; markSelected(); }
}

function handlePickerChange(sel) {
  const key = sel.dataset.pickFor;
  const value = sel.value;
  if (!key || !value || value === '__custom__') { if (value === '__custom__') sel.value = ''; return; }
  const inp = getFieldValueInput(key);
  if (!inp) return;
  inp.value = value;
  sel.value = '';
  autoCheck(key);
  refresh();
}

function promptCustomModel(btn) {
  const key = btn.dataset.customFor;
  const inp = getFieldValueInput(key);
  if (!inp) return;
  const text = prompt('Enter a custom value', '');
  if (text === null) return;
  const val = String(text).trim();
  if (!val) return;
  inp.value = val;
  autoCheck(key);
  refresh();
}

function resetPickerField(btn) {
  const key = btn.dataset.clearFor;
  const inp = getFieldValueInput(key);
  if (!inp) return;
  if (inp.closest('[data-toggle-row]')) {
    inp.value = 'false';
    const toggleBtn = inp.closest('.toggle-shell')?.querySelector('[data-toggle]');
    if (toggleBtn) { toggleBtn.textContent = 'Off'; toggleBtn.classList.remove('on'); }
  } else {
    inp.value = '';
  }
  refresh();
}

function toggleField(key) {
  const inp = getFieldValueInput(key);
  if (!inp) return;
  const on = String(inp.value || '').trim().toLowerCase() !== 'true';
  inp.value = on ? 'true' : 'false';
  const btn = inp.closest('.toggle-shell')?.querySelector('[data-toggle]');
  if (btn) { btn.textContent = on ? 'On' : 'Off'; btn.classList.toggle('on', on); }
  const chk = document.querySelector(`[data-check="${CSS.escape(key)}"]`);
  if (chk) { chk.checked = on; markSelected(); }
  refresh();
}

function bindFieldEvents() {
  document.querySelectorAll('[data-check]').forEach(el => el.addEventListener('change', () => { markSelected(); refresh(); }));
  document.querySelectorAll('[data-key]').forEach(el => el.addEventListener('input', refresh));
  document.querySelectorAll('[data-toggle]').forEach(btn => btn.addEventListener('click', () => toggleField(btn.dataset.toggle)));
  document.querySelectorAll('[data-pick-for]').forEach(sel => sel.addEventListener('change', () => handlePickerChange(sel)));
  document.querySelectorAll('[data-custom-for]').forEach(btn => btn.addEventListener('click', () => promptCustomModel(btn)));
  document.querySelectorAll('[data-clear-for]').forEach(btn => btn.addEventListener('click', () => resetPickerField(btn)));
}

function renderSections() {
  const grouped = {};
  FIELDS.forEach(f => { (grouped[f.g] ||= []).push(f); });
  const wrap = $('sections');
  wrap.innerHTML = '';
  Object.entries(grouped).forEach(([grp, items]) => {
    const sec = document.createElement('div');
    sec.className = 'sec';
    sec.dataset.section = grp;
    sec.innerHTML = `<div class="sec-header">
      <span class="sec-icon">${ICONS[grp] || '📁'}</span>
      <span class="sec-title">${esc(grp)}</span>
      <div class="sec-line"></div>
    </div>
    <div class="cards">${items.map(cardHTML).join('')}</div>`;
    wrap.appendChild(sec);
  });
  bindFieldEvents();
}

function copyText(text) {
  return navigator.clipboard.writeText(text).then(
    () => showToast('Copied ✓'),
    () => {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.left = '-9999px';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      ta.remove();
      showToast('Copied ✓');
    }
  );
}

// ── Init ──
renderSidebar();
renderSections();
addCustomRow();
filter();
refresh();

// ── Events ──
$('search').oninput = filter;
$('selectRequired').onclick = () => {
  document.querySelectorAll('[data-critical="1"]').forEach(c => c.checked = true);
  markSelected(); refresh();
  showToast('Critical fields selected ✓');
};
$('selectCommon').onclick = () => {
  document.querySelectorAll('[data-common="1"]').forEach(c => c.checked = true);
  markSelected(); refresh();
};
$('selectVisible').onclick = () => {
  document.querySelectorAll('.sec:not(.sec-hidden) [data-row]:not(.hidden) [data-check]').forEach(c => c.checked = true);
  markSelected(); refresh();
};
$('clearAll').onclick = () => { clearForm(); markSelected(); filter(); refresh(); };
$('generateBundle').onclick = () => { generateBundle(); showToast('Bundle generated ✓'); };
$('applyImport').onclick = () => {
  try { applyObj(parseEnv($('importText').value), true); showToast('Imported ✓'); }
  catch (e) { showToast('Import failed'); alert(e.message); }
};
$('importText').addEventListener('paste', () => {
  setTimeout(() => {
    try {
      const val = $('importText').value.trim();
      if (!val) return;
      applyObj(parseEnv(val), true);
      showToast('Auto-imported ✓');
    } catch (e) { showToast('Import failed'); }
  }, 0);
});
$('importText').addEventListener('input', () => {
  const val = $('importText').value.trim();
  if (!val) return;
  const looksLikeEnv = val.includes('=') || val.startsWith('{') || /^[A-Za-z0-9_\-]{20,}$/.test(val);
  if (looksLikeEnv) {
    try { applyObj(parseEnv(val), true); } catch (e) { /* silent */ }
  }
});
$('addCustom').onclick = () => addCustomRow();
$('applyBundle').onclick = () => {
  try { applyObj(decodeBundle($('bundleOut').value), true); showToast('Bundle applied ✓'); }
  catch (e) { showToast('Invalid bundle'); }
};
$('copyBundle').onclick = () => copyText($('bundleOut').value);
$('copyEnvLine').onclick = () => copyText($('envLineOut').value);
$('copyJson').onclick = () => copyText(JSON.stringify(collect(), null, 2));
