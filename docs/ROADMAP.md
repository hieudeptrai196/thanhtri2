# THÀNH TRÌ — Roadmap

Cập nhật: 2026-10-18. Ký hiệu: **[Chốt]** đã xác nhận · **[Đề xuất]** chờ duyệt · **[Mở]** chưa quyết định.

## 1. Mục tiêu

- **[Chốt]** Game nghiêm túc, phát hành trên **Steam**, và tối thiểu **Google Play + App Store**.
- **[Chốt]** Chế độ chính: **endless**. Người chơi so xem **ai đi được xa hơn**.
- **[Chốt]** Model/asset làm tử tế (họa sĩ làm theo tài liệu tiêu chuẩn asset), giao diện có chất game.
- **[Chốt]** Đa ngôn ngữ (i18n) từ đầu; lần đầu vào game chọn ngôn ngữ.
- **[Chốt]** Solo + multiplayer (kiến trúc giữ đường; làm networking sau).
- **[Chốt]** **Làm xong bản PC (Steam) trước**, rồi mới port di động. Renderer: **Forward+ trên PC, Mobile trên điện thoại** (Godot đã tự chuyển: `rendering_method.mobile = mobile`).

## 2. Hiện trạng (prototype, giai đoạn 0–8 xong)

Pháo đài tự chạy theo lộ trình cố định (~250 m), chiến binh đánh chủ động ngắm theo chuột, 1 loại quái, Gỗ/Đá/Đồng,
sửa thành, rơi đồ khi ngã, điểm dừng nâng cấp (thân gỗ → đá, tháp, thẻ vũ khí), bom ẩn, thắng/thua/chơi lại, HUD.
Toàn bộ là hình khối placeholder. 39 test tự động (`tests/run.sh`), đo hiệu năng (`tools/benchmark.sh`).

## 3. Nguyên tắc cho bản phát hành

- Mỗi bước nhỏ, có test tự động + chơi thử; không bước nào làm hỏng bước trước.
- **Chữ người chơi thấy luôn qua `tr()`**; không ghép chuỗi kiểu phụ thuộc trật tự từ tiếng Việt.
- **Mọi input đi qua `PlayerInput`** để thêm cảm ứng / tay cầm mà không sửa gameplay.
- Ưu tiên PC, nhưng **không khóa đường di động**: input qua `PlayerInput`, chữ qua `tr()`, UI co giãn; hiệu ứng chỉ có ở Forward+ phải có phương án thay thế khi chạy Mobile (game vẫn đọc rõ, chỉ kém đẹp hơn).
- Asset thay được không cần sửa code (xem "Điểm gắn asset" trong `CLAUDE.md`).
- Không plugin / API key / tài khoản / deploy nếu chưa được duyệt riêng.

## 4. Các hạng mục

### A. Lối chơi endless (làm trước, vẫn placeholder)

| # | Nội dung | Xong khi |
|---|---|---|
| A1 | **Lộ trình vô tận**: sinh đường theo đoạn phía trước, xóa phía sau; cây/đá/bom sinh theo đoạn; bỏ tường cố định | Chạy 30 phút không hết đường, bộ nhớ & FPS ổn định (test + benchmark) |
| A2 | **Độ khó theo quãng đường**: mật độ/sức mạnh/loại quái tăng dần; điểm dừng mỗi X m | Có bảng/đồ thị độ khó theo mét; chơi thử thấy nhịp căng–nghỉ |
| A3 | **Điểm = quãng đường**: số mét trên HUD, kỷ lục lưu máy, màn kết quả so kỷ lục | "1.240 m — kỷ lục mới!" |
| A4 | **Nội dung**: 3–4 quái dân gian **[Mở: tên/cơ chế do người dùng chốt]**, quái tinh anh, **boss sau mỗi N điểm dừng**, thêm cấp vật liệu pháo đài, thêm loại tháp, thẻ pháo đài, **class nhân vật + chiêu riêng + dash**, biome đổi theo quãng đường | Mỗi trận khác nhau nhờ kết hợp thẻ/quái/biome |
| A5 | **Cân bằng + tối ưu** (vật lý quái là điểm nóng đã đo) | Đạt mục tiêu FPS trên thiết bị yếu nhất (xem C1) |
| A6 | **So quãng đường**: kỷ lục trên máy + **seed hằng ngày** (mọi người cùng lộ trình/quái trong ngày) → sau đó bảng xếp hạng nền tảng (C5) | So sánh công bằng giữa người chơi |

