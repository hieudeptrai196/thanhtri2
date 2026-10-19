# THÀNH TRÌ — Yêu cầu asset cho họa sĩ (v1)

> v1.1 — 2026-10-19 (M3 B1): người dùng đã chốt phong cách, pháo đài bánh xe, 5 model riêng, hướng quái, tiến độ nhanh nhất. Thay bản nháp 2026-10-18. Người dùng đưa tài liệu này cho họa sĩ; họa sĩ gửi file về, Claude ghép vào game.
> Ký hiệu: **[Chốt]** đã xác nhận · **[Đề xuất]** gợi ý, họa sĩ được điều chỉnh nếu có ý hay hơn · **[Mở]** còn để ngỏ.
> **"Họa sĩ" là AI tạo 3D từ chữ / ảnh** → prompt copy-paste từng asset ở [`ASSET_PROMPTS.md`](ASSET_PROMPTS.md) (sinh bằng `tools/art/build_prompts.py`). Tài liệu này là bản đầy đủ về phong cách / thông số.
> Mã asset (vd `CH-01`) dùng để trao đổi và đặt tên file. Ưu tiên: **Đ1** đợt thử nghiệm · **Đ2** đủ để chơi đẹp · **Đ3** sau.

---

## 1. Game là gì (đọc trong 1 phút)

- Roguelite hành động **3D, camera isometric** (nhìn chéo từ trên xuống, không phối cảnh), cảm hứng **dân gian / lịch sử Việt Nam**. **[Chốt]**
- Người chơi là **chiến binh đi bộ** hộ tống một **pháo đài tự di chuyển** trên con đường vô tận; quái kéo đến từ mọi phía. Người chơi chặt cây, đào than, xây tháp nỏ / rào gỗ ngoài thực địa, đem tài nguyên về pháo đài. Đi càng xa càng giỏi. **[Chốt]**
- **Co-op tối đa 5 người**, mỗi người một **vai trò (class)**: Công binh, Tiều phu, Võ tướng, Thầy pháp, Thợ máy. Solo vẫn chơi trọn vẹn. **[Chốt]**
- Phát hành **Steam (PC) trước**, sau đó **Google Play + App Store** → mọi asset phải nhẹ đủ để chạy trên điện thoại. **[Chốt]**
- Engine **Godot 4.7** (PC: Forward+, điện thoại: Mobile renderer). Ánh sáng, hậu kỳ, hiệu ứng hạt làm trong Godot — họa sĩ tập trung vào **model, texture, animation, hình vẽ 2D UI**.

Hiện game đang dùng khối hộp / viên nang làm tạm (placeholder). Mọi kích thước dưới đây lấy từ game đang chạy.

---

## 2. Phong cách

### 2.1 Hướng chung **[Chốt 2026-10-19]**

**Giống các game tham khảo — *Monsters Are Coming! Rock & Road* và *Marcha de Ferro* — nhưng không được đơn giản quá.**

- **Stylized 3D, khối "chunky"**: hình dáng to, chắc, cạnh vát rõ, tỉ lệ hơi phóng đại; nhìn vào là thấy nặng, có sức mạnh. Không làm kiểu khối hộp trơn như asset miễn phí.
- **Có chi tiết vừa phải**: vân gỗ, đinh tán, dây buộc, vết mòn, mép sứt, gạch đá xếp lớp — đủ để vật trông "có chất liệu" khi nhìn gần, nhưng **hình khối lớn vẫn đọc được từ xa** (mục 3). Chi tiết nằm trong **texture vẽ tay / gradient**, không phải polygon li ti.
- **Màu tươi, bão hòa vừa**, sáng sủa, tương phản rõ giữa người chơi / quái / nền.
- **Nhiều đạo cụ trang trí** cho thế giới sống động (cờ, đèn lồng, thùng, bao tải, tre, đá…).
- Người **hơi to đầu (khoảng 3–3.5 đầu)**, tay chân chắc, vũ khí / dụng cụ **to hơn thật ~20–30%**.
- **Bóng dáng (silhouette)**: mỗi class phải nhận ra được chỉ bằng bóng đen ở kích thước ~50 px.
- **Chất Việt** qua hình khối + họa tiết + bảng màu:
  - Kiến trúc: **mái cong đầu đao, ngói mũi hài, cột gỗ lim, tường thành Cổ Loa (đất nện / gạch), cổng tam quan, đình làng**.
  - Đồ đồng: **trống đồng Đông Sơn** (vòng tròn đồng tâm, ngôi sao giữa, chim Lạc), rìu xéo, mũi tên đồng.
  - Trang phục: **giáp thời Lý–Trần**, khăn chít / mũ trụ, nón lá, áo nâu, xà cạp.
  - Thiên nhiên: **tre, chuối, đa, sen, ruộng bậc thang, đá vôi** (biome sau).
