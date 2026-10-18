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
- Harness dùng file lưu riêng (`user://thanhtri_test_save.cfg`), xóa sau mỗi test, và xóa trận đang xếp hàng (`Match._queued_mode`). Nút ở màn bắt đầu / kết quả gọi `reload_current_scene()` → trong test phải ngắt kết nối handler của Match trước khi bấm.
- `start_match()` làm trống kho pháo đài (trừ khi `keep_starting_resources`), vì kho bắt đầu có 30 Gỗ.
- Khi có kết quả trận, cây scene bị tạm dừng; `GameTest.cleanup()` tự bỏ tạm dừng. Nút Chơi lại gọi `reload_current_scene()`, harness không có current scene nên test phải ngắt `m.restart` trước khi bấm.
- Bố trí đường ngẫu nhiên có thể đặt bom ngay đoạn đầu: test nhạy với máu/tiếng ồn của thành thì gọi `clear_random_bombs(m)` hoặc `fortress.health.reset()`. Đưa thành tới điểm dừng bằng `base_speed = 300` xong thì nhớ đặt lại 0 nếu còn chờ lâu (không thì tới điểm dừng kế và quái bị dọn).
- Runner: file test không nạp được → FAIL; test chạy quá 7200 frame → FAIL "timed out". Test cần vật thể cố định thì tự đặt (`spawn_resource`, `RouteContent.place_bomb`) thay vì dựa vào bố trí ngẫu nhiên.
- Bẫy hay gặp khi viết test: dịch chuyển chiến binh ra khỏi vùng quanh pháo đài rồi `await frames(2)` trước khi nhét đồ vào túi, nếu không `ServiceZone` sẽ nộp mất.
- Co-op: `start_net_match(clients, seed, port, wait_for_start)` dựng host + client, mỗi máy một `SubViewport` (thế giới 3D riêng) với `MultiplayerAPI` riêng, ENet thật qua localhost; chờ bằng `wait_until(callable, max_frames)`. `Input` dùng chung: bấm phím sẽ điều khiển cả host lẫn client. Luồng thật (phòng chờ → nạp lại scene) thử bằng `tools/net_smoke.sh`.
- Kiểm tra cú pháp nhanh: `Godot --headless --path . --quit`.

## Đa ngôn ngữ (i18n)

