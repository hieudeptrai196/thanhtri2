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
- [x] **M2.1c** Công trình (bản vẽ → xây xong → thu hồi / nổ đòn cuối, theo `net_id`; client đặt + gõ búa qua ý định), đống đồ rơi, cây/than bị khai thác + bom nổ (theo `content_id` = thứ tự sinh nội dung, giống nhau mọi máy), vệt bắn của nỏ, nhát chém của người khác, thông báo (toast) gửi kèm chữ gốc để mỗi máy dịch theo ngôn ngữ riêng. 4 test mới, 106 xanh, smoke OK. Commit `6a54ec5`.
- [x] **M2.1d** Điểm dừng chung: bảng hiện trên mọi máy (snapshot `stop`), client mua / chọn tuyến / sẵn sàng qua `NetSync.client_request` → `Match.handle_request`; **tất cả sẵn sàng mới khởi hành** (người rời phòng không chặn); mỗi người mua 1 thẻ cho vũ khí của mình; toast điểm dừng / khởi hành gửi mọi máy. 4 test mới, 110 xanh, smoke OK, ảnh 1280×720 Việt + Anh vừa. Commit `8e3d23e`.
  - [Chốt 2026-10-18] cả đội thấy cùng 3 thẻ, mỗi người mua tối đa 1 (trả từ kho chung); ai cũng chọn được tuyến, người chọn sau cùng thắng; đã bấm sẵn sàng thì không hủy được.
- Chưa thử 2 cửa sổ có hình (chỉ headless). Muốn thử: chạy 2 bản Godot, một bên Tạo phòng, bên kia Vào phòng 127.0.0.1.

**M2.2 — 5 class = vai trò** (bắt đầu 2026-10-18; bảng class đã duyệt, co-op nâng lên 5 người)

- [x] **M2.2a** Khung class (`classes/`: `PlayerClass` .tres + `PlayerClasses`), điểm mạnh thụ động: Công binh (búa ×1.5, sửa ×1.5, vác 2), Tiều phu (túi ×2, chạy ×1.25 khi rỗng), Võ tướng (máu ×1.5, sát thương ×1.3), Thầy pháp (công trình trong 8 m bắn ×1.3), Thợ máy (cả đội: tăng tốc tốn Than ×0.6, nâng cấp thành ×0.85). Chọn vai trò ở màn bắt đầu + phòng chờ (lưu trong SaveManager), gửi lên host qua `client_ready`, đồng bộ màu/class cho mọi máy. 8 test mới, 119 xanh; ảnh 1280×720 Việt + Anh vừa (đã thu gọn màn bắt đầu). Commit `04d6704`. Số liệu = Đề xuất.
- [x] **M2.2b** 5 kỹ năng chủ động (R / LT, chạy trên host, `ClassSkills` + số liệu trong `PlayerClass`): Dựng tốc (bản vẽ trong 8 m ×3 trong 5 s, hồi 20 s), Bổ mạnh (lấy 3 đơn vị từ cây/mỏ phía trước, hồi 8 s), Hét trận (quái trong 10 m lao vào mình, nhận ½ sát thương 4 s, hồi 15 s), Bùa trận (vùng 5 m tại điểm ngắm: hồi 8 máu/s người, 12/s công trình, quái chậm ½, 6 s, hồi 20 s), Đốt lò (tăng tốc 8 s không tốn thêm Than, hồi 30 s). Không có gì để tác động thì không mất lượt. Ô kỹ năng + hồi chiêu trên HUD; client thấy vùng/xung. 7 test mới, 126 xanh, smoke OK. Commit `3cc5a11`. Số liệu = Đề xuất.

**M2.3 — Đỡ đồng đội, ụ nỏ có người điều khiển, ping, kết hợp class** (bắt đầu 2026-10-18, người dùng: "cứ làm tiếp đi")

