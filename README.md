# clalytics — cài telemetry cho máy bạn

Script này báo **lượng token Claude Code bạn dùng** về dashboard chung của team (để biết ai dùng
bao nhiêu trên account xài chung). Cài **1 lần / máy**, sau đó chạy nền tự động — không cần làm gì thêm.

> Gửi đi: **số token + email/name/team của bạn**. KHÔNG gửi nội dung code, prompt, hay file.

## Cần gì

- Đã cài **Claude Code** (script chỉ thêm cấu hình telemetry cho nó).
- **Node.js** (Claude Code vốn đã cần) — dùng để ghi config an toàn.
- **endpoint + token** → xin admin (Ryan).
- macOS / Linux / Windows (mở **Git Bash**).

## Cài

Xin admin 2 thứ: **ENDPOINT** (URL ingest, vd `https://clalytics.team.io:4318`) và **TOKEN**.

**Cách 1 — one-liner** (điền sẵn endpoint/token, chỉ hỏi email/name/team):
```bash
CLALYTICS_ENDPOINT=<ENDPOINT> CLALYTICS_TOKEN=<TOKEN> \
  bash <(curl -fsSL https://raw.githubusercontent.com/sonnb98/clalytics-client/main/install.sh)
```

**Cách 2 — tải file rồi chạy** (Windows dùng Git Bash):
```bash
curl -fsSL https://raw.githubusercontent.com/sonnb98/clalytics-client/main/install.sh -o clalytics-install.sh
bash clalytics-install.sh
```

Script sẽ hỏi:

| Hỏi | Nhập |
|---|---|
| Email | email của bạn (mặc định lấy từ `git config`) |
| Name | tên bạn |
| Team | team bạn (Platform / Growth / CS…) |
| Endpoint | URL admin đưa (vd `https://clalytics.team.io`) |
| Token | token admin đưa |

Endpoint/token lưu lại cạnh script → lần sau khỏi nhập.

## Xong rồi làm gì

**Mở lại Claude Code** (đóng hẳn rồi mở lại — CLI hoặc IDE). Token tự đẩy về mỗi ~60 giây khi bạn dùng.
Sau vài phút, tên bạn xuất hiện trên dashboard.

## Kiểm tra đã cài

```bash
grep -A15 '"env"' ~/.claude/settings.json
```
Thấy `CLAUDE_CODE_ENABLE_TELEMETRY`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_RESOURCE_ATTRIBUTES` (email/name/team của bạn) là ok.

## Đổi thông tin / gỡ

- **Đổi** email/name/team hay endpoint/token: chạy lại script.
- **Gỡ**: mở `~/.claude/settings.json`, xoá các key `OTEL_*` và `CLAUDE_CODE_ENABLE_TELEMETRY` trong block `"env"`. Script đã backup file cũ tại `~/.claude/settings.json.bak.*`.

## Riêng tư

Chỉ metric số học rời khỏi máy: **số token theo (giờ, loại) + danh tính bạn**. Toàn bộ nội dung phiên
làm việc, mã nguồn, prompt **ở lại máy bạn** — Claude Code không gửi chúng qua kênh telemetry này.
