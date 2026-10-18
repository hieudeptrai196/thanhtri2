# THÀNH TRÌ — Theo dõi tiến độ

> File này để làm tiếp được nếu phiên làm việc bị ngắt. **Cập nhật sau mỗi bước** (bắt đầu, xong, đổi quyết định).
> Kế hoạch dài hạn: [`ROADMAP.md`](ROADMAP.md) · Quy tắc & kiến trúc: [`../CLAUDE.md`](../CLAUDE.md).

## Đang làm

**M1.2 — Độ khó tăng theo quãng đường** (2026-10-18) — **code xong, test 47/47, chờ người dùng chơi thử để cân bằng rồi commit**

- [x] `match/difficulty.gd` + `difficulty_default.tres`: khoảng sinh quái (4.5 s, ×0.7/km, tối thiểu 0.6 s), quái tối đa (30 +30/km, trần 200), máu quái +40%/km, sát thương +25%/km, cỡ đàn 1 +0.75/km (trần 6) [Đề xuất]
- [x] Spawner sinh theo đợt quanh một hướng, theo Difficulty + quãng đường; `Enemy.apply_scaling`
- [x] Cân bằng đầu game: sát thương quái 10 → 5, khoảng sinh đầu 3 → 4.5 s (đứng yên: thành trụ ~49 s / ~127 m, trước là 31 s / 80 m)
- [x] Test `test_difficulty.gd`; ErrorCatcher bỏ qua cảnh báo Jolt ở cả `code` lẫn `rationale`
- [ ] Người dùng chơi thử → chỉnh số → commit
- Ghi chú: bot đánh tự động (scratchpad) bị kẹt sau pháo đài/cây nên **không dùng để cân bằng**; cần người chơi thật.

## Tiếp theo (M1)

- M1.3 Điểm = số mét (HUD, màn kết quả so kỷ lục)
- M1.4 Lưu kỷ lục + cài đặt (`user://`)
- M1.5 Hạ tầng i18n (Việt + Anh) + màn chọn ngôn ngữ — **cần sửa `project.godot` → nhờ người dùng tắt Godot**

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

## Nhật ký quyết định (mới nhất ở trên)

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

- Chơi thử M1.2 (độ khó) và cho phép commit.
- Đã chốt vòng nhảy cóc (phương án 1). **Đang hỏi tiếp:** danh sách tính năng riêng của người dùng → chi tiết công trình (mang theo, bộ đệm, đòn cuối, số loại). M1.2 (độ khó theo quãng đường) được giữ làm nền, chờ chơi thử rồi commit.

## Ghi chú cho phiên sau

- Chạy test: `tests/run.sh` (phải luôn xanh trước khi báo xong). Benchmark: `tools/benchmark.sh`.
- Godot editor mở sẽ ghi đè `project.godot` → nhờ tắt Godot trước khi sửa file đó.
- Người dùng chơi thử bằng ⌘B, duyệt từng bước rồi mới commit.