- [x] **M2.3a** Đỡ đồng đội dậy: khi có đồng đội, 0 máu → **gục** 15 s (người dùng bảo tăng từ 10) (vẫn giữ đồ, quái bỏ qua), đồng đội đứng ≤ 2 m giữ E 3 s (nhiều người nhanh hơn, đang được đỡ thì ngừng đếm ngược) → dậy với 40% máu; hết giờ → ngã như cũ (rơi đồ, hồi sinh ở thành). Solo không đổi. Nhãn trên đầu + lời nhắc HUD. Kèm sửa mạng: snapshot **nén + chia gói ≤ 1200 B** (trước đó 5 người đã vượt MTU): 0 quái ≈ 0.3 KB, 300 quái ≈ 5.7 KB/lần. 6 test mới, 132 xanh, smoke OK. Commit `6bca219`. Số liệu = Đề xuất.
- [x] **M2.3b (commit `6a99a91`, 2026-10-19):** [Chốt 2026-10-19] dùng chính nỏ liên châu trên thành, cho 1 người vào điều khiển (không làm ụ riêng). Thang ở đuôi thành: đứng cạnh chân thang (≤ 2 m), tay không, không đang xây → nhấn E leo lên; E hoặc dash để xuống. Khi có người: bắn mục tiêu gần hướng ngắm nhất (nón 35°), không có thì không bắn; sát thương ×2.5, tốc độ bắn ×1.6, tầm ×1.5 (cộng dồn với cấp nâng nỏ ở điểm dừng); không ai thì tự bắn yếu như cũ. Mỗi lúc 1 người. Người trên nỏ: quái không đuổi, gục/ngã thì nỏ trống lại và rơi ở chân thang. Đồng bộ mạng (sự kiện `interact`, `gunner`/`gun_yaw` trong snapshot thành, `manning` của chiến binh). 8 test mới, 140 xanh, smoke OK, ảnh 1280×720 Việt + Anh vừa. Số liệu = Đề xuất. Ghi chú cũ: ụ nỏ có người điều khiển trên thành (đứng vào ô trên thành → ngắm bắn mạnh bằng chuột/stick; không ai đứng thì tự bắn yếu như nỏ liên châu hiện có). Cần chốt với người dùng: vị trí ụ, cách vào/ra (E?), sát thương/tốc độ, có nâng cấp ở điểm dừng không. Sau đó M2.3c ping, M2.3d kết hợp class, rồi M2.4 độ khó theo số người, M2.5 tổng kết MVP.
- [x] **M2.3c (commit `3d8002a`, 2026-10-19): ping.** [Chốt 2026-10-19] 1 phím theo ngữ cảnh (không làm vòng chọn). Z / chuột giữa / D-pad xuống ping chỗ con trỏ (tay cầm: điểm trước mặt theo hướng ngắm). Host chọn nghĩa theo thứ ở đó (≤ 2.5 m): quái → "Quái ở đây!", bản vẽ → "Xây giúp ở đây", công trình → "Thu <tên> này", đống đồ → "Đồ rơi ở đây", cây/mỏ → "Lấy <Gỗ/Than> ở đây", thân thành → "Về giữ thành!", còn lại "Đến đây". Dấu = vòng + cột sáng + chữ theo màu người ping, 4 s; mỗi người 1 dấu (dấu mới thay dấu cũ), chặn spam 0.6 s, xa quá 45 m thì kéo vào. Khuất màn hình → mũi tên ở rìa (`PingIndicators`). Đồng bộ: sự kiện `ping` (host kiểm tra Vector3) → fx `ping`. 6 test mới, 146 xanh, smoke OK, ảnh 1280×720 Việt + Anh vừa. Số liệu = Đề xuất. 
- [x] **M2.3d — XONG, CHỜ DUYỆT (2026-10-19): kết hợp class.** 7 test mới, 153 xanh, smoke OK, ảnh 1280×720 Việt + Anh vừa. Thông báo khi trấn yểm / khắc phù / Đốt lò có người điều khiển nỏ; tháp khắc phù có viên phù tím. Kèm sửa: `_toast_all` trên host giờ dịch cả tên chèn vào (trước đó tên tuyến khi khởi hành không được dịch trên host). Chưa ghi kết hợp vào mô tả class ở màn chọn. Tiếp: M2.4 độ khó theo số người. [Chốt 2026-10-19] làm cả 4: (1) Võ tướng × Thầy pháp: quái bị Hét trận trong Bùa trận chậm ¼ + nhận thêm 30% sát thương; (2) Công binh × Thầy pháp: tháp Công binh gõ xong trong hào quang Thầy pháp được khắc phù, bắn nhanh ×1.25 vĩnh viễn (cộng hào quang); (3) Tiều phu × Công binh: người gõ bản vẽ lấy Gỗ từ túi Tiều phu đứng ≤ 4 m trước kho, người gõ là Công binh thì 1 Gỗ đó tính 1.5; (4) Thợ máy × người điều khiển nỏ: trong Đốt lò nỏ có người bắn nhanh ×1.5, chính Thợ máy điều khiển thì tầm +20%. Số liệu = Đề xuất.
- **Bản nháp tiêu chuẩn asset:** `docs/ASSET_SPEC.md` (2026-10-18, chờ người dùng review; hoàn thiện ở M3 B1).
- Người dùng **chưa chơi thử** từ M1.4b tới giờ (cả M2): nên nhắc chơi thử + cân bằng khi có dịp.

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
| M2.1c | `6a54ec5` | Đồng bộ công trình, đồ rơi, cây/than, bom, hiệu ứng |
| M2.1d | `8e3d23e` | Điểm dừng chung, tất cả sẵn sàng mới khởi hành, thẻ vũ khí theo người — M2.1 xong |
| M2.2a | `04d6704` | 5 class = vai trò, điểm mạnh thụ động, chọn vai trò |
| M2.2b | `3cc5a11` | 5 kỹ năng chủ động — M2.2 xong |
| M2.3a | `6bca219` | Đỡ đồng đội dậy (gục 15 s), snapshot nén + chia gói |
| M2.3b | `6a99a91` | Điều khiển nỏ liên châu trên thành |
| M2.3c | `3d8002a` | Ping theo ngữ cảnh |

