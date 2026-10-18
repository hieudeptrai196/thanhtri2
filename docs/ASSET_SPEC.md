# THÀNH TRÌ — Tiêu chuẩn asset (BẢN NHÁP)

> Bản nháp 2026-10-18, để đưa họa sĩ / tìm người làm. Sẽ hoàn thiện ở **M3 B1** (xem `ROADMAP.md`).
> Ký hiệu: **[Chốt]** đã xác nhận · **[Đề xuất]** Claude đề xuất, chờ duyệt · **[Mở]** chưa quyết.
> Tên quái, boss, biome… chưa chốt — danh sách dưới đây là **khung** cho họa sĩ ước lượng khối lượng, không phải nội dung cuối.

## 1. Tóm tắt cho họa sĩ

- Game hành động roguelite **3D góc nhìn isometric** (camera nghiêng từ trên xuống), cảm hứng **dân gian Việt Nam**. **[Chốt]**
- Người chơi là **chiến binh đi bộ** hộ tống một **pháo đài tự di chuyển** trên con đường vô tận; co-op tối đa 5 người, mỗi người một vai trò (class). **[Chốt]**
- Phát hành **Steam (PC) trước**, sau đó Google Play + App Store → asset phải chạy được cả trên điện thoại. **[Chốt]**
- Nền tảng: dùng bộ **KayKit + Kenney (CC0)** cho phần chung (cây, đá, đạo cụ…); **phần mang bản sắc Việt** (nhân vật, pháo đài, quái, kiến trúc, trang phục) do họa sĩ làm. **[Chốt]**
- Engine: **Godot 4.7**, renderer Forward+ trên PC, Mobile trên điện thoại.

## 2. Phong cách

- **[Đề xuất]** **Stylized low-poly**, tỉ lệ hơi "chibi" (đầu to vừa phải) để đọc rõ ở góc nhìn xa, hợp với KayKit để trộn được với asset nền.
- **[Đề xuất]** Màu phẳng / gradient nhẹ, ít chi tiết nhỏ; hình khối phải **đọc được từ trên cao** (camera nhìn xuống ~35°, khoảng cách xa).
- **[Đề xuất]** Chất Việt qua hình khối và họa tiết: mái cong, ngói, tre, gỗ lim, đồng (trống đồng), nón lá, áo giáp thời Lý–Trần, hoa văn Đông Sơn. Tránh hoa văn trùng lặp với Trung Quốc / Nhật nếu không chủ ý.
- **[Mở]** Bảng màu chính cho từng biome (để M3 chốt cùng 1 biome mẫu).
- Mỗi **class** có **màu nhận diện** (người chơi phân biệt nhau trong co-op) — màu hiện tại trong game (placeholder) để tham khảo:

| Class | Vai trò | Màu tạm |
|---|---|---|
| Công binh | xây, sửa, vác 2 công trình | cam đồng |
| Tiều phu | khai thác Gỗ/Than | xanh lá |
| Võ tướng | đánh, giữ tuyến | đỏ |
| Thầy pháp | hồi máu, hỗ trợ công trình | tím |
| Thợ máy | quản lý Than, pháo đài | xám thép |

## 3. Thông số kỹ thuật chung

| Mục | Tiêu chuẩn |
|---|---|
| Định dạng 3D | **glTF 2.0 binary (`.glb`)**, mỗi asset một file |
| Hệ trục | **Y hướng lên**, mặt trước nhìn về **−Z**, gốc (pivot) **ở chân / tâm đáy** |
| Đơn vị | **1 unit = 1 mét**, áp scale trước khi xuất (scale = 1) |
| Texture | PNG; ưu tiên **1 atlas màu chung** (kiểu KayKit) hoặc ≤ 1 texture/asset; kích thước lũy thừa 2, **tối đa 1024²** (nhân vật chính có thể 2048² nếu cần) |
| Vật liệu | PBR đơn giản (albedo, tùy chọn roughness); **không** dùng shader riêng của phần mềm 3D |
| Animation | Gói trong `.glb`, tên clip tiếng Anh viết thường: `idle`, `run`, `attack`, … (danh sách ở mục 4) ; 30 fps |
| Rig | Nhân vật người dùng **chung một bộ xương** (để dùng lại animation giữa các class) **[Đề xuất]** |
| Đặt tên file | `snake_case` tiếng Anh, không dấu: `warrior_engineer.glb`, `enemy_basic.glb`, `fortress_wood.glb` |