### B. Đồ họa & âm thanh

| # | Nội dung |
|---|---|
| B1 | **Hướng mỹ thuật + tài liệu tiêu chuẩn asset** (làm sớm nhất vì họa sĩ cần thời gian): phong cách, bảng màu; chiến binh theo class, quái, boss, **pháo đài dạng module theo cấp vật liệu**, bộ cảnh theo biome, props, UI kit (khung, nút, thẻ, icon), VFX; giới hạn polygon/texture **theo ngân sách di động**, danh sách animation, `.glb`, quy tắc đặt tên |
| B2 | **Làm đẹp bằng code** (giai đoạn 9): ánh sáng/hậu kỳ, shader stylized, nền đất + cây cỏ (MultiMesh), hạt, juice (rung camera, hit-stop, số sát thương), font tiếng Việt (OFL, cần duyệt tải), làm mờ pháo đài khi che nhân vật |
| B3 | **Lắp asset thật**: thay placeholder từng scene, AnimationTree, đo lại hiệu năng trên mọi nền tảng |
| B4 | **Âm thanh** [Đề xuất]: SFX (chém, nổ, chặt), nhạc theo biome, âm lượng trong cài đặt |

### C. Nền tảng & phát hành

| # | Nội dung |
|---|---|
| C1 | **Renderer & hiệu năng**: **[Chốt]** Forward+ trên PC, Mobile trên điện thoại. **[Mở]** cấu hình PC tối thiểu và mục tiêu FPS (đề xuất 60 FPS ở 1080p trên GPU tích hợp tầm trung); khi port: thiết bị di động yếu nhất + mục tiêu FPS, kiểm tra hình ảnh dưới renderer Mobile |
| C2 | **Điều khiển**: cảm ứng (joystick ảo trái di chuyển, joystick/vùng phải ngắm-đánh, nút dash/chiêu/E/sẵn sàng), tay cầm (đã có cơ bản), chuột-bàn phím; chỉ sửa `PlayerInput` + lớp UI cảm ứng |
| C3 | **i18n**: bật TranslationServer, file dịch (đề xuất gettext `.po` để giao cho người dịch; Godot sinh `.pot`), **màn chọn ngôn ngữ lần đầu**, tự nhận ngôn ngữ máy làm mặc định, đổi ngôn ngữ trong cài đặt, font dự phòng cho ngôn ngữ khác (CJK…), kiểm tra chữ dài không tràn khung. Bắt đầu: **Tiếng Việt + English** [Đề xuất], thêm ngôn ngữ sau |
| C4 | **Lưu game & cài đặt**: kỷ lục, tiến trình, ngôn ngữ, âm lượng, điều khiển (`user://`); cloud save theo nền tảng sau |
| C5 | **Dịch vụ nền tảng**: bảng xếp hạng + thành tựu qua **Steamworks**, **Google Play Games**, **Game Center** (đều cần plugin/SDK + tài khoản → duyệt riêng). Lớp trừu tượng `PlatformServices` để gameplay không phụ thuộc nền tảng |
| C6 | **UI đa màn hình**: co giãn theo tỉ lệ (16:9 → 20:9 điện thoại, notch/safe area), cỡ chữ & nút đủ lớn cho ngón tay |
| C7 | **Build & export**: preset cho macOS/Windows/Linux, Android (SDK, keystore), iOS (Xcode); loại `tests/` và `tools/` khỏi bản build; CI chạy `tests/run.sh` |
| C8 | **Yêu cầu store**: tài khoản (Apple Developer ~99 USD/năm, Google Play ~25 USD một lần, Steamworks ~100 USD/game) — **người dùng tự đăng ký**; chính sách quyền riêng tư, phân loại độ tuổi, ảnh/video store theo từng ngôn ngữ, mô tả bản địa hóa |
| C9 | **QA thiết bị**: danh sách máy test (Mac, Windows, Android tầm thấp/trung, iPhone đời cũ), TestFlight / Play internal testing / Steam Playtest |