## Nhật ký quyết định (mới nhất ở trên)

- 2026-10-18 · **Vũ khí của thành là một phần nâng cấp pháo đài ở điểm dừng, trả bằng nguyên liệu kiếm được (giá trộn Gỗ/Than/Đồng).**
- 2026-10-18 · **Pháo đài tự phòng thủ (khác spec gốc), lấy cả 6 ý:** nỏ liên châu yếu + chông gai (M1.5), module nâng nỏ / dầu sôi / lò lửa Than / khiên tự hồi (M1.6), Nỏ thần (M1.7), ụ nỏ có người điều khiển (M2.3). Thành chỉ xử lý quái sát thân; tuyến chính vẫn là công trình + người chơi.
- 2026-10-18 · **Xây chung**: bản vẽ + cả đội cùng gõ (nhiều người nhanh hơn), góp Gỗ trực tiếp, thu hồi chung nhanh hơn. Ý 2–4 (đa vật liệu, gia cố, liên kết) để M2.
- 2026-10-18 · Điều khiển xây: phím 1–4 + chuột trên PC, menu vòng tròn (LB) cho tay cầm; xây thời gian thực, không slow-mo.
- 2026-10-18 · Chọn ý tưởng 1,2,4,5,7–18 (19 ưu tiên thấp); co-op tối đa 4; roadmap viết lại (M1 vòng cốt lõi → M2 co-op…).
- 2026-10-18 · **Co-op tối đa 5 người** (đổi từ 4): 5 class = 5 vai trò, đủ người thì mỗi người một class. `Net.MAX_PLAYERS = 5`.
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