- **Tránh**: họa tiết rồng / mây / mái kiểu Trung Quốc, Nhật (torii, giáp samurai) trừ khi có chủ ý; tránh hiện thực; tránh màu neon.
- Không sao chép asset hay thiết kế cụ thể của game tham khảo — chỉ học **mức độ chi tiết, độ chunky, độ tươi màu**.

### 2.2 Bảng màu **[Đề xuất]**

Tông chung: **ấm và tươi** (gỗ, đất nung, đồng, cỏ xanh), điểm nhấn bằng **màu nhận diện class** và **đồng vàng**. Họa sĩ được chỉnh độ tươi cho hợp phong cách ở 2.1.

| Nhóm | Màu (hex) | Dùng cho |
|---|---|---|
| Gỗ tối / gỗ / gỗ sáng | `#211710` `#3D2919` `#543B24` | khung UI, gỗ lim |
| Đồng / đồng sáng | `#DB9942` `#FFCC6B` | viền UI, đồ đồng, điểm nhấn |
| Giấy dó | `#F5E8CC` | chữ trên nền tối |
| Đất đường | `#8C6B47` | dải đường đất |
| Cỏ (Đồng bằng) | `#738C47` / `#69803F` | nền biome mẫu |
| Rừng già | `#335C29` / `#2B4F24` | nền rừng |
| Quái (thù địch) | đỏ sẫm / tím than + **mắt vàng phát sáng** | tách bạch với người chơi |

**Màu nhận diện class** (phải thấy rõ trên áo / khăn / cờ nhỏ sau lưng, để co-op phân biệt nhau) — màu hiện tại trong game:

| Class | Vai trò | Màu | Hex hiện tại |
|---|---|---|---|
| Công binh | xây nhanh, sửa thành, vác 2 công trình | cam đồng | `#D98C33` |
| Tiều phu | túi đồ gấp đôi, khai thác Gỗ / Than | xanh lá | `#59A64C` |
| Võ tướng | trâu, đánh mạnh, kéo quái | đỏ | `#CC3333` |
| Thầy pháp | bùa hồi máu, tăng sức công trình | tím | `#9959D9` |
| Thợ máy | lò than, pháo đài chạy nhanh | xám thép | `#73808C` |

---

## 3. Góc nhìn camera & độ rõ (quan trọng nhất cho họa sĩ)

| Thông số | Giá trị trong game |
|---|---|
| Kiểu camera | **Orthographic** (không phối cảnh — vật xa không nhỏ đi) |
| Góc | **nghiêng xuống 35°**, xoay **45°** quanh trục đứng (nhìn chéo góc) |
| Vùng nhìn | chiều cao màn hình ≈ **26 m** thế giới |
| 1 mét = | **~41 px** ở 1920×1080 · **~28 px** ở 1280×720 |
| Nhân vật cao 1.8 m trên màn hình | **~60–80 px** (1080p) · **~40–55 px** (720p) |
| Pháo đài 10 × 10 m | **~550–600 px** bề ngang (1080p) |

Hệ quả:
- **Mặt trên** (đầu, vai, mái, nóc) và **mặt chéo phía trước** là thứ người chơi nhìn thấy nhiều nhất; mặt đáy hầu như không thấy.
- Chi tiết nhỏ hơn **~0.15 m** (≈ 6 px) gần như biến mất — đừng đầu tư vào đó.
- Thứ cần đọc được trong 1 giây: **ai là ai (class)**, **đâu là quái**, **công trình nào**, **tài nguyên gì**.
- Có thể có tới **~300 quái + 5 người + 20 công trình** cùng màn hình.

> Kèm theo tài liệu: ảnh chụp game hiện tại (placeholder) ở 1280×720 để thấy đúng góc và tỉ lệ.

---

## 4. Thông số kỹ thuật