- **Tiếng Việt là ngôn ngữ gốc** (msgid). Bản dịch: gettext `locale/*.po` (hiện có `en.po`); fallback locale = `vi` trong `project.godot`.
- Sau khi thêm/sửa chữ: chạy `python3 -I tools/extract_strings.py` → cập nhật `locale/messages.pot` + mọi `.po`, in ra chuỗi còn thiếu. Dịch phần thiếu trong `en.po`. `tests/test_i18n.gd` hỏng nếu còn chuỗi chưa dịch.
- Công cụ lấy: `tr("...")` trong `.gd`, chuỗi trên dòng có `# i18n` (vd hằng mảng tên), `display_name` / `description` trong `.tres`.
- **Không ghép câu** từ mảnh (vd "Giữ F để %s %s" với động từ chèn vào): viết câu trọn cho từng trường hợp để người dịch tự sắp trật tự từ.
- `Locales` (`locale/locales.gd`): ngôn ngữ hỗ trợ + lựa chọn (lưu trong SaveManager); autoload `LocaleBoot` áp dụng trước khi scene dựng chữ. Lần đầu mở game: màn bắt đầu chỉ hiện chọn ngôn ngữ. Tên ngôn ngữ tự gọi mình, không dịch.
- Thêm ngôn ngữ mới: tạo `locale/<mã>.po` (chạy công cụ trích để điền msgid), thêm vào `locale/translations` trong `project.godot` (tắt Godot trước) và `Locales.SUPPORTED`. Ngôn ngữ CJK cần font dự phòng.
- Chữ tiếng Anh dài hơn: khi thêm UI phải chụp lại bằng cả hai ngôn ngữ ở 1280×720.
- Harness luôn đặt locale `vi`.

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
| `match/` | `NetSync` (chỉ có khi online — xem mục Mạng co-op), `NoiseMeter` (tiếng ồn 0–100, mức, truy đuổi; nguồn ồn gọi qua group `"noise"`), `Difficulty`, `match.gd` (gốc một trận: nối mọi hệ thống, giữ RNG theo seed, luồng dừng/khởi hành/hồi sinh, thua → tạm dừng cây + màn kết quả + lưu kỷ lục; **chế độ** RANDOM / DAILY (seed từ ngày, `Match.queue_run` mang lựa chọn qua lần nạp lại scene); `wait_for_start` — `main.tscn` bật để hiện màn bắt đầu, test tắt), `spawner.gd` |
| `fortress/` | `Fortress` (máu → tốc độ, kho + tài nguyên ban đầu, sửa, cấp vật liệu, **nỏ liên châu** `$Crossbow`, **chông gai** `thorns_damage`, nhiên liệu Than + tăng tốc, **Nỏ thần** `DivineCrossbow` (nạp bằng hạ quái/nộp đồ/xây xong, G / RB), **nâng cấp** `FortressUpgrade` (.tres trong `upgrades/`: crossbow, boiling_oil, furnace, shield — giá trộn theo cấp) + module placeholder trên thân), `RouteFollower` (chạy theo `EndlessRoute`, `distance` = tổng mét = điểm), `ServiceZone` (nộp đồ, giữ interact để sửa), `Tower` |
| `player/` | `Warrior` (tự đánh, dash, vác 1 công trình), `PlayerInput` (ý định), `Builder` (chế độ xây cục bộ: phím 1–4 / menu vòng tròn, bóng ma, giữ F thu hồi) |
| `structures/` | `StructureType` (.tres trong `types/`) + `StructureTypes.ALL`, `Structure` (máu, bộ đệm, tiếp sức), `CrossbowTurret` (bắn, đòn cuối, nổ), rào gỗ (`Structure` không cần điện, hút quái), `StructureNetwork` (chứa công trình ở tọa độ thế giới, luật đặt, tiếp sức trong bán kính pháo đài, bản vẽ, dỡ/thu hồi). `Structure` bắt đầu là **bản vẽ**: `add_hammer` mỗi tick, trả dần (túi rồi kho), `add_recover_helper` cộng tiến độ thu hồi chung |
| `combat/` | `HealthComponent`, `Hurtbox`, `MeleeWeapon`, `AutoShooter` (tự bắn mục tiêu gần nhất — dùng cho tháp nỏ và nỏ liên châu trên thành), bia thử |
| `enemies/` | `Enemy` |
| `resources/` | `ResourceType` (.tres trong `types/`: wood, coal, bronze), `ResourceTypes.ALL`, `Inventory`, `ResourceNode` (cây, mỏ than), `Pickup` |
| `world/` | `EndlessRoute` (đường vô tận theo đoạn, RNG riêng theo seed, địa chỉ bằng quãng đường tuyệt đối), `RouteContent` (dải đường, cây/mỏ than/bom/vòng điểm dừng theo đoạn, dọn phía sau; **hoãn** nội dung sau điểm dừng tới khi chọn tuyến — `set_content_limit`), `RouteType` (.tres trong `routes/`: rừng già, mỏ than, đồng bằng, đền hoang — hệ số cây/than/bom/quái/rơi đồ + màu đất) + `RouteTypes.draw`, `ground_follow.gd`, `HiddenBomb`, shader nền |
| `net/` | `Net` (tĩnh: `host`/`join`/`leave`/`is_online`/`lan_addresses`, ENet cổng 24690, tối đa 4 người; nhận `MultiplayerAPI` bất kỳ để test chạy host + client trong một process) |
| `camera/` | Camera isometric orthographic |
| `ui/` | `UiStyle` (style chung), `Hud` (HUD trong trận), `ResultScreen`, `UpgradePanel` (bảng ở điểm dừng), `WeaponCard`, `ResourceCounter`, `RouteProgress` |
| `locale/` | `Locales`, `locale_boot.gd` (autoload), `messages.pot`, `en.po` |
| `save/` | `SaveManager` (tĩnh; ConfigFile có phiên bản ở `user://thanhtri_save.cfg`: kỷ lục chung, kỷ lục từng ngày, số trận, cài đặt) |
| `tests/` | Test harness |
| `tools/` | `benchmark.sh`, `extract_strings.py`, `net_smoke.sh` (host + client thật, 2 tiến trình) — không thuộc bản build |

