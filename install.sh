#!/usr/bin/env bash
#
# user/install.sh — CLIENT: cài telemetry per-user cho Claude Code (clalytics).
# Standalone, publish riêng (curl|bash). Không phụ thuộc phần server.
# Tham khảo stack: github.com/ColeMurray/claude-code-otel (collector+Prometheus+Grafana)
# Bổ sung phần repo thiếu: per-user attribution (OTEL_RESOURCE_ATTRIBUTES) + auth token.
#
# Chạy 1 lần / máy (macOS / Linux):
#     bash install.sh
#     # hoặc:  curl -fsSL https://<host>/install.sh | bash
#     # Windows: mở Git Bash rồi chạy:  bash install.sh
#
# Ghi env OTEL vào ~/.claude/settings.json (merge, backup, không clobber) → Claude Code
# (CLI + IDE) tự đẩy token usage về collector. Không daemon, cài 1 lần là chạy.
# Yêu cầu: node trên PATH (Claude Code vốn cần) — dùng để merge JSON an toàn.

set -euo pipefail

# ==== Toggle track cho session riêng tư ====
# settings.json THẮNG shell env → không tắt được bằng `CLAUDE_CODE_ENABLE_TELEMETRY=0 claude`.
# Phải sửa file. Tắt trước session không muốn track, bật lại khi xong.
#   bash install.sh off      # tắt track (session mở SAU đó không gửi token)
#   bash install.sh on       # bật lại
#   bash install.sh status   # xem đang bật/tắt
case "${1:-}" in
  on|off|status)
    command -v node >/dev/null 2>&1 || { echo "✗ Cần Node.js." >&2; exit 1; }
    MODE="$1" node - <<'NODE'
const fs=require('fs'),path=require('path'),os=require('os');
const file=path.join(os.homedir(),'.claude','settings.json');
let s={};try{s=JSON.parse(fs.readFileSync(file,'utf8')||'{}')}catch(e){}
const on=(s.env||{}).CLAUDE_CODE_ENABLE_TELEMETRY==='1';
if(process.env.MODE==='status'){console.log(on?'● ON — đang track':'○ OFF — không track');process.exit(0);}
if(!s.env){console.error('✗ Chưa cài telemetry. Chạy: bash install.sh');process.exit(1);}
s.env.CLAUDE_CODE_ENABLE_TELEMETRY=process.env.MODE==='on'?'1':'0';
fs.writeFileSync(file,JSON.stringify(s,null,2)+'\n');
console.log(process.env.MODE==='on'
  ? '✓ Bật track. (Mở lại Claude Code nếu đang chạy.)'
  : '✓ Tắt track — session Claude Code mở SAU đây không gửi token. Bật lại: bash install.sh on');
NODE
    exit 0 ;;
esac

# ==== Nạp .env cạnh script (endpoint + token dùng chung cả team) ====
# Chưa có .env → tự tạo template. Có → nạp. Cuối script lưu lại cho lần sau.
SELF="${BASH_SOURCE[0]:-$0}"
ENV_FILE=""
if [ -f "$SELF" ]; then
  ENV_FILE="$(cd "$(dirname "$SELF")" && pwd)/.env"
  if [ -f "$ENV_FILE" ]; then
    set -a; . "$ENV_FILE"; set +a
  else
    printf 'CLALYTICS_ENDPOINT=\nCLALYTICS_TOKEN=\n' > "$ENV_FILE"
    echo "• Tạo $ENV_FILE (lần sau khỏi nhập lại endpoint/token)."
  fi
fi
ENDPOINT="${CLALYTICS_ENDPOINT:-}"   # vd http://<host>:4318 (OTLP HTTP của collector)
TOKEN="${CLALYTICS_TOKEN:-}"         # ingest token (khớp .env server)

# ==== Tự suy person từ git (data tự sinh được → làm default) ====
GIT_EMAIL="$(git config --get user.email 2>/dev/null || true)"
GIT_NAME="$(git config --get user.name 2>/dev/null || true)"
# ====================================================================

# Phát hiện terminal thật (curl|bash: stdin là pipe → phải mở /dev/tty để hỏi)
if { : < /dev/tty; } 2>/dev/null; then HAS_TTY=1; else HAS_TTY=0; fi