| Mục | Tiêu chuẩn |
|---|---|
| Định dạng 3D | **glTF 2.0 binary `.glb`**, mỗi asset một file (nhân vật: model + mọi animation trong cùng file) |
| Phần mềm | Tùy (Blender khuyến khích). Giao kèm **file nguồn** (`.blend` hoặc tương đương) |
| Hệ trục | Theo **chuẩn Blender**: Z lên, **mặt trước nhân vật / vật thể quay về −Y** (Front view). Xuất glTF mặc định (+Y up). Bên game tự xoay khi nhập. |
| Đơn vị | **1 unit = 1 mét**, **apply scale** trước khi xuất (scale = 1, rotation = 0) |
| Gốc (pivot) | **Giữa đáy** (tâm chân / tâm móng), đặt ở (0, 0, 0) |
| Texture | PNG, **vẽ tay / gradient có chi tiết** (mục 2.1). Kích thước lũy thừa 2: nhân vật **1024²**, pháo đài **2048²** (có thể chia 2 tấm), quái thường **512²**, công trình / cây / đạo cụ **512²–1024²**. Đạo cụ nhỏ nên **gom chung một atlas** để nhẹ. Bản điện thoại game tự giảm một nửa kích thước. |
| Vật liệu | PBR cơ bản: albedo (+ tùy chọn roughness / emission cho mắt quái, lò lửa, bùa). **Không** dùng node shader riêng của phần mềm 3D |
| Animation | Trong `.glb`, **tại chỗ (in-place, không root motion)**, **30 fps**, tên clip **tiếng Anh viết thường** đúng như mục 5 |
| Rig | **5 model riêng [Chốt]** nhưng **cùng một cấu trúc xương** (cùng tên, cùng thứ bậc bone) để dùng chung animation cơ bản (`run`, `idle`, `hit`…); clip riêng từng class được phép. Quái thường một bộ xương riêng |
| Tên file | `snake_case` tiếng Anh không dấu, bắt đầu bằng mã: `ch01_engineer.glb`, `en01_basic.glb`, `ft01_fortress_wood.glb`, `ui_icon_wood.png` |
| LOD | Không cần (camera cố định khoảng cách) |

### Ngân sách tam giác **[Đề xuất]**

Nâng so với bản nháp cho đúng mức chi tiết ở 2.1. Bên game sẽ **đo hiệu năng sau đợt 1** và báo nếu cần giảm.

| Loại | Tam giác / model | Ghi chú |
|---|---|---|
| Chiến binh (mỗi class, kể cả vũ khí) | 6.000 – 10.000 | tối đa 5 trên màn hình |
| **Quái thường** | **1.500 – 3.000** | tới ~300 cùng lúc — đây là chỗ nặng nhất, **giữ ở mức thấp của khoảng**, ≤ 25 xương |
| Quái lớn / boss | 10.000 – 25.000 | ít, theo mốc |
| Pháo đài (mỗi cấp, chưa kể module) | 25.000 – 45.000 | luôn ở giữa màn hình, là "nhân vật chính" thứ hai |
| Module pháo đài | 500 – 3.000 | |
| Công trình (tháp, rào) | 2.000 – 5.000 | ~20 cùng lúc |
| Cây, mỏ, đạo cụ | 300 – 2.500 | dùng lặp lại nhiều lần |

---

## 5. Danh sách asset 3D

Kích thước = vùng va chạm / chơi trong game; model nên khớp (chênh ±15% được).

### 5.1 Nhân vật — 5 class

| Mã | Class | Dụng cụ / đặc điểm nhận diện [Đề xuất] | Ưu tiên |
|---|---|---|---|
| CH-01 | Công binh | búa gỗ lớn, túi đồ nghề, thước / dây đo; màu cam đồng | Đ2 |
| CH-02 | Tiều phu | rìu, sọt / gùi tre to sau lưng (túi đồ gấp đôi); xanh lá | Đ2 |
| CH-03 | **Võ tướng** | giáp Lý–Trần, đao hoặc giáo, vai to; đỏ | **Đ1** (model thử nghiệm) |
| CH-04 | Thầy pháp | gậy / phất trần, bùa giấy, mũ / khăn đặc trưng; tím | Đ2 |
| CH-05 | Thợ máy | cờ lê / ống bễ, kính bảo hộ đồng, tạp dề da; xám thép | Đ2 |

- Cao **~1.8 m**, vai rộng **~0.9–1.0 m** (vùng va chạm: viên nang bán kính 0.5 m).
- **5 model riêng** cho 5 class **[Chốt]** (dáng người, trang phục, dụng cụ khác hẳn nhau), cùng cấu trúc xương (mục 4).
- Nên có một **chi tiết mang màu class lớn, nhìn từ trên xuống** (khăn, cờ nhỏ sau lưng, mũ) — để phân biệt trong co-op.
- **Điểm gắn (bone / empty) cần có**: `hand_r` (vũ khí), `back` (công trình gấp gọn / gùi), `head` (để gắn nhãn trên đầu).

