# THÀNH TRÌ — Theo dõi tiến độ

> File này để làm tiếp được nếu phiên làm việc bị ngắt. **Cập nhật sau mỗi bước** (bắt đầu, xong, đổi quyết định).
> Kế hoạch dài hạn: [`ROADMAP.md`](ROADMAP.md) · Quy tắc & kiến trúc: [`../CLAUDE.md`](../CLAUDE.md).

## Đang làm

**M2.1 — Mạng co-op nền** (bắt đầu 2026-10-18; người dùng bảo "tiếp đi" — chưa chơi thử M1, cân bằng để sau)

Chia nhỏ: **M2.1a** lớp mạng (ENet, host-authoritative) + phòng chờ (Tạo phòng / Vào phòng bằng IP, cổng 24690) + mỗi người
một chiến binh + ý định gửi lên máy chủ + đồng bộ chiến binh & trạng thái thành · M2.1b quái · M2.1c công trình / túi đồ /
cây-than bị khai thác · M2.1d điểm dừng chung (bảng, chọn tuyến, tất cả sẵn sàng mới đi), kết quả.
Nguyên tắc: solo = máy chủ không ai vào, cùng một đường code; đường + nội dung không gửi qua mạng (sinh từ seed).

- [x] **M2.1a** Match nhiều chiến binh; `net/` + phòng chờ trong màn bắt đầu; ý định client → host, snapshot thành/tiếng ồn/tuyến/chiến binh → client; client không tự mô phỏng; 9 test co-op trong cùng process + `tools/net_smoke.sh` (2 tiến trình thật: tạo phòng → vào → bắt đầu → cùng seed) — 100 test xanh
- [x] **M2.1b** Quái: host sinh + mô phỏng, client hiện theo `net_id` (vị trí trượt mượt, máu + chớp khi trúng đòn, biến mất khi chết / dọn ở điểm dừng), quái client không va chạm / không gây sát thương. 2 test mới, 102 xanh, smoke 2 tiến trình OK. Commit `5bf0337`. Snapshot: ~0.6 KB + 28 B/quái (300 quái ≈ 9 KB × 20 Hz ≈ 180 KB/s mỗi client — ổn LAN; chơi qua internet nên nén sau). Rơi đồ → M2.1c. Chưa thấy hiệu ứng bắn của nỏ trên client.
- [x] **M2.1c** Công trình (bản vẽ → xây xong → thu hồi / nổ đòn cuối, theo `net_id`; client đặt + gõ búa qua ý định), đống đồ rơi, cây/than bị khai thác + bom nổ (theo `content_id` = thứ tự sinh nội dung, giống nhau mọi máy), vệt bắn của nỏ, nhát chém của người khác, thông báo (toast) gửi kèm chữ gốc để mỗi máy dịch theo ngôn ngữ riêng. 4 test mới, 106 xanh, smoke OK. **Chưa commit — chờ duyệt.**
- [ ] **M2.1d** Điểm dừng chung: bảng nâng cấp + chọn tuyến trên mọi máy, tất cả sẵn sàng mới đi; thẻ vũ khí theo từng người; kết quả
- Chưa thử 2 cửa sổ có hình (chỉ headless). Muốn thử: chạy 2 bản Godot, một bên Tạo phòng, bên kia Vào phòng 127.0.0.1.

## Tiếp theo (M2, xem ROADMAP)

- M2.1 Mạng co-op nền (host-authoritative, ENet, test 2–4 cửa sổ trên cùng máy), kho chung + túi riêng
- M2.2 5 class = vai trò · M2.3 đỡ đồng đội, kết hợp class, ping, ụ nỏ có người điều khiển · M2.4 độ khó theo số người · M2.5 tổng kết MVP
- Trước M2 nên có một lượt **chơi thử + cân bằng** toàn bộ M1 (người dùng chưa chơi thử từ M1.4b).

## Đã xong

| Giai đoạn | Commit | Nội dung |
|---|---|---|
| 0 | `59e123e` | Khung project, input map |
| 1 | `3a7cf6d` | Pháo đài tự chạy theo lộ trình, camera isometric |
| 2 | `e28c56e` | Chiến binh di chuyển, `PlayerInput` |
| 3 | `c5c3a55` | Máu, sát thương, đánh chủ động ngắm chuột |
| 4 | `1894085` | Quái + Spawner, hồi sinh |
| 5 | `2cb2b0d` | Tài nguyên Gỗ/Đá/Đồng, khai thác, nộp, sửa, rơi đồ |
| Harness | `ab2a498` | Test tự động + `CLAUDE.md` |
| 6a | `84445aa` | Bảng nâng cấp, thân gỗ → đá, tháp |
| 6b | `ab16ce9` | Thẻ vũ khí, style UI, chỗ gắn asset |
| 6c | `b63e53e` | Bom ẩn; runner bắt lỗi engine |
| 7 | `5df4522` | Thắng/thua/chơi lại, HUD |
| 8 | `6c2ba01` | Benchmark M1 Pro, F3, roadmap |
| — | `a254fbd` | Roadmap: PC trước, di động sau |
| — | `ef650ec` | `docs/PROGRESS.md` |
| M1.1 | `ab03fb0` | Lộ trình vô tận, nội dung theo đoạn, harness timeout |
| M1.2 | `c85f80e` | Độ khó theo quãng đường |
| M1.3 | `5e07fb1` | Tự đánh + dash |
| M1.4 | `46b4449` | Công trình ngoài thực địa, nhảy cóc |
| M1.4b | `22a9e29` | Xây chung |
| M1.5 | `9970e8a` | Thành tự vệ cơ bản |
| M1.6a | `fc24be8` | Than, tăng tốc, mỏ than, bỏ Đá |
| M1.6b | `cbc4495` | Nâng cấp pháo đài giá trộn: nỏ 3 cấp, dầu sôi, lò lửa Than, khiên 2 cấp; bảng điểm dừng 2 cột |
| M1.7 | `4f959c5` | Tiếng ồn + truy đuổi, Nỏ thần |
| M1.8 | `e670fa4` | Chọn 1/2 tuyến ở điểm dừng (4 loại tuyến), hoãn nội dung tới khi chọn |
| M1.9 | `d897f42` | Điểm = mét, kỷ lục lưu máy, seed ngày, màn bắt đầu, kết quả mới |
| M1.10 | `695f0a0` | i18n Việt + Anh, chọn ngôn ngữ lần đầu, công cụ trích chuỗi |
| M2.1a | `7d6f4b3` | Mạng ENet host-authoritative, phòng chờ, mỗi người một chiến binh, đồng bộ thành + chiến binh |
| M2.1b | `5bf0337` | Đồng bộ quái host → client |