Nguyên tắc:
- **Chỉ `PlayerInput` được đọc `Input`.** Gameplay đọc ý định (`move_direction`, `aim_direction`, `attack_held`, `interact_held`, `ready_requested`) để sau này ý định có thể đến từ mạng.
- **Mọi sát thương đi qua `HealthComponent.apply_damage()`**, mọi thay đổi tài nguyên qua `Inventory`. Trạng thái chỉ đổi ở một nơi để sau này chỉ server được gọi.
- "Gọi xuống, signal lên": `Match` nối hệ thống; hệ con không tìm nhau bằng đường dẫn toàn cục. Chưa dùng autoload.
- **Quyền đặt / thu hồi công trình ở `Match.request_place` / `request_recover`** (sau này chạy trên server); `Builder` chỉ phát ý định. Công trình là con của `StructureNetwork`, không bao giờ là con của pháo đài.
- Người chơi được nhận diện kiểu duck typing (`is_alive`, `inventory`, `input`), quái không phụ thuộc trực tiếp vào `Warrior`.
- **Tất định theo seed:** đường + nội dung dùng RNG riêng sinh từ `run_seed` (`Match._seeded_rng`), không dùng chung RNG gameplay — cần cho seed hằng ngày.
- Tài nguyên/chi phí là dữ liệu dạng `{ &"wood": 3, &"coal": 1 }`. Thêm loại tài nguyên = thêm `.tres` + khai báo trong `ResourceTypes.ALL`.
- **Chữ người chơi thấy phải đi qua `tr()`** (game đa ngôn ngữ). Nhãn debug được viết cứng.
- Sinh node trong lúc đang ở callback vật lý (ví dụ khi có thứ chết) thì dùng deferred.
- Không xây hệ thống cho tính năng chưa được xác nhận.

Mạng co-op (M2.1, host-authoritative):
- Solo = máy chủ không ai vào, cùng một đường code. `multiplayer.is_server()` đúng khi offline. `Match._is_host()` chặn mọi `request_*`; `HealthComponent.apply_damage`, bom, búa/thu hồi trong `Builder` cũng chỉ chạy trên host.
- `$Warrior` của scene luôn là của host (peer 1); người khác là `Warrior_<id>` (con của Match, `Match.spawn_player`). `Warrior.peer_id`, `local_warrior` = chiến binh của máy này (camera + HUD theo nó). `Match.players` mọi chiến binh.
- Client → host: `NetSync.client_input` mỗi tick (unreliable, `PlayerInput.export_state`) + `client_events` (reliable, sự kiện một lần + input tick đó; host lọc bằng `_clean_state` / `ALLOWED_EVENTS`). Host → client: `server_snapshot` 20 Hz (`Match.net_snapshot`: thành, tiếng ồn, tuyến, chiến binh), `begin_run(seed)`, `run_finished`.
- Client không mô phỏng: tắt physics của Spawner/Structures/NoiseMeter/Fortress/ServiceZone/nỏ trên thành; chiến binh `set_simulated(false)` và trượt mượt tới vị trí host gửi. `RouteFollower` client vẫn chạy (dự đoán) và bị snapshot sửa. Đường + nội dung sinh từ seed chung, không gửi.
- Phòng chờ ở màn bắt đầu (Chơi cùng bạn bè → Tạo phòng / Vào phòng bằng IP → host bấm Bắt đầu). Bắt đầu = mọi máy `reload_current_scene` với `Match._queued_seed`; client báo `client_ready` sau khi nạp xong thì host mới tạo chiến binh và gửi snapshot. Vào giữa trận: host gửi `begin_run` riêng cho người mới.
- Thêm trạng thái cần đồng bộ: thêm vào `net_state()`/`apply_net_state()` của hệ đó (đổi trên client phải phát lại signal để HUD cập nhật) + `Match.net_snapshot`. Không gửi Resource/Object qua mạng — gửi id/chỉ số (`StructureTypes.ALL.find`, `RouteTypes.ALL.find`).
- Chưa đồng bộ (M2.1b–d): quái, công trình, nhặt đồ / cây-than bị khai thác, bảng điểm dừng + chọn tuyến trên client. Chưa có dự đoán cho chiến binh của client (trễ 1 RTT, ổn trong LAN).