**Animation cho mọi class** (tên clip / mô tả / nhịp trong game):

| Clip | Mô tả | Nhịp game |
|---|---|---|
| `idle` | đứng thở | lặp |
| `run` | chạy | lặp, khớp tốc độ **7 m/s** |
| `run_carry` | chạy vác công trình gấp gọn trên lưng | lặp, **5 m/s** |
| `attack` | chém / đánh tự động | **0.5 s** một nhát (cắt được ngắn hơn) |
| `dash` | lướt né | **0.15 s** (rất nhanh) |
| `hammer` | gõ búa xây / sửa | lặp ~0.5 s |
| `chop` | chặt cây / bổ than | lặp ~0.5 s |
| `skill` | dùng kỹ năng class (mỗi class một kiểu: dựng tốc / bổ mạnh / hét trận / vung bùa / đốt lò) | ~0.6–0.8 s |
| `downed` | gục nằm chờ đồng đội (co-op) | lặp |
| `revive_help` | quỳ đỡ đồng đội | lặp, tổng **3 s** |
| `get_up` | được đỡ dậy | ~0.6 s |
| `death` | ngã | ~0.8 s |
| `man_crossbow` | đứng điều khiển nỏ trên thành (tay cầm tay quay) | lặp |

### 5.2 Quái

| Mã | Quái | Mô tả | Ưu tiên |
|---|---|---|---|
| EN-01 | **Quái thường** | cao ~1.6 m, bán kính 0.5 m; chạy **3.5 m/s**, đánh **1 nhát / 1 s** | **Đ1** |
| EN-02 | Quái nhanh | nhỏ, nhanh | Đ3 |
| EN-03 | Quái trâu | to, chậm, nhiều máu | Đ3 |
| EN-04 | Boss (1–2) | theo mốc đường | Đ3 |

- **Hướng: quái từ truyền thuyết Việt [Chốt]**. Tên / dáng [Đề xuất]: **EN-01 Quỷ rừng** (thân gỗ mục, rêu, mắt lửa), **EN-02 Ma trơi** (đốm lửa xanh có tay, nhỏ và nhanh), **EN-03 Quỷ nhập tràng** (to, chậm, áo liệm rách), **EN-04 boss** lấy từ chuyện Lạc Long Quân diệt yêu: **Ngư tinh**, **Hồ tinh**, **Mộc tinh**.
- Phải **khác hẳn người chơi** về màu (đỏ sẫm / tím than) và dáng (khom, tay dài); **mắt phát sáng** để thấy giữa đám đông.
- Animation: `idle`, `run`, `attack`, `hit` (giật khi trúng đòn, ~0.2 s), `death` (~0.6 s), `stunned` (bị trấn yểm / làm chậm — có thể dùng lại `idle` chậm).

### 5.3 Pháo đài (thành trì di động)

**Tòa thành chạy bằng bánh xe, trông phải thật có sức mạnh [Chốt 2026-10-19]** (không đặt trên lưng rùa, không voi kéo).

- Thân chính **10 × 10 m, cao 5 m**, mũi trước nhô ra. Chạy dọc đường rộng **16 m**, tốc độ **3 m/s** (tăng tốc ×1.6).
- Gợi ý hình ảnh [Đề xuất]: **tường thành Cổ Loa thu nhỏ đặt trên khung xe gỗ lim bọc sắt**, **4–6 bánh xe gỗ khổng lồ** (cao ~2.5–3 m, đai sắt, nan to, đinh tán), **mũi phá thành** (đầu húc bọc đồng) phía trước, cổng thành + vọng lâu mái đầu đao trên nóc, cờ hiệu, xích, khói từ ống lò. Thấp, rộng, nặng — như một cỗ xe công thành.
- **Cấp vật liệu** (thay vỏ, cùng kích thước, cùng bánh xe / khung): **FT-01 Gỗ** (Đ1) — gỗ lim, cọc nhọn, dây chão; **FT-02 Đá** (Đ2) — gạch đá Cổ Loa, đai sắt dày hơn; **FT-03 Bọc đồng** (Đ3, chưa có trong game — làm sau nếu thêm cấp) — mảng đồng chạm hoa văn Đông Sơn.
- **Trạng thái hư hại** [Đề xuất]: lành / hư nhẹ / hư nặng (thành mất máu thì chạy chậm — nên thấy được: ván vỡ, gạch sứt, khói). Có thể là 3 bộ texture hoặc vài mảnh vỡ gắn thêm.
- **Animation / bộ phận chuyển động**: **bánh xe tách riêng từng mesh** (game tự quay theo tốc độ), thân có `move` (rung nhẹ khi chạy), `idle` (dừng ở điểm dừng). Tăng tốc: game quay bánh nhanh hơn + thêm khói lửa.

