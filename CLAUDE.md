# THÀNH TRÌ

Game roguelite hành động 3D isometric, cảm hứng dân gian Việt Nam. Godot **4.7.2**, **GDScript**, Forward Plus, Jolt Physics. Máy dev: MacBook Pro M1 (macOS). Trả lời người dùng bằng **tiếng Việt**.

## Cách làm việc (bắt buộc)

- Làm theo **từng giai đoạn nhỏ**, mỗi giai đoạn kiểm thử độc lập được. Xong một giai đoạn thì báo kết quả và **chờ người dùng duyệt** rồi mới commit / làm tiếp.
- Luôn phân biệt **[Chốt]** (người dùng đã xác nhận), **[Đề xuất]** và **[Mở]**. Không tự chốt nội dung gameplay: tên quái, vũ khí, kỹ năng, nâng cấp, điều kiện thắng, lộ trình…
- Cần quyết định thì hỏi **một câu quan trọng nhất** trước, kèm phương án đề xuất.
- Không cam kết hiệu năng khi chưa đo trên M1.
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
- Bẫy hay gặp khi viết test: dịch chuyển chiến binh ra khỏi vùng quanh pháo đài rồi `await frames(2)` trước khi nhét đồ vào túi, nếu không `ServiceZone` sẽ nộp mất.
- Kiểm tra cú pháp nhanh: `Godot --headless --path . --quit`.

## Kiến trúc

| Thư mục | Nội dung |
|---|---|
| `match/` | `match.gd` (gốc một trận: nối mọi hệ thống, giữ RNG theo seed, luồng dừng/khởi hành/hồi sinh), `spawner.gd` |
| `fortress/` | `Fortress` (máu → tốc độ, kho, sửa), `RouteFollower` (chạy theo `Path3D`, dừng tại `Marker3D`), `ServiceZone` (nộp đồ, giữ interact để sửa) |
| `player/` | `Warrior`, `PlayerInput` |
| `combat/` | `HealthComponent`, `Hurtbox`, `MeleeWeapon`, bia thử |
| `enemies/` | `Enemy` |
| `resources/` | `ResourceType` (.tres trong `types/`), `ResourceTypes.ALL`, `Inventory`, `ResourceNode` (cây/đá), `Pickup` |
| `camera/`, `world/` | Camera isometric orthographic, shader nền |
| `tests/` | Test harness |

Nguyên tắc:
- **Chỉ `PlayerInput` được đọc `Input`.** Gameplay đọc ý định (`move_direction`, `aim_direction`, `attack_held`, `interact_held`, `ready_requested`) để sau này ý định có thể đến từ mạng.
- **Mọi sát thương đi qua `HealthComponent.apply_damage()`**, mọi thay đổi tài nguyên qua `Inventory`. Trạng thái chỉ đổi ở một nơi để sau này chỉ server được gọi.
- "Gọi xuống, signal lên": `Match` nối hệ thống; hệ con không tìm nhau bằng đường dẫn toàn cục. Chưa dùng autoload.
- Người chơi được nhận diện kiểu duck typing (`is_alive`, `inventory`, `input`), quái không phụ thuộc trực tiếp vào `Warrior`.
- Tài nguyên/chi phí là dữ liệu dạng `{ &"wood": 3 }`. Thêm loại tài nguyên = thêm `.tres` + khai báo trong `ResourceTypes.ALL`.
- **Chữ người chơi thấy phải đi qua `tr()`** (game đa ngôn ngữ). Nhãn debug được viết cứng.
- Sinh node trong lúc đang ở callback vật lý (ví dụ khi có thứ chết) thì dùng deferred.
- Không xây hệ thống cho tính năng chưa được xác nhận.

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
- Chiến binh ngã thì hồi sinh nhưng **rơi hết đồ đang mang**. Thua khi pháo đài bị phá.
- Pháo đài không chỉ bằng gỗ: nâng cấp bằng nhiều vật liệu (chi tiết chưa chốt).
- Có cả solo và multiplayer (kiến trúc sẵn sàng; chưa làm networking).
- Sau này: class nhân vật có chiêu riêng, dash; menu chọn ngôn ngữ lúc mới vào.
- Asset: placeholder cho tới hết prototype; khi làm asset thì viết tiêu chuẩn asset để người dùng đưa họa sĩ.

## Lộ trình prototype

0–5 đã xong: khung project → pháo đài + camera → di chuyển → máu/đánh → quái + spawner → tài nguyên/sửa/rơi đồ.
Tiếp theo: **6** điểm dừng nâng cấp (pháo đài + vũ khí) + bom ẩn · **7** vòng trận thắng/thua + HUD (bỏ phím debug K) · **8** đo hiệu năng trên M1 + chơi thử.