ask() { # ask VAR_NAME "prompt" "default"
  local var="$1" prompt="$2" def="${3:-}" cur="${!1:-}"
  local val="${cur:-$def}"
  if [ -z "$val" ]; then
    if [ "$HAS_TTY" != "1" ]; then
      echo "✗ Thiếu '$prompt', không có terminal để hỏi. Cung cấp qua env CLALYTICS_EMAIL/NAME/TEAM/ENDPOINT/TOKEN." >&2
      exit 1
    fi
    while [ -z "$val" ]; do
      printf '%s: ' "$prompt"; read -r val < /dev/tty || true
      [ -z "$val" ] && echo "  (bắt buộc)"
    done
  elif [ -z "$cur" ] && [ "$HAS_TTY" = "1" ]; then
    printf '%s [%s]: ' "$prompt" "$def"; local a=""; read -r a < /dev/tty || true; val="${a:-$def}"
  fi
  printf -v "$var" '%s' "$val"
}

echo "— Cài telemetry Claude Code (clalytics) —"

ask EMAIL    "Email của bạn (user.email)"            "${CLALYTICS_EMAIL:-$GIT_EMAIL}"
ask NAME     "Tên của bạn (user.name)"               "${CLALYTICS_NAME:-$GIT_NAME}"
ask TEAM     "Team của bạn (user.team)"              "${CLALYTICS_TEAM:-}"
ask ENDPOINT "Collector endpoint (vd http://host:4318)" "$ENDPOINT"
ask TOKEN    "Ingest token"                          "$TOKEN"
ENDPOINT="${ENDPOINT%/}"

# Lưu endpoint + token vào .env cho lần sau (gitignored)
if [ -n "$ENV_FILE" ]; then
  printf 'CLALYTICS_ENDPOINT=%s\nCLALYTICS_TOKEN=%s\n' "$ENDPOINT" "$TOKEN" > "$ENV_FILE"
fi

command -v node >/dev/null 2>&1 || {
  echo "✗ Cần Node.js (Claude Code vốn đã cần). Cài node rồi chạy lại." >&2; exit 1;
}

# Merge an toàn vào settings.json bằng node inline (JSON native, backup)
CLALYTICS_EMAIL="$EMAIL" CLALYTICS_NAME="$NAME" CLALYTICS_TEAM="$TEAM" \
CLALYTICS_ENDPOINT="$ENDPOINT" CLALYTICS_TOKEN="$TOKEN" node - <<'NODE'
const fs = require('fs'), path = require('path'), os = require('os');
const email = process.env.CLALYTICS_EMAIL, name = process.env.CLALYTICS_NAME, team = process.env.CLALYTICS_TEAM;
const endpoint = process.env.CLALYTICS_ENDPOINT, token = process.env.CLALYTICS_TOKEN;
const dir = path.join(os.homedir(), '.claude'), file = path.join(dir, 'settings.json');
fs.mkdirSync(dir, { recursive: true });
let s = {};
if (fs.existsSync(file)) {
  const raw = fs.readFileSync(file, 'utf8');
  try { s = raw.trim() ? JSON.parse(raw) : {}; }
  catch (e) { console.error('✗ ~/.claude/settings.json không phải JSON hợp lệ — dừng:', e.message); process.exit(1); }
  fs.writeFileSync(`${file}.bak.${Date.now()}`, raw);
  console.log(`• Backup config cũ → ${file}.bak.*`);
}
s.env = s.env || {};
Object.assign(s.env, {
  CLAUDE_CODE_ENABLE_TELEMETRY: '1',
  OTEL_METRICS_EXPORTER: 'otlp',
  // clalytics cộng dồn phía server → delta (mỗi push gửi phần tăng), khỏi track counter-reset
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE: 'delta',
  OTEL_EXPORTER_OTLP_PROTOCOL: 'http/protobuf',
  OTEL_EXPORTER_OTLP_ENDPOINT: endpoint,
  OTEL_METRIC_EXPORT_INTERVAL: '60000',
  // Account tự track (Claude Code auto-gắn) — key ổn định để chia theo account
  OTEL_METRICS_INCLUDE_ACCOUNT_UUID: 'true',
  OTEL_EXPORTER_OTLP_HEADERS: `Authorization=Bearer ${token}`,
  // Phần repo THIẾU: danh tính NGƯỜI (account chung không tách được) → nhập tay
  OTEL_RESOURCE_ATTRIBUTES: `user.email=${email},user.name=${name},user.team=${team}`,
});
fs.writeFileSync(file, JSON.stringify(s, null, 2) + '\n');
const mask = token.length <= 6 ? '***' : token.slice(0,3)+'***'+token.slice(-2);
console.log('✓ Đã ghi telemetry vào', file);
console.log(`  user.email=${email}  user.name=${name}  user.team=${team}`);
console.log(`  endpoint=${endpoint}  token=${mask}`);
NODE

echo "Xong. Mở lại Claude Code (CLI/IDE) — token tự đẩy về ${ENDPOINT}."