**Module gắn lên thân** (hiện lên khi mua nâng cấp ở điểm dừng) — cần **điểm gắn (empty) đặt tên đúng** trên model thân. Tọa độ hiện tại (mét, gốc = tâm đáy pháo đài, phía trước = mũi):

| Mã | Module | Điểm gắn | Vị trí hiện tại | Ghi chú | Ưu tiên |
|---|---|---|---|---|---|
| FM-01 | **Nỏ liên châu** | `socket_crossbow` | giữa nóc, cao 5.3 | xoay quanh trục đứng theo hướng ngắm; **3 cấp nâng** (to / thêm dây cung) | Đ1 |
| FM-02 | **Chỗ đứng điều khiển nỏ** | `socket_gunner` | nóc, sau nỏ 1.4 m | người chơi đứng vào | Đ1 |
| FM-03 | **Thang** | `socket_ladder` | giữa mặt sau | người chơi leo lên bằng thang này | Đ1 |
| FM-04 | Dầu sôi (vạc + máng đổ) | `socket_oil` | góc sau-trái nóc | ~1.2 m | Đ2 |
| FM-05 | Lò lửa đốt Than | `socket_furnace` | góc sau-phải nóc | ~1.2 m, có lửa / khói (emission) | Đ2 |
| FM-06 | Khiên tự hồi | — | vòm bao quanh, bán kính ~7.5 m | **làm bằng shader trong Godot**, họa sĩ chỉ cần ý tưởng / hoa văn (có thể là texture hoa văn trống đồng) | Đ2 |
| FM-07 | Nỏ thần | `socket_divine` | **trên vọng lâu phía trước**, cao ~7 m (Claude chọn) | vũ khí tối thượng: nỏ đồng lớn, bắn loạt tên quanh thành; nên là chi tiết đẹp nhất trên thành | Đ2 |
| FM-08 | Chông gai | quanh chân tường | — | có sẵn từ đầu (phản sát thương) | Đ2 |

### 5.4 Công trình ngoài thực địa

| Mã | Công trình | Kích thước | Trạng thái / biến thể cần có | Ưu tiên |
|---|---|---|---|---|
| ST-01 | **Tháp nỏ** | cao ~2.4 m, đế bán kính ~0.85 m | (a) **bản vẽ**: game tự làm mờ / trong suốt model hoàn chỉnh — họa sĩ không cần làm riêng; (b) hoàn chỉnh; (c) **gấp gọn** để vác trên lưng (~0.9 × 0.9 × 0.6 m); (d) đống đổ nát khi bị phá. Phần nỏ trên đỉnh **xoay được** (tách mesh) | **Đ1** |
| ST-02 | Rào gỗ (chướng ngại hút quái) | 3 × 1.4 × 0.8 m | hoàn chỉnh, hư nặng, gấp gọn, đổ nát | Đ2 |

### 5.5 Tài nguyên & thế giới

| Mã | Asset | Kích thước | Biến thể | Ưu tiên |
|---|---|---|---|---|
| WD-01 | **Cây** (cho Gỗ) | cao 3–5 m, thân bán kính ~0.5 m | 3 biến thể (Đ1: 2); rung khi bị chặt (game tự làm); gốc cây khi hết gỗ | **Đ1** |
| WD-02 | Mỏ than | khối ~2.2 × 1.6 × 2.2 m | 2 biến thể; nhỏ dần khi bị đào (2–3 mức hoặc game tự thu nhỏ) | Đ2 |
| WD-03 | Đống đồ rơi | ~0.6–0.9 m | Gỗ (bó củi), Than (đống than), Đồng (mảnh đồng / mũi tên đồng), hỗn hợp | Đ2 |
| WD-04 | Mốc điểm dừng | vùng tròn bán kính **8 m** trên đường | cổng tam quan / cột mốc + vòng trên đất | Đ2 |
| WD-05 | Mặt đất | texture lặp liền (tileable) | 1 kiểu cho biome mẫu (Đồng bằng) | Đ1 |
| WD-06 | Dải đường đất | texture lặp theo chiều dọc | vết bánh xe, sỏi | Đ1 |
| WD-07 | Đạo cụ trang trí ven đường | 0.3–3 m | tre, đá, cỏ, bụi, hàng rào tre, miếu nhỏ | Đ2 |
| WD-08 | 4 kiểu tuyến | — | **Rừng già**, **Mỏ than**, **Đồng bằng**, **Đền hoang**: mỗi kiểu một bảng màu đất + bộ đạo cụ riêng | Đ3 (Đ2: Đồng bằng làm mẫu) |

