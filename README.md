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

Xin admin 2 thứ: **ENDPOINT** (URL clalytics, vd `https://clalytics.team.io`) và **TOKEN**.

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

**Đóng hẳn và mở lại Claude Code** (CLI hoặc IDE) — cờ track chỉ có hiệu lực từ session mới.
Token tự đẩy về mỗi ~60 giây khi bạn dùng. Sau vài phút, tên bạn xuất hiện trên dashboard.

## Kiểm tra đã cài

```bash
grep OTEL_EXPORTER_OTLP_ENDPOINT ~/.claude/settings.json   # có endpoint = ok
bash install.sh status                                      # ● ON = đang track
```

## Tắt track — toàn bộ (mọi phiên, mọi launcher)

Cờ track nằm trong `~/.claude/settings.json` → tắt/bật là mức toàn cục, không còn tắt riêng
1 phiên (`claude --notrack` đã bỏ — launcher không qua login shell, vd daemon spawn `claude`
trực tiếp, không thấy được cờ đó nên vô nghĩa).

```bash
bash install.sh off      # tắt hết
bash install.sh on       # bật lại
bash install.sh status   # ● ON / ○ OFF
```
Không giữ file? `bash <(curl -fsSL https://raw.githubusercontent.com/sonnb98/clalytics-client/main/install.sh) off`

Muốn **một dự án luôn không track**: tạo `.claude/settings.local.json` trong repo đó với
`{"env":{"CLAUDE_CODE_ENABLE_TELEMETRY":"0"}}`.

## Đổi thông tin / gỡ

- **Đổi** email/name/team hay endpoint/token: chạy lại script (Enter để giữ, gõ để đổi từng ô).
- **Gỡ**: xoá các key `OTEL_*` (gồm `OTEL_RESOURCE_ATTRIBUTES` chứa `person_email`/`person_name`/
  `person_team`) và `CLAUDE_CODE_ENABLE_TELEMETRY` trong block `"env"` của `~/.claude/settings.json`.
  Backup cũ ở `~/.claude/settings.json.bak.*`. Không còn gì để xoá trong `~/.zshrc` / `~/.bashrc`
  (bản mới không đụng shell profile).

> Danh tính gửi đi qua key **custom** `person_email`/`person_name`/`person_team` — không phải
> `user.email`. `user.email` là attribute Claude Code tự gắn từ account dùng chung, không phân
> biệt được người khi 20 người xài chung 1 account.

## Riêng tư

Chỉ metric số học rời khỏi máy: **số token theo (giờ, loại) + danh tính bạn**. Toàn bộ nội dung phiên
làm việc, mã nguồn, prompt **ở lại máy bạn** — Claude Code không gửi chúng qua kênh telemetry này.
