# THÀNH TRÌ — Theo dõi tiến độ

> File này để làm tiếp được nếu phiên làm việc bị ngắt. **Cập nhật sau mỗi bước** (bắt đầu, xong, đổi quyết định).
> Kế hoạch dài hạn: [`ROADMAP.md`](ROADMAP.md) · Quy tắc & kiến trúc: [`../CLAUDE.md`](../CLAUDE.md).

## Đang làm

**M1.4b — Xây chung** (2026-10-18, **code xong, test 61/61, chờ chơi thử**; ý 1 + ý 5 trong phản hồi của người dùng, ý 2–4 sang M2)

- Đặt **bản vẽ** miễn phí (ai cũng đặt); đặt tháp đang vác thì xong ngay (giữ nhịp nhảy cóc)
- **Gõ**: giữ E cạnh bản vẽ (khi không ở chế độ xây); tháp nỏ 4 s, rào 2 s một người; nhiều người: tốc độ × n^0.85; không tự đánh khi gõ
- **Trả Gỗ dần**: túi người gõ trước, rồi kho; thiếu thì dừng + báo "thiếu Gỗ"
- Bản vẽ: mờ, không bắn, quái không đánh/không hút; giữ F trên bản vẽ = dỡ, hoàn Gỗ đã góp về kho
- **Thu hồi chung**: tiến độ giữ F tính trên công trình (2 người = nhanh gấp đôi)

- [x] Code (`Structure` trạng thái xây + trả dần + thu hồi chung, `StructureNetwork.place_blueprint/dismantle/nearest_blueprint`, `Builder` gõ/thu hồi chung, `Match`, HUD gợi ý)
- [x] Test (gõ một mình, 2 người nhanh ~1.8×, trả từ túi trước, hết Gỗ thì dừng, bản vẽ không bắn/không bị đánh, dỡ hoàn Gỗ, 2 người thu hồi nhanh gấp đôi) — tổng 61/61
- [x] Commit + push theo yêu cầu (người dùng **chưa chơi thử** M1.4b)

## Tiếp theo (M1, xem ROADMAP)

- M1.5 Tự vệ cơ bản của pháo đài (nỏ liên châu + chông gai) + chơi thử câu hỏi cốt lõi + cân bằng
- M1.6 Tài nguyên Gỗ/Than/Đồng + module pháo đài (thân, nâng nỏ, dầu sôi, lò lửa Than, khiên)
- M1.7 Tiếng ồn/truy đuổi + Nỏ thần · M1.8 Chọn tuyến · M1.9 Điểm/kỷ lục/seed ngày · M1.10 i18n

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

## Nhật ký quyết định (mới nhất ở trên)

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

- **Bàn giao 2026-10-18 (người dùng sắp hết token, sẽ quay lại):** M1.4b đã commit + push nhưng **chưa được chơi thử**.
  Khi quay lại: (1) nhờ người dùng chơi thử M1.4b — để ý việc phải giữ E mới xây có làm solo chậm quá không;
  (2) làm **M1.5**: thêm **tự vệ cơ bản của pháo đài** (nỏ liên châu yếu tầm ngắn + chông gai phản sát thương), rồi hỏi cảm nhận câu hỏi cốt lõi "nhảy cóc có vui không" và cân bằng (thời gian gõ, giá, bộ đệm, độ khó đầu game, sức nỏ của thành).
- Tiếp sau M1.5: M1.6 tài nguyên Gỗ/Than/Đồng (bỏ Đá) + module pháo đài → M1.7 tiếng ồn/truy đuổi + Nỏ thần → M1.8 chọn tuyến → M1.9 điểm/kỷ lục/seed ngày → M1.10 i18n.

## Ghi chú cho phiên sau

- Chạy test: `tests/run.sh` (phải luôn xanh trước khi báo xong). Benchmark: `tools/benchmark.sh`.
- Godot editor mở sẽ ghi đè `project.godot` → nhờ tắt Godot trước khi sửa file đó.
- Người dùng chơi thử bằng ⌘B, duyệt từng bước rồi mới commit.