Bom ẩn dưới đường **không cần model** (chỉ hiệu ứng nổ, làm trong Godot).

---

## 6. Hiệu ứng (VFX) — Claude làm trong Godot

Họa sĩ **không bắt buộc** làm. Nếu muốn đóng góp: sprite sheet PNG nền trong suốt (vd khói, tia lửa, mảnh gỗ, vòng bùa, hoa văn khiên), 512² hoặc 1024².

Danh sách: vệt tên nỏ, nhát chém, nổ (bom / tháp đòn cuối / Nỏ thần), vùng Bùa trận (vòng trên đất), xung Hét trận / Dựng tốc, khiên, hồi máu, chớp trắng khi trúng đòn, khói lò / tăng tốc, bụi chân, mảnh gỗ khi chặt, bụi than khi đào, viên phù tím (tháp khắc phù), dấu ping.

---

## 7. UI 2D

Phong cách UI **[Đề xuất]**: **gỗ – đồng – giấy dó** (khớp màu UI hiện tại ở mục 2.2), viền đồng chạm hoa văn Đông Sơn, nền gỗ tối. Có chất game, **không** kiểu form mặc định. **[Chốt]**

Tiêu chuẩn chung: PNG nền trong suốt, **vẽ ở gấp đôi kích thước dùng** (để nét trên màn 4K), file nguồn có lớp (PSD / Krita / Figma).

| Mã | Asset | Kích thước file | Số lượng | Chỗ gắn trong game | Ưu tiên |
|---|---|---|---|---|---|
| UI-01 | **Logo "THÀNH TRÌ"** | ~1600 × 600 | 1 (+ bản tiếng Anh nếu muốn) | màn bắt đầu | Đ2 |
| UI-02 | **Font** | — | chữ thường + chữ tiêu đề | toàn game | **Đ1** |
| UI-03 | **Khung thẻ 9-slice** | 192 × 192, viền không giãn **24 px** (bản ×2: 384, viền 48) | 1 | `ui/art/card_frame.png` (đã nối sẵn) | **Đ1** |
| UI-04 | Khung bảng 9-slice (panel HUD, bảng điểm dừng, màn kết quả) | 192 × 192, viền 24 px | 1–2 | thay khung vẽ bằng code | Đ2 |
| UI-05 | Nút 9-slice | ~256 × 80 | 4 trạng thái: thường / di chuột / nhấn / khóa | mọi nút | Đ2 |
| UI-06 | Thanh tiến độ (máu thành, máu người, tiếng ồn, Nỏ thần, hồi chiêu) | khung + lõi 9-slice | 1 bộ | HUD | Đ2 |
| UI-07 | **Icon tài nguyên**: Gỗ, Than, Đồng | **128 × 128** | 3 | `resources/types/*.tres` → `icon` (đã nối sẵn) | **Đ1** |
| UI-08 | Icon công trình: Tháp nỏ, Rào gỗ | 128 × 128 | 2 | `structures/types/*.tres` → `icon` | Đ2 |
| UI-09 | **Chân dung class** (thẻ chọn vai trò) | **256 × 256** | 5 | `classes/types/*.tres` → `art` | Đ2 |
| UI-10 | Icon kỹ năng class: Dựng tốc, Bổ mạnh, Hét trận, Bùa trận, Đốt lò | 128 × 128 | 5 | ô kỹ năng HUD | Đ2 |
| UI-11 | Minh họa thẻ vũ khí: Sát thương +30%, Chém rộng, Tầm với +25%, Đánh nhanh | **320 × 200** | 4 | `combat/upgrades/*.tres` → `art` (đã nối sẵn) | Đ2 |
| UI-12 | Icon nâng cấp pháo đài: Nỏ liên châu, Dầu sôi, Lò lửa, Khiên tự hồi + cấp thân Gỗ / Đá | 128 × 128 | 6 | bảng điểm dừng | Đ2 |
| UI-13 | Minh họa tuyến: Rừng già, Mỏ than, Đồng bằng, Đền hoang | 480 × 200 | 4 | `world/routes/*.tres` → `art` | Đ3 |
| UI-14 | Icon ping: quái, xây giúp, thu công trình, đồ rơi, lấy tài nguyên, về giữ thành, đến đây | 96 × 96 | 7 | dấu ping + mũi tên rìa màn hình | Đ3 |
| UI-15 | Icon trạng thái: gục, hồi sinh, tăng tốc, hết Than, truy đuổi, điều khiển nỏ | 64 × 64 | 6 | HUD | Đ3 |
| UI-16 | Nền màn bắt đầu / phòng chờ | 1920 × 1080 (an toàn cho tỉ lệ dài của điện thoại: để chi tiết quan trọng ở giữa 1600 × 900) | 1 | màn bắt đầu | Đ3 |
| UI-17 | Biểu tượng ứng dụng (Steam, Android, iOS) | 1024 × 1024 | 1 | phát hành | Đ3 |