Điểm gắn asset (thay placeholder không cần sửa code):
- Biểu tượng tài nguyên trên HUD: gán `icon` trong `resources/types/*.tres`; không có thì vẽ ô màu.
- Ảnh minh họa thẻ vũ khí: gán `art` (Texture2D) trong `combat/upgrades/*.tres`; thẻ tự thay ô placeholder.
- Khung thẻ: thả ảnh 9-slice vào `ui/art/card_frame.png` (viền không giãn 24 px, xem `UiStyle.CARD_FRAME_SLICE`).
- Bảng ở điểm dừng chia 2 cột (pháo đài | thẻ vũ khí) để vừa 720p — khi thêm mục mới phải kiểm tra lại bằng ảnh chụp 1280×720.
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
| 8 | 128 | hurtbox công trình (quái đánh được) |

## Gameplay đã chốt

- **Game tham khảo: Marcha de Ferro** (xem `docs/REFERENCE.md`) + co-op + tính năng riêng của người dùng. Học nguyên tắc, không chép nguyên văn.
- **[2026-10-18] Vòng chính: đặt công trình (tháp, chướng ngại…) ngoài thực địa phía trước pháo đài, công trình được tiếp sức khi ở gần pháo đài, thu về mang lên trước ("nhảy cóc") hoặc bỏ lại kèm đòn cuối.** Chi tiết (mang theo, bộ đệm, loại công trình, tháp gắn pháo đài cũ) đang chốt dần. **Điều khiển xây:** PC = phím 1–4 chọn, bóng ma theo con trỏ (xanh/vàng/đỏ), click trái đặt, chuột phải hủy; tay cầm = giữ LB mở menu vòng tròn, stick phải chọn/đẩy bóng ma, A đặt, B hủy. **Không làm chậm thời gian** (vì co-op). **Xây chung [2026-10-18]:** đặt bản vẽ miễn phí → cả đội giữ E gõ (nhiều người nhanh hơn), Gỗ trả dần từ túi người gõ rồi kho; thu hồi chung nhanh hơn. Đa vật liệu / gia cố / liên kết công trình để M2.
- Người chơi là **chiến binh đi bộ** bảo vệ **pháo đài tự di chuyển** (không lái). Tham khảo *Monsters Are Coming! Rock & Road*.
- **[2026-10-18] Đòn thường tự đánh** (chuột / stick phải chỉ ưu tiên hướng mục tiêu); **kỹ năng class bấm chủ động và ngắm** (dùng lại phần ngắm/quạt chém hiện có). Tháp/công trình là lực sát thương chính. **Dash**: Shift / B. Đã làm ở M1.3 (`MeleeWeapon.pick_target`, `Warrior._auto_attack`).
- Pháo đài chạy liên tục, **hư càng nhiều càng chậm**. Thỉnh thoảng dẫm **bom ẩn** (ít). Có **điểm dừng nâng cấp**: vùng an toàn, không quái, khởi hành khi người chơi sẵn sàng.
- **Quái di chuyển, đánh cả người chơi lẫn pháo đài.**
- **[2026-10-18] Pháo đài tự phòng thủ được (khác spec Marcha de Ferro).** Nguyên tắc: thành chỉ xử lý quái **lọt sát thân**; chặn cả đợt vẫn là việc của công trình ngoài thực địa + người chơi. Gồm cả 6 cơ chế: (1) **nỏ liên châu** tự bắn yếu, tầm ngắn, có sẵn; (2) **Nỏ thần** — thanh năng lượng đầy dần khi đội hạ quái/nộp đồ/xây, một người kích hoạt loạt tên quét quanh thành; (3) **chông gai** phản sát thương → nâng cấp **dầu sôi** tự dội khi thành mất nhiều máu; (4) module **lò lửa đốt Than**; (5) **ụ nỏ có người điều khiển** (co-op: người đứng vào ngắm bắn mạnh, không ai thì tự bắn yếu); (6) **khiên tự hồi**. Module hiện lên trên thân thành. **Vũ khí của thành nằm trong nâng cấp của thành (ở điểm dừng), trả bằng nguyên liệu kiếm được** — giá trộn Gỗ/Than/Đồng theo từng nâng cấp (vd nâng nỏ: Gỗ + Đồng; lò lửa: Đồng + Than; khiên: Đồng) [số liệu: Đề xuất].
- **[2026-10-18] Endless + chọn 1 trong 2 tuyến ở mỗi điểm dừng** (mỗi tuyến có thưởng/rủi ro, vd rừng già: nhiều Gỗ + đông quái; mỏ than: nhiều Than + đường hẹp; đền hoang: chắc có module + ít tài nguyên). Tuyến sinh theo seed (seed hằng ngày vẫn công bằng). Chế độ Hành trình có cổng cuối: để sau phát hành nếu cần.
- **[2026-10-18] Độ khó = quãng đường (nền, `Difficulty`) + tiếng ồn** (tăng theo thời gian và việc ồn: tăng tốc, chặt cây, bắn…; đầy thanh → truy đuổi, quái dồn từ phía sau; điểm dừng làm dịu).
- **[2026-10-18] Tài nguyên mới (3 loại):** **Gỗ** = xây công trình + sửa thành; **Than** (mới) = nhiên liệu pháo đài (đủ than chạy thường, **tăng tốc** tốn than + kéo thêm quái, hết than bò chậm); **Đồng** = vũ khí, kỹ năng, góp phần vào nâng cấp pháo đài (cùng Gỗ/Than). **Bỏ Đá**. Đã làm ở M1.6a: Than từ **mỏ than** dọc đường; thành tiêu 0.125 Than/s, **tăng tốc** (T / D-pad lên) ×1.6 tốc độ, 0.6 Than/s; hết Than chạy 35%; kho bắt đầu 30 Gỗ + 15 Than. Mang về pháo đài; người chơi chia việc giữ thành / đi kiếm.
- Nâng cấp vũ khí: **ở điểm dừng, chọn 1 trong 3 thẻ**, trả bằng Đồng.
- Chiến binh ngã thì hồi sinh nhưng **rơi hết đồ đang mang**. Thua khi pháo đài bị phá.
- Pháo đài không chỉ bằng gỗ. Nâng cấp ở điểm dừng theo 2 trục: **thân pháo đài lên cấp vật liệu** (gỗ → đá → …, tăng độ bền, đổi hình) + **ô quanh rìa gắn công trình tấn công** (tháp…). Prototype: 1 cấp gỗ → đá, 1 loại tháp tự bắn. Thẻ nâng cấp ngẫu nhiên có thể thêm khi làm endless.
- **Co-op tối đa 4 người, chia vai trò rõ (class = vai trò)**; solo vẫn trọn vẹn. Kiến trúc sẵn sàng; networking làm ở M2.
- Tính năng đã chọn (xem `docs/IDEAS.md`): class-vai trò, đỡ đồng đội, kết hợp class, ping, kho chung/túi riêng, độ khó theo số người, xếp hạng theo cỡ đội + bạn bè + seed ngày/tuần + mùa giải + chống gian lận, tổng kết MVP theo vai trò, thẻ hành trình, biome vùng miền, sự kiện truyền thuyết, boss; trang phục theo thời đại ưu tiên thấp.
- Sau này: class nhân vật có chiêu riêng, dash; menu chọn ngôn ngữ lúc mới vào.
- **Giao diện phải đẹp, có chất game** (thẻ, khung có style, hiệu ứng hover…), không dùng kiểu form mặc định (input, select box, nút xám trơn). Prototype được tạm, nhưng không làm UI kiểu form.
- Asset: placeholder cho tới hết prototype; khi làm asset thì viết tiêu chuẩn asset để người dùng đưa họa sĩ.

## Lộ trình

Xem [`docs/ROADMAP.md`](docs/ROADMAP.md) (M1 vòng cốt lõi → M2 co-op & vai trò → M3 vertical slice đẹp → M4 nội dung → M5 Steam beta → M6 phát hành → M7–M8 di động) và [`docs/PROGRESS.md`](docs/PROGRESS.md).