**Ngân sách polygon (tam giác) [Đề xuất]** — trong trận có thể tới ~300 quái cùng lúc, và phải chạy trên điện thoại:

| Loại | Tam giác | Ghi chú |
|---|---|---|
| Chiến binh (class) | 3.000 – 6.000 | 5 người cùng màn hình |
| Quái thường | 800 – 1.500 | **nhiều nhất màn hình**, càng nhẹ càng tốt |
| Quái lớn / boss | 5.000 – 15.000 | ít, theo mốc |
| Pháo đài (mỗi cấp) | 8.000 – 20.000 | luôn ở giữa màn hình |
| Công trình (tháp, rào) | 1.000 – 3.000 | |
| Cây, mỏ, đạo cụ | 200 – 1.500 | dùng nhiều lần |

## 4. Kích thước & danh sách asset (theo game hiện tại)

Kích thước dưới đây là **vùng va chạm trong game** (model nên khớp để nhìn đúng với cách chơi):

### 4.1 Nhân vật — 5 class **[Chốt danh sách class]**

- Cao ~**1.8 m**, rộng ~1 m (thân capsule bán kính 0.5 m).
- Mỗi class 1 model (hoặc 1 thân chung + phụ kiện/trang phục riêng), màu nhận diện ở mục 2.
- Cần thể hiện **vũ khí / dụng cụ** theo vai trò: búa (Công binh), rìu (Tiều phu), đao/giáo (Võ tướng), gậy/bùa (Thầy pháp), cờ lê/ống bễ (Thợ máy) **[Đề xuất]**.
- Animation: `idle`, `run`, `run_carry` (vác công trình trên lưng), `attack` (chém tự động), `dash`, `hammer` (xây/sửa), `chop` (chặt/đào), `skill`, `downed` (gục nằm), `revive` (đỡ dậy / được đỡ), `death`.
- Phụ kiện: **công trình gấp gọn trên lưng** (~0.9 × 0.9 × 0.6 m).

### 4.2 Quái

- Quái thường: cao ~**1.6 m**, bán kính 0.5 m. Animation: `idle`, `run`, `attack`, `hit`, `death`.
- **[Mở]** Chủng loại quái theo truyền thuyết Việt (để M4 chốt tên). Cần khung ít nhất: 1 quái thường, 1 quái nhanh, 1 quái trâu, 1–2 boss.

### 4.3 Pháo đài (thành trì di động)

- Thân **10 × 5 × 10 m** (dài × cao × rộng), di chuyển dọc đường; đường rộng ~12 m.
- **Cấp vật liệu** (hiện có 2): **Gỗ → Đá** **[Chốt hướng]**; cấp sau **[Mở]**. Mỗi cấp 1 model (hoặc thay vỏ).
- **Module gắn lên thân** (hiện lên khi mua nâng cấp ở điểm dừng) **[Chốt]**:
  - Nỏ liên châu (trên nóc, xoay theo mục tiêu)
  - Dầu sôi (vạc / máng đổ)
  - Lò lửa đốt Than
  - Khiên tự hồi (hiệu ứng vòm sáng)
  - Nỏ thần (vũ khí tối thượng, bắn loạt quanh thành)
  - **[Sắp làm — M2.3b]** Ụ nỏ có người điều khiển (chỗ để người chơi đứng vào)
- Cần chỗ (socket) cố định cho từng module trên model thân.

### 4.4 Công trình ngoài thực địa

| Công trình | Kích thước | Trạng thái cần thể hiện |
|---|---|---|
| Tháp nỏ | cao ~2.4 m, bán kính ~0.8 m | **bản vẽ** (mờ / khung giàn), đang xây, hoàn thành, sắp hết năng lượng, **đòn cuối** (quá tải rồi nổ), gấp gọn |
| Rào gỗ | ~3 × 2 × 1 m | bản vẽ, hoàn thành, hư hỏng |

### 4.5 Tài nguyên & thế giới

- **Cây** (cho Gỗ): cao ~3–4 m, nhiều biến thể; có hiệu ứng rung khi bị chặt.
- **Mỏ than** (cho Than): khối đá có vỉa than.
- **Đống đồ rơi** (Gỗ / Than / Đồng): ~0.9 m, đọc được loại tài nguyên qua màu/hình.
- **Bom ẩn** dưới đường (chỉ thấy khi nổ) + hiệu ứng nổ.
- **Mốc điểm dừng** trên đường (cổng / cột mốc).
- Mặt đất + dải đường đất; **4 kiểu tuyến** cần đổi màu/đạo cụ: Rừng già, Mỏ than, Đồng bằng, Đền hoang.
- **[Mở — M4]** Biome theo vùng miền, sự kiện truyền thuyết.