**Font (UI-02)** — yêu cầu bắt buộc: **đủ dấu tiếng Việt** (ă â đ ê ô ơ ư + 5 dấu thanh, kể cả chữ hoa có dấu như "Ở", "Ữ"), có chữ Anh, **giấy phép cho phép nhúng vào game thương mại** (vd SIL Open Font License). Gợi ý tìm trên Google Fonts với bộ chữ "Vietnamese" [Đề xuất]: chữ thường dạng tròn dễ đọc (Be Vietnam Pro, Nunito, Lexend); chữ tiêu đề có cá tính (Baloo 2 hoặc vẽ riêng cho logo). Chữ tiếng Anh dài hơn tiếng Việt ~10–30% → khung chữ phải co giãn.

**Màn hình phải hỗ trợ**: tối thiểu **1280 × 720**, PC 1920 × 1080 trở lên, điện thoại tỉ lệ dài (19.5:9) có tai thỏ.

---

## 8. Âm thanh (không thuộc phạm vi họa sĩ)

**[Chốt 2026-10-19]** Bên game (Claude) lo phần âm thanh theo cách sau:

- **Claude làm**: hệ thống âm thanh trong Godot (kênh nhạc / hiệu ứng / giao diện, trộn âm lượng, âm thanh theo vị trí, giới hạn số tiếng cùng lúc khi có 300 quái), nối âm vào từng sự kiện game, và **âm tạm tổng hợp bằng code** để có tiếng ngay.
- **Claude không làm được**: sáng tác / thu âm nhạc thật và hiệu ứng chất lượng phát hành. Phần này lấy từ **thư viện âm thanh CC0 / miễn phí bản quyền** (cần chủ dự án cho phép tải) hoặc thuê người làm âm thanh.
- Danh sách cần có (để tìm thư viện hoặc giao người làm): nhạc chất dân tộc (**trống đồng, sáo trúc, đàn bầu, đàn đáy, cồng chiêng**) pha nhịp hành động — trận (2 lớp: thường / truy đuổi), điểm dừng, menu; SFX: chém, trúng đòn, quái kêu / chết, bắn nỏ (tháp, thành, Nỏ thần), nổ, gõ búa, chặt cây, đào than, nhặt / nộp đồ, bánh xe pháo đài lăn / tăng tốc / bị đánh, công trình xây xong / bị phá, gục / được đỡ dậy, 5 kỹ năng class, ping, giao diện.
- Định dạng: `.ogg` (nhạc, 44.1 kHz), `.wav` (SFX ngắn, 44.1 kHz, 16-bit).

---

## 9. Bàn giao & quy trình

### 9.1 Ba đợt — ưu tiên **nhanh nhất** **[Chốt 2026-10-19]**

| Đợt | Nội dung | Mục đích |
|---|---|---|
| **Đ1 — thử nghiệm** | CH-03 Võ tướng (đủ animation), EN-01 Quái thường, FT-01 Pháo đài gỗ (+ FM-01..03), ST-01 Tháp nỏ, WD-01 Cây (2 biến thể), WD-05/06 đất + đường, UI-02 font, UI-03 khung thẻ, UI-07 3 icon tài nguyên | Ghép vào game, kiểm tra **đọc rõ ở góc camera** và **hiệu năng với ~300 quái**, chốt phong cách. Duyệt xong mới làm tiếp. |
| **Đ2 — chơi đẹp** | 4 class còn lại, FT-02 Pháo đài đá, module FM-04..08, ST-02 Rào, WD-02..04, WD-07, biome Đồng bằng hoàn chỉnh, UI-01, UI-04..12 | Bản vertical slice đẹp (M3) |
| **Đ3 — mở rộng** | Quái EN-02..04, FT-03, 4 kiểu tuyến, UI-13..17 | Nội dung (M4) + phát hành |

