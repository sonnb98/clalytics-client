# clalytics — cài telemetry Claude Code cho máy bạn

Script này báo **lượng token Claude Code bạn dùng** về dashboard chung của team. Cài **1 lần / máy**,
sau đó chạy nền tự động — không phải làm gì thêm.

> Gửi đi: **số token + email/name/team của bạn**. KHÔNG gửi nội dung code, prompt, hay file.

## Vì sao cần cài

Cả team dùng **chung một account Claude**, mà Anthropic tính tiền theo *account* chứ không theo
*người* — bảng usage của họ chỉ ra đúng một dòng cho cả 20 người. Script này gắn danh tính của bạn
vào metric ngay tại máy, để dashboard tách được ai dùng bao nhiêu.

Không cài thì phần token của bạn vẫn bị tính tiền, chỉ là gộp chung vào một đống vô danh.

## Cần gì

- Đã cài **Claude Code** (script chỉ thêm cấu hình telemetry cho nó, không cài lại Claude).
- **Node.js** — Claude Code vốn đã cần; script dùng nó để sửa JSON config an toàn.
- **ENDPOINT + TOKEN** → xin admin (Ryan). Không public ở đây.
- macOS / Linux / Windows (mở **Git Bash**, không dùng PowerShell).

## Cài

```bash
CLALYTICS_ENDPOINT=<ENDPOINT> CLALYTICS_TOKEN=<TOKEN> \
  bash <(curl -fsSL https://raw.githubusercontent.com/sonnb98/clalytics-client/main/install.sh)
```

Thay `<ENDPOINT>` và `<TOKEN>` bằng giá trị admin gửi. Script hỏi tiếp 3 ô:

| Hỏi | Nhập | Mặc định |
|---|---|---|
| Email | email công ty của bạn | lấy từ `git config user.email` |
| Name | tên bạn | lấy từ `git config user.name` |
| Team | Platform / Growth / CS… | trống |

Endpoint/token được lưu lại cạnh script → chạy lại lần sau khỏi nhập.

Không thích one-liner thì tải file về chạy cũng được:

```bash
curl -fsSL https://raw.githubusercontent.com/sonnb98/clalytics-client/main/install.sh -o clalytics-install.sh
bash clalytics-install.sh
```

## Bắt buộc: mở lại Claude Code

**Đóng hẳn rồi mở lại Claude Code** (CLI hoặc IDE). Cờ telemetry chỉ có hiệu lực từ session mới —
session đang mở sẽ **không** track, và đây là lý do phổ biến nhất khiến "cài rồi mà không thấy tên".

Sau đó token tự đẩy về mỗi ~60 giây. Vài phút sau tên bạn xuất hiện trên dashboard.

## Kiểm tra

```bash
bash clalytics-install.sh status        # ● ON = đang track
grep OTEL_EXPORTER_OTLP_ENDPOINT ~/.claude/settings.json   # có dòng này = đã ghi config
```

Chắc ăn nhất: mở dashboard, đổi khoảng thời gian về **Last 1 hour**, tìm email của bạn trong
bảng *Usage by person*. Không thấy sau ~5 phút dùng Claude → báo admin.

## Xem dashboard

URL admin gửi kèm. Đăng nhập bằng **Google, tài khoản @mageplaza.vn** — trang login chỉ có đúng
một nút đó. Bạn vào với quyền Viewer: xem mọi chart, đổi bộ lọc và khoảng thời gian, nhưng không
sửa được dashboard.

Vài thao tác đáng biết:

- Click **một người** trong bảng → mọi chart lọc theo người đó.
- Click **một cột ngày** trong *Tokens per day* → chart giờ bên dưới nhảy sang ngày đó.
- Bộ lọc **Claude account** — sau này team có nhiều sub thì chọn ở đây.

## Tắt / bật track

Cờ nằm trong `~/.claude/settings.json` nên tắt là tắt **toàn cục**, mọi launcher. Không có cách tắt
riêng một phiên (`claude --notrack` đã bỏ: launcher như daemon spawn `claude` trực tiếp, không qua
login shell nên không đọc được cờ kiểu đó — có giữ lại cũng chỉ tạo cảm giác an toàn giả).

```bash
bash clalytics-install.sh off      # tắt
bash clalytics-install.sh on       # bật lại
bash clalytics-install.sh status   # ● ON / ○ OFF
```

Không giữ file script:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sonnb98/clalytics-client/main/install.sh) off
```

Muốn **một repo cụ thể không bao giờ track**: tạo `.claude/settings.local.json` trong repo đó với
`{"env":{"CLAUDE_CODE_ENABLE_TELEMETRY":"0"}}`.

## Đổi thông tin / gỡ

- **Đổi** email/name/team/endpoint/token: chạy lại script, Enter để giữ giá trị cũ, gõ để đổi.
- **Gỡ**: xoá các key `OTEL_*` và `CLAUDE_CODE_ENABLE_TELEMETRY` trong block `"env"` của
  `~/.claude/settings.json`. Backup nằm ở `~/.claude/settings.json.bak.*`. Không cần đụng
  `~/.zshrc` / `~/.bashrc` — bản hiện tại không sửa shell profile.

## Riêng tư

Chỉ **metric số học** rời khỏi máy: số token theo (giờ, loại token, model) kèm email/name/team bạn
đã nhập. Nội dung phiên làm việc, mã nguồn, prompt, tên file **ở lại máy bạn** — kênh telemetry này
không truyền chúng.

Danh tính gửi qua key **custom** `person_email` / `person_name` / `person_team`, không phải
`user.email`. Lý do: `user.email` là attribute Claude Code tự gắn từ account dùng chung, và khi
trùng key thì **Claude Code luôn giữ giá trị built-in của nó, vứt giá trị của mình** — đặt danh tính
vào đó thì cả 20 người ra cùng một email, im lặng, không báo lỗi gì. Đây là bug đã thật sự xảy ra
với bản đầu tiên; `person_*` là cách duy nhất chạy được.