### D. Multiplayer (sau khi bản solo ổn định)

Co-op online (host-authoritative), đồng bộ ý định từ `PlayerInput`, đếm sẵn sàng ở điểm dừng, chia kho; quyết định relay/NAT qua dịch vụ nền tảng (Steam Networking…) — duyệt riêng.

## 5. Cột mốc đề xuất

**Giai đoạn PC (Steam) — làm trước**

| Mốc | Gồm | Kết quả |
|---|---|---|
| **M1 — Endless chơi được** | A1, A2, A3, C3 (hạ tầng i18n + chọn ngôn ngữ), C4 (lưu kỷ lục + cài đặt) | Endless bằng placeholder trên PC |
| **M2 — Vertical slice PC** | B1, B2, 1 biome + batch asset đầu | 1 lát cắt "trông như game thật" |
| **M3 — Nội dung** | A4, B3, B4 | Đủ quái/boss/class/biome cho trải nghiệm dài |
| **M4 — Steam beta** | A5, A6, C5 (Steamworks), C7 (Windows/macOS/Linux), C8 (Steam), C9 (PC) | Steam Playtest |
| **M5 — Phát hành Steam** | Sửa lỗi beta, store listing đa ngôn ngữ | Lên Steam |

**Giai đoạn di động — sau khi PC xong**

| Mốc | Gồm | Kết quả |
|---|---|---|
| **M6 — Port di động** | C1 (Mobile renderer, thiết bị yếu nhất), C2 (cảm ứng), C6 (safe area, cỡ nút), tối ưu | Chơi tốt trên điện thoại thật |
| **M7 — Phát hành Google Play + App Store** | C5 (Google Play Games, Game Center), C7 (Android/iOS), C8, C9 (thiết bị) | Lên 2 store |

Song song từ M1: B1 (tài liệu cho họa sĩ) để asset kịp về ở M2–M3. Ngân sách asset vẫn tính tới di động để không phải làm lại khi port.

## 6. Quyết định đang mở

1. Cấu hình PC tối thiểu + mục tiêu FPS (di động chốt khi tới M6).
2. Nền tảng PC: Windows + macOS + Linux (Steam Deck)?
3. Phong cách mỹ thuật (B1).
4. Tên, cơ chế quái/boss/class; danh sách biome.
5. Ngôn ngữ ngoài Việt/Anh, thứ tự ưu tiên.
6. Mô hình kinh doanh (trả phí một lần / miễn phí + quảng cáo / mua trong game) — ảnh hưởng thiết kế và yêu cầu store.
7. Bảng xếp hạng: đề xuất kỷ lục máy + seed hằng ngày trước, rồi bảng xếp hạng nền tảng (C5).

## 7. Rủi ro

- **Hiệu năng di động**: cảnh nhiều quái + Forward+ có thể quá nặng; cần chốt renderer và ngân sách asset sớm.
- **Điều khiển cảm ứng** cho twin-stick hành động: cần chơi thử sớm trên điện thoại thật.
- **Che khuất** bởi pháo đài lớn ở góc isometric.
- **Gian lận bảng xếp hạng**: seed cố định giúp kiểm tra lại, nhưng bảng online vẫn cần chống gian lận.
- **Khối lượng asset** lớn (module pháo đài × cấp vật liệu, nhiều quái, biome) → cần ngân sách và lịch họa sĩ.
- Phụ thuộc plugin nền tảng (Steamworks, Google Play Games, Game Center) theo phiên bản Godot.