**Để nhanh nhất:**
- **Giao cuốn chiếu**: xong asset nào gửi asset đó (không chờ đủ cả đợt) — bên game ghép và phản hồi ngay trong ngày.
- Thứ tự trong Đ1: **pháo đài gỗ → Võ tướng → quái thường → tháp nỏ → cây → đất / đường**, UI song song.
- Đạo cụ chung (đá, cỏ, thùng, bao tải…) **được dựng từ mesh nền CC0 rồi vẽ lại texture** cho đúng phong cách, để dồn thời gian cho nhân vật, quái, pháo đài.
- Có thể giao Đ1 và Đ2 cho **2 người song song** (một người 3D nhân vật / quái, một người pháo đài / công trình / UI).

### 9.2 Cách gửi file

- Mỗi lần gửi một thư mục nén: `thanhtri_dot1_<ngày>.zip` (giao cuốn chiếu thì gửi nhiều lần, cùng cấu trúc), bên trong:
  ```
  3d/      ch03_general.glb, en01_basic.glb, ft01_fortress_wood.glb, st01_crossbow_turret.glb, wd01_tree_a.glb …
  tex/     palette.png (atlas dùng chung) và texture riêng nếu có
  ui/      ui_card_frame.png, ui_icon_wood.png, ui_icon_coal.png, ui_icon_bronze.png …
  fonts/   *.ttf / *.otf + file giấy phép
  source/  file nguồn .blend / .psd / .kra
  README.txt   danh sách file + ghi chú (vd clip nào chưa xong)
  ```
- Tên file theo mục 4; tên clip animation đúng mục 5.

### 9.3 Checklist trước khi gửi (họa sĩ tự kiểm)

- [ ] Scale = 1, đơn vị mét, gốc ở giữa đáy, mặt trước quay −Y (Blender)
- [ ] Tam giác trong ngân sách mục 4
- [ ] Clip animation đủ tên, 30 fps, tại chỗ, các clip lặp nối liền
- [ ] Điểm gắn (`hand_r`, `back`, `socket_*`) đặt đúng tên
- [ ] Texture PNG, lũy thừa 2, không nhúng đường dẫn tuyệt đối
- [ ] Nhìn thử ở góc 35° / 45° orthographic, thu nhỏ còn ~50 px vẫn nhận ra
- [ ] Giấy phép: tự làm, hoặc nguồn CC0 / cho phép thương mại — ghi rõ nguồn từng thứ bên thứ ba

### 9.4 Bên game làm gì khi nhận file

Claude nhập vào Godot, thay placeholder, nối animation với hành động, chụp ảnh **1280×720 tiếng Việt + tiếng Anh**, đo hiệu năng (`tools/benchmark.sh`, 0→300 quái) và báo lại chỗ cần sửa (vd "quá nặng", "khó phân biệt với nền", "clip `run` trượt chân ở 7 m/s").

### 9.5 Giấy phép

- Asset phải là **tự làm** hoặc **CC0 / giấy phép cho phép thương mại**; ghi nguồn vào `CREDITS.md`.
- **Không** dùng asset của game tham khảo (Marcha de Ferro) hay bất kỳ asset có bản quyền nào khác.
- Quyền sử dụng asset thuộc về chủ dự án (thỏa thuận giữa người dùng và họa sĩ).

---

## 10. Các quyết định đã chốt (2026-10-19)

| Câu hỏi | Quyết định |
|---|---|
| Phong cách | Giống *Monsters Are Coming! Rock & Road* / *Marcha de Ferro*, **không đơn giản quá** (mục 2.1) |
| Pháo đài di chuyển bằng gì | **Tòa thành bánh xe**, trông có sức mạnh (mục 5.3) |
| Nhân vật | **5 model riêng**, cùng cấu trúc xương |
| Quái | Hướng truyền thuyết Việt; tên / dáng theo đề xuất ở 5.2 |
| Nỏ thần, cấp thân sau Đá | Claude chọn: Nỏ thần trên vọng lâu phía trước; cấp 3 "Bọc đồng" (làm sau) |
| Âm thanh | Claude lo hệ thống + âm tạm; nhạc / SFX thật lấy từ thư viện CC0 hoặc người làm âm thanh (mục 8) |
| Tiến độ | **Nhanh nhất**: giao cuốn chiếu, ưu tiên theo thứ tự ở 9.1 |