## Nhật ký quyết định (mới nhất ở trên)

- 2026-10-18 · **Vũ khí của thành là một phần nâng cấp pháo đài ở điểm dừng, trả bằng nguyên liệu kiếm được (giá trộn Gỗ/Than/Đồng).**
- 2026-10-18 · **Pháo đài tự phòng thủ (khác spec gốc), lấy cả 6 ý:** nỏ liên châu yếu + chông gai (M1.5), module nâng nỏ / dầu sôi / lò lửa Than / khiên tự hồi (M1.6), Nỏ thần (M1.7), ụ nỏ có người điều khiển (M2.3). Thành chỉ xử lý quái sát thân; tuyến chính vẫn là công trình + người chơi.
- 2026-10-18 · **Xây chung**: bản vẽ + cả đội cùng gõ (nhiều người nhanh hơn), góp Gỗ trực tiếp, thu hồi chung nhanh hơn. Ý 2–4 (đa vật liệu, gia cố, liên kết) để M2.
- 2026-10-18 · Điều khiển xây: phím 1–4 + chuột trên PC, menu vòng tròn (LB) cho tay cầm; xây thời gian thực, không slow-mo.
- 2026-10-18 · Chọn ý tưởng 1,2,4,5,7–18 (19 ưu tiên thấp); co-op tối đa 4; roadmap viết lại (M1 vòng cốt lõi → M2 co-op…).
- 2026-10-18 · **Endless + chọn 1/2 tuyến ở mỗi điểm dừng** (thay quyết định "một đường, ngã rẽ để M3").
- 2026-10-18 · **Độ khó: quãng đường làm nền (M1.2 giữ lại) + thanh tiếng ồn / truy đuổi.**
- 2026-10-18 · **Tài nguyên: Gỗ (xây/sửa), Than (nhiên liệu, tăng tốc), Đồng (vũ khí/kỹ năng/module); bỏ Đá.**
- 2026-10-18 · **Đòn thường tự đánh, kỹ năng class bấm chủ động + ngắm.**
- 2026-10-18 · **Lấy vòng chính của Marcha de Ferro: đặt công trình ngoài thực địa, tiếp sức gần pháo đài, nhảy cóc / bỏ lại.** Các chi tiết khác đang hỏi tiếp.
- 2026-10-18 · Game tham khảo: Marcha de Ferro (+ co-op + tính năng riêng). Xem `REFERENCE.md`.
- 2026-10-18 · Lộ trình endless: **một con đường uốn lượn ngẫu nhiên**, điểm dừng ~350 m; ngã rẽ để M3 nếu cần.
- 2026-10-18 · **Forward+ trên PC, Mobile trên điện thoại; làm xong PC (Steam) trước.**
- 2026-10-18 · Mục tiêu: game nghiêm túc, Steam + Google Play + App Store, endless so quãng đường, i18n bắt buộc.
- 2026-10-18 · Làm đẹp đồ họa sau khi xong vòng chơi (giai đoạn 9 / M2).
- 2026-10-18 · HUD: bố cục gọn gắn vào thế giới. Nâng cấp ở điểm dừng mở bảng trên màn hình.
- 2026-10-18 · Thẻ vũ khí: chọn 1/3, trả Đồng. Pháo đài: cấp vật liệu + ô tháp.
- Xem đầy đủ các quyết định gameplay trong `CLAUDE.md` → "Gameplay đã chốt".

## Câu hỏi đang chờ người dùng

- M1 đã xong. Người dùng **chưa chơi thử** các bước từ M1.4b → M1.10; nên chơi thử + cân bằng trước khi sang M2 (hoặc làm M2.1 trước nếu người dùng muốn).

## Ghi chú cho phiên sau

- Chạy test: `tests/run.sh` (phải luôn xanh trước khi báo xong). Benchmark: `tools/benchmark.sh`.
- Godot editor mở sẽ ghi đè `project.godot` → nhờ tắt Godot trước khi sửa file đó.
- Người dùng chơi thử bằng ⌘B, duyệt từng bước rồi mới commit.