### 4.6 Hiệu ứng (VFX) — có thể làm trong Godot

Vệt tên bắn, nhát chém, nổ (bom, tháp, Nỏ thần), vùng Bùa trận (vòng tròn trên đất), xung Hét trận / Dựng tốc, khiên, hồi máu, chớp trắng khi trúng đòn.

## 5. UI & icon

Game đã có **chỗ gắn sẵn** — thả file đúng tên/đúng chỗ là thay được placeholder, không cần sửa code:

| Asset | Chỗ đặt | Tiêu chuẩn |
|---|---|---|
| Icon tài nguyên (Gỗ, Than, Đồng) | gán `icon` trong `resources/types/*.tres` | PNG nền trong suốt, **128 × 128** **[Đề xuất]** |
| Ảnh minh họa thẻ vũ khí | gán `art` trong `combat/upgrades/*.tres` | PNG ~**320 × 200** **[Đề xuất]** |
| Khung thẻ | `ui/art/card_frame.png` | **9-slice**, viền không giãn **24 px** |
| Chân dung class (thẻ chọn vai trò) | trường `art` trong `classes/types/*.tres` (đã có, **thẻ chưa hiển thị** — nối ở M3) | PNG ~**256 × 256** **[Đề xuất]** |
| Ảnh tuyến đường (thẻ chọn tuyến) | **[Mở]** (`RouteType.art` để sau) | |

Yêu cầu chung cho UI **[Chốt]**: có chất game (khung, thẻ, nút có style, hover), **không** dùng kiểu form mặc định.
**[Đề xuất]**: phong cách gỗ – đồng – giấy dó, hợp màu UI hiện tại (gỗ nâu, đồng vàng, chữ màu giấy).

Cần thêm (chưa có chỗ gắn, làm ở M3):
- **Font tiếng Việt** có chất game (đủ dấu, hỗ trợ cả tiếng Anh; ngôn ngữ CJK sau này cần font dự phòng).
- Logo "THÀNH TRÌ", màn bắt đầu, nền phòng chờ.
- Icon kỹ năng 5 class, icon nâng cấp pháo đài, icon trạng thái (gục, hồi sinh, tăng tốc, hết Than…).
- Biểu tượng ping (M2.3c): "cần Gỗ", "quái hướng này", "thu tháp này".

**Kích thước màn hình phải hỗ trợ**: tối thiểu 1280 × 720, PC 1920 × 1080 trở lên, điện thoại (tỉ lệ dài, vùng tai thỏ). Chữ tiếng Anh dài hơn tiếng Việt → khung chữ phải co giãn.

## 6. Âm thanh (sơ bộ, M3)

- **[Đề xuất]** Nhạc nền mang chất dân tộc (trống đồng, sáo trúc, đàn bầu) pha nhịp hành động; 1 bài trận + 1 bài điểm dừng + 1 bài menu.
- SFX: chém, bắn nỏ, nổ, xây/gõ búa, chặt cây, đào than, nhặt đồ, pháo đài chạy / tăng tốc, quái kêu, gục / được đỡ, kỹ năng 5 class, UI (hover, bấm, mua).
- Định dạng: `.ogg` (nhạc), `.wav` (SFX ngắn).

## 7. Giấy phép & bàn giao

- Asset phải là **tự làm hoặc CC0 / giấy phép cho phép thương mại**; ghi nguồn từng asset bên thứ ba vào `CREDITS.md`.
- Không dùng asset của game tham khảo (Marcha de Ferro) hay asset có bản quyền khác.
- Bàn giao: file nguồn (Blender `.blend` hoặc tương đương) + file xuất `.glb` / `.png`, đặt tên theo mục 3.
- Trước khi làm hàng loạt: làm **1 class + 1 quái + pháo đài cấp Gỗ** để thử trong game (đọc rõ ở góc camera, hiệu năng với ~300 quái), duyệt xong mới làm tiếp.

## 8. Còn mở (cần chốt trước khi giao việc)

- Phong cách cuối (stylized low-poly như đề xuất, hay khác?) và bảng màu.
- Tên + hình dáng các loại quái, boss, biome theo vùng miền (M4).
- Các cấp pháo đài sau Đá.
- Mức độ chi tiết nhân vật (1 model chung + phụ kiện, hay 5 model riêng).
- Ngân sách / số người làm asset.
