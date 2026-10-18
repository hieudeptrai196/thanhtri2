# THÀNH TRÌ — Theo dõi tiến độ

> File này để làm tiếp được nếu phiên làm việc bị ngắt. **Cập nhật sau mỗi bước** (bắt đầu, xong, đổi quyết định).
> Kế hoạch dài hạn: [`ROADMAP.md`](ROADMAP.md) · Quy tắc & kiến trúc: [`../CLAUDE.md`](../CLAUDE.md).

## Đang làm

**M1.4 — Công trình ngoài thực địa** (2026-10-18) — **code xong, test 56/56, chờ chơi thử rồi commit**. Thông số đã duyệt: tháp nỏ gập (15 Gỗ, 120 máu), rào gỗ cố định
(5 Gỗ, 150 máu, hút quái); tiếp sức trong 12 m quanh pháo đài, ngoài đó bộ đệm 30 s; vác 1 tháp (chạy 5 m/s, không đánh,
đặt lại miễn phí); hết bộ đệm → đòn cuối (bắn ×3 trong 4 s rồi nổ 6 m); xây trong 6 m quanh chiến binh, không trên đường/không
chồng vật cản; trả từ kho chung; kho bắt đầu 30 Gỗ; quái gần công trình (6 m) quay sang đánh; bỏ 4 ô tháp trên pháo đài.

- [x] Dữ liệu: `StructureType` + `StructureTypes`, 2 file `.tres`
- [x] `Structure` (máu, bộ đệm, tiếp sức), `CrossbowTurret` (bắn, đòn cuối, nổ), `Barricade`
- [x] `StructureNetwork` (chứa công trình, luật đặt, tiếp sức, thu hồi) + quyền ở `Match`
- [x] `Builder` (phím 1–4, menu vòng tròn LB, bóng ma xanh/vàng/đỏ, giữ F thu hồi) + `PlayerInput` intent mới
- [x] Chiến binh vác tháp (chậm, không đánh, rơi tháp khi ngã); quái nhắm công trình
- [x] HUD: thanh công trình, trạng thái vác, gợi ý thu hồi, menu vòng tròn; bỏ ô tháp + nút "Xây tháp"
- [x] Test `test_structures.gd` (9 bài) + chụp màn hình — tổng 56/56
- [x] Commit làm nền (người dùng muốn thêm xây chung → M1.4b)

## Tiếp theo (M1, xem ROADMAP)

- M1.4 Công trình ngoài thực địa (nhảy cóc, bộ đệm, đòn cuối)
- M1.5 Chơi thử câu hỏi cốt lõi
- M1.6 Tài nguyên Gỗ/Than/Đồng · M1.7 Tiếng ồn · M1.8 Chọn tuyến · M1.9 Điểm/kỷ lục/seed ngày · M1.10 i18n

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

## Nhật ký quyết định (mới nhất ở trên)

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

- Chơi thử M1.2 (độ khó) và cho phép commit.
- Đã chốt vòng nhảy cóc (phương án 1). (không có — đang làm M1.4)

## Ghi chú cho phiên sau

- Chạy test: `tests/run.sh` (phải luôn xanh trước khi báo xong). Benchmark: `tools/benchmark.sh`.
- Godot editor mở sẽ ghi đè `project.godot` → nhờ tắt Godot trước khi sửa file đó.
- Người dùng chơi thử bằng ⌘B, duyệt từng bước rồi mới commit.
