# THÀNH TRÌ

Game roguelite hành động 3D isometric, cảm hứng dân gian Việt Nam. Godot **4.7.2**, **GDScript**, Forward Plus, Jolt Physics. Máy dev: MacBook Pro 14" **M1 Pro** (8 nhân, 32 GB, màn 120 Hz, macOS). Trả lời người dùng bằng **tiếng Việt**.

**Mục tiêu:** game nghiêm túc, phát hành **Steam + Google Play + App Store**, chế độ chính **endless** (so ai đi xa hơn), asset tử tế, **i18n bắt buộc**. Kế hoạch đầy đủ: [`docs/ROADMAP.md`](docs/ROADMAP.md). **Làm xong bản PC trước**, port di động sau (Forward+ trên PC, Mobile trên điện thoại); nhưng không khóa đường di động (input qua `PlayerInput`, chữ qua `tr()`, UI co giãn, hiệu ứng Forward+ phải có phương án thay thế).

## Cách làm việc (bắt buộc)

- **Đầu mỗi phiên đọc [`docs/PROGRESS.md`](docs/PROGRESS.md)** (đang làm gì, dang dở gì, câu hỏi chờ). **Cập nhật file đó sau mỗi bước** (bắt đầu, xong, commit, đổi quyết định) để làm tiếp được nếu phiên bị ngắt.
- Làm theo **từng giai đoạn nhỏ**, mỗi giai đoạn kiểm thử độc lập được. Xong một giai đoạn thì báo kết quả và **chờ người dùng duyệt** rồi mới commit / làm tiếp.
- Luôn phân biệt **[Chốt]** (người dùng đã xác nhận), **[Đề xuất]** và **[Mở]**. Không tự chốt nội dung gameplay: tên quái, vũ khí, kỹ năng, nâng cấp, điều kiện thắng, lộ trình…
- Cần quyết định thì hỏi **một câu quan trọng nhất** trước, kèm phương án đề xuất.
- Không cam kết hiệu năng khi chưa đo (dùng `tools/benchmark.sh`).
- Không cài plugin, không dùng API key, **không push**, không deploy khi chưa được phép. Commit local khi người dùng đồng ý; message tiếng Việt dạng `Giai đoạn N: ...`.
- **Godot editor đang mở sẽ ghi đè `project.godot`** bằng bản trong bộ nhớ. Trước khi sửa `project.godot` (input map, layer, setting): nhờ người dùng thoát Godot (⌘Q, Don't Save) và kiểm tra bằng `pgrep -fl Godot`. Sửa scene/script thì để editor mở được, nhắc người dùng chọn Reload.
- Phím tắt trên Mac: chạy game ⌘B, chạy scene ⌘R, dừng ⌘. (không phải F5/F6/F8).

## Kiểm thử

```sh
tests/run.sh            # chạy toàn bộ, ~vài giây, exit 1 nếu có test hỏng
tests/run.sh test_enemies                  # lọc theo "file::tên_test"
GODOT=/đường/dẫn/Godot tests/run.sh        # nếu Godot không ở /Users/mac/Downloads/Godot.app
```

- Test nằm ở `tests/test_*.gd`, kế thừa `GameTest` (`tests/game_test.gd`): `start_match()`, `frames()`, `seconds()`, `check()`, `check_near()`, `aim_at()`, `attack_until_freed()`, `spawn_dummy()`.
- Mỗi giai đoạn mới **phải thêm test** cho hành vi mới và chạy lại toàn bộ trước khi báo xong.
- Khi có kết quả trận, cây scene bị tạm dừng; `GameTest.cleanup()` tự bỏ tạm dừng. Nút Chơi lại gọi `reload_current_scene()`, harness không có current scene nên test phải ngắt `m.restart` trước khi bấm.
- Bẫy hay gặp khi viết test: dịch chuyển chiến binh ra khỏi vùng quanh pháo đài rồi `await frames(2)` trước khi nhét đồ vào túi, nếu không `ServiceZone` sẽ nộp mất.
- Kiểm tra cú pháp nhanh: `Godot --headless --path . --quit`.

## Hiệu năng

- `tools/benchmark.sh [WxH]`: mở cửa sổ, tắt vsync, tăng dần số quái (0→300) quanh pháo đài, in FPS / ms / khung tệ nhất / ms vật lý / draw call. Trong trận bấm **F3** để bật lớp số liệu.
- Đo trên M1 Pro (2026-10-18), Forward+ / Metal, quái placeholder:

| Quái | 1600×900: FPS tb / khung tệ nhất | 1512×982: FPS tb / khung tệ nhất | Vật lý mỗi nhịp |
|---|---|---|---|
| 50 | 361 / 10.7 ms | 145 / 10.1 ms | ~3–4 ms |
| 150 | 335 / 9.9 ms | 145 / 12.3 ms | ~4–4.6 ms |
| 300 | 184 / 21.5 ms | 145 / 16.5 ms | ~9.4–9.9 ms |

- Ở 1512×982 FPS bị chặn trần ~145 (không phải giới hạn máy). Chi phí lớn dần là **vật lý của quái** (mỗi quái là CharacterBody3D + move_and_slide + Area3D): khoảng +0.03 ms/quái/nhịp. Nếu cần nhiều quái hơn, đây là chỗ tối ưu đầu tiên. Số đo chỉ đúng cho máy này và cảnh placeholder; giai đoạn làm đẹp phải đo lại.

## Kiến trúc

| Thư mục | Nội dung |
|---|---|
| `match/` | `match.gd` (gốc một trận: nối mọi hệ thống, giữ RNG theo seed, luồng dừng/khởi hành/hồi sinh, thắng/thua → tạm dừng cây + màn kết quả, chơi lại = nạp lại scene), `spawner.gd` |
| `fortress/` | `Fortress` (máu → tốc độ, kho, sửa), `RouteFollower` (chạy theo `Path3D`, dừng tại `Marker3D`), `ServiceZone` (nộp đồ, giữ interact để sửa) |
| `player/` | `Warrior`, `PlayerInput` |
| `combat/` | `HealthComponent`, `Hurtbox`, `MeleeWeapon`, bia thử |
| `enemies/` | `Enemy` |
| `resources/` | `ResourceType` (.tres trong `types/`), `ResourceTypes.ALL`, `Inventory`, `ResourceNode` (cây/đá), `Pickup` |
| `camera/`, `world/` | Camera isometric orthographic, shader nền |
| `ui/` | `UiStyle` (style chung), `Hud` (HUD trong trận), `ResultScreen`, `UpgradePanel` (bảng ở điểm dừng), `WeaponCard`, `ResourceCounter`, `RouteProgress` |
| `tests/` | Test harness |
| `tools/` | `benchmark.sh` (không thuộc bản build) |

Nguyên tắc:
- **Chỉ `PlayerInput` được đọc `Input`.** Gameplay đọc ý định (`move_direction`, `aim_direction`, `attack_held`, `interact_held`, `ready_requested`) để sau này ý định có thể đến từ mạng.
- **Mọi sát thương đi qua `HealthComponent.apply_damage()`**, mọi thay đổi tài nguyên qua `Inventory`. Trạng thái chỉ đổi ở một nơi để sau này chỉ server được gọi.
- "Gọi xuống, signal lên": `Match` nối hệ thống; hệ con không tìm nhau bằng đường dẫn toàn cục. Chưa dùng autoload.
- Người chơi được nhận diện kiểu duck typing (`is_alive`, `inventory`, `input`), quái không phụ thuộc trực tiếp vào `Warrior`.
- Tài nguyên/chi phí là dữ liệu dạng `{ &"wood": 3 }`. Thêm loại tài nguyên = thêm `.tres` + khai báo trong `ResourceTypes.ALL`.
- **Chữ người chơi thấy phải đi qua `tr()`** (game đa ngôn ngữ). Nhãn debug được viết cứng.
- Sinh node trong lúc đang ở callback vật lý (ví dụ khi có thứ chết) thì dùng deferred.
- Không xây hệ thống cho tính năng chưa được xác nhận.

Điểm gắn asset (thay placeholder không cần sửa code):
- Biểu tượng tài nguyên trên HUD: gán `icon` trong `resources/types/*.tres`; không có thì vẽ ô màu.
- Ảnh minh họa thẻ vũ khí: gán `art` (Texture2D) trong `combat/upgrades/*.tres`; thẻ tự thay ô placeholder.
- Khung thẻ: thả ảnh 9-slice vào `ui/art/card_frame.png` (viền không giãn 24 px, xem `UiStyle.CARD_FRAME_SLICE`).
- Bố cục HUD / màn kết quả / thẻ: sửa `ui/hud.tscn`, `ui/result_screen.tscn`, `ui/weapon_card.tscn` trong editor. Màu/style chung: `ui/ui_style.gd`.
- Khi thêm UI mới: tách thành scene riêng và chừa chỗ cho ảnh như trên.

Collision layer:

| Bit | Giá trị | Dùng cho |
|---|---|---|
| 1 | 1 | world (nền, tường, pháo đài, cây/đá) |
| 2 | 2 | thân người chơi |
| 3 | 4 | hurtbox quái |
| 4 | 8 | hurtbox pháo đài |
| 5 | 16 | hurtbox người chơi |
| 6 | 32 | thân quái |
| 7 | 64 | hurtbox tài nguyên |

## Gameplay đã chốt

- Người chơi là **chiến binh đi bộ** bảo vệ **pháo đài tự di chuyển** (không lái). Tham khảo *Monsters Are Coming! Rock & Road*.
- Đánh **chủ động**: click chuột / J / RT, **ngắm theo con trỏ** (twin-stick; tay cầm ngắm bằng stick phải).
- Pháo đài chạy liên tục, **hư càng nhiều càng chậm**. Thỉnh thoảng dẫm **bom ẩn** (ít). Có **điểm dừng nâng cấp**: vùng an toàn, không quái, khởi hành khi người chơi sẵn sàng.
- **Quái di chuyển, đánh cả người chơi lẫn pháo đài.**
- Tài nguyên: **Gỗ** (chặt cây → sửa thành), **Đá** (đập đá → nâng cấp pháo đài), **Đồng** (quái rơi → nâng cấp vũ khí). Mang về pháo đài; ý đồ là người chơi chia việc giữ thành / đi kiếm.
- Nâng cấp vũ khí: **ở điểm dừng, chọn 1 trong 3 thẻ**, trả bằng Đồng.
- Chiến binh ngã thì hồi sinh nhưng **rơi hết đồ đang mang**. Thua khi pháo đài bị phá.
- Pháo đài không chỉ bằng gỗ. Nâng cấp ở điểm dừng theo 2 trục: **thân pháo đài lên cấp vật liệu** (gỗ → đá → …, tăng độ bền, đổi hình) + **ô quanh rìa gắn công trình tấn công** (tháp…). Prototype: 1 cấp gỗ → đá, 1 loại tháp tự bắn. Thẻ nâng cấp ngẫu nhiên có thể thêm khi làm endless.
- Có cả solo và multiplayer (kiến trúc sẵn sàng; chưa làm networking).
- Sau này: class nhân vật có chiêu riêng, dash; menu chọn ngôn ngữ lúc mới vào.
- **Giao diện phải đẹp, có chất game** (thẻ, khung có style, hiệu ứng hover…), không dùng kiểu form mặc định (input, select box, nút xám trơn). Prototype được tạm, nhưng không làm UI kiểu form.
- Asset: placeholder cho tới hết prototype; khi làm asset thì viết tiêu chuẩn asset để người dùng đưa họa sĩ.

## Lộ trình prototype

0–7 đã xong: khung project → pháo đài + camera → di chuyển → máu/đánh → quái + spawner → tài nguyên/sửa/rơi đồ → điểm dừng nâng cấp (6a thân + tháp, 6b thẻ vũ khí, 6c bom ẩn) → vòng trận thắng/thua/chơi lại + HUD.
Tiếp theo: **8** đo hiệu năng trên M1 + chơi thử · **9** làm đẹp: ánh sáng/hậu kỳ, vật liệu stylized, nền đất, juice (rung camera, hit-stop, số sát thương), hiệu ứng hạt, font tiếng Việt (cần người dùng đồng ý tải font OFL).
