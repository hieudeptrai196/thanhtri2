# THÀNH TRÌ — Theo dõi tiến độ

> File này để làm tiếp được nếu phiên làm việc bị ngắt. **Cập nhật sau mỗi bước** (bắt đầu, xong, đổi quyết định).
> Kế hoạch dài hạn: [`ROADMAP.md`](ROADMAP.md) · Quy tắc & kiến trúc: [`../CLAUDE.md`](../CLAUDE.md).

## Đang làm

**M1.1 — Lộ trình vô tận** (2026-10-18) — **code xong, test 44/44 xanh, chờ người dùng chơi thử rồi commit**

- [x] `world/endless_route.gd`: đường sinh theo đoạn 20 m, xóa phía sau, địa chỉ bằng quãng đường tuyệt đối, RNG riêng theo seed
- [x] `RouteFollower` dùng `EndlessRoute` (`distance` tăng mãi, điểm dừng mỗi 350 m)
- [x] `world/route_content.gd`: dải đường đất + cây/đá/bom/vòng điểm dừng theo đoạn (30 m đầu trống), xóa vật thể xa phía sau
- [x] Mặt đất đi theo pháo đài (`world/ground_follow.gd`); bỏ tường biên → chiến binh bị giữ trong 90 m quanh pháo đài
- [x] Bỏ điều kiện thắng (endless chỉ thua); màn kết quả hiện quãng đường; Spawner bỏ giới hạn đấu trường
- [x] HUD: dải tiến trình điểm dừng trước → kế tiếp + "Điểm dừng: X m"; thanh máu chiến binh ẩn khi ra khỏi màn hình
- [x] Test mới `test_route.gd` (tất định theo seed, không quay đầu, giới hạn số điểm, bố trí nội dung, chạy 4 km số node không tăng, giới hạn 90 m); viết lại test fortress/bombs/resources/match_flow
- [x] Harness: file test không nạp được → FAIL; mỗi test có giới hạn 7200 frame (treo → FAIL)
- [x] Benchmark lại: không giảm hiệu năng
- [x] Người dùng chơi thử → commit

## Tiếp theo (M1)

- M1.2 Độ khó tăng theo quãng đường
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

## Nhật ký quyết định (mới nhất ở trên)

- 2026-10-18 · Lộ trình endless: **một con đường uốn lượn ngẫu nhiên**, điểm dừng ~350 m; ngã rẽ để M3 nếu cần.
- 2026-10-18 · **Forward+ trên PC, Mobile trên điện thoại; làm xong PC (Steam) trước.**
- 2026-10-18 · Mục tiêu: game nghiêm túc, Steam + Google Play + App Store, endless so quãng đường, i18n bắt buộc.
- 2026-10-18 · Làm đẹp đồ họa sau khi xong vòng chơi (giai đoạn 9 / M2).
- 2026-10-18 · HUD: bố cục gọn gắn vào thế giới. Nâng cấp ở điểm dừng mở bảng trên màn hình.
- 2026-10-18 · Thẻ vũ khí: chọn 1/3, trả Đồng. Pháo đài: cấp vật liệu + ô tháp.
- Xem đầy đủ các quyết định gameplay trong `CLAUDE.md` → "Gameplay đã chốt".

## Câu hỏi đang chờ người dùng

- (không có)

## Ghi chú cho phiên sau

- Chạy test: `tests/run.sh` (phải luôn xanh trước khi báo xong). Benchmark: `tools/benchmark.sh`.
- Godot editor mở sẽ ghi đè `project.godot` → nhờ tắt Godot trước khi sửa file đó.
- Người dùng chơi thử bằng ⌘B, duyệt từng bước rồi mới commit.
