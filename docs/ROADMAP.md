# THÀNH TRÌ — Roadmap

Cập nhật: 2026-10-18 (viết lại theo vòng chơi mới). Ký hiệu: **[Chốt]** · **[Đề xuất]** · **[Mở]**.
Tiến độ hằng ngày: [`PROGRESS.md`](PROGRESS.md) · Game tham khảo: [`REFERENCE.md`](REFERENCE.md) · Ý tưởng: [`IDEAS.md`](IDEAS.md).

## 1. Mục tiêu [Chốt]

- Game nghiêm túc. **Steam trước (PC)**, sau đó Google Play + App Store. Forward+ trên PC, Mobile trên điện thoại.
- **Endless**, so **đội / người chơi nào đi xa hơn**; bảng xếp hạng theo cỡ đội.
- **Co-op tối đa 4 người, chia vai trò rõ** — đây là hướng chính của người dùng. Solo vẫn chơi trọn vẹn.
- Tham khảo **Marcha de Ferro** (học nguyên tắc, không chép), thêm co-op và tính năng riêng.
- Asset tử tế (nền KayKit/Kenney CC0 + phần bản sắc Việt do họa sĩ làm), UI có chất game, **i18n bắt buộc**.

## 2. Vòng chơi đã chốt

**Tiến → Lắp → Duy trì → Bỏ lại**, trên một con đường vô tận.

- Pháo đài tự đi. Người chơi **đặt công trình ngoài thực địa** phía trước; công trình được **tiếp sức khi ở gần pháo đài**,
  ra xa thì chạy bằng bộ đệm; **thu về mang lên trước** ("nhảy cóc") hoặc **bỏ lại kèm đòn cuối**.
- **Đòn thường tự đánh**; **kỹ năng class bấm chủ động và ngắm**; dash.
- Tài nguyên: **Gỗ** (xây, sửa) · **Than** (nhiên liệu, tăng tốc; hết than bò chậm) · **Đồng** (vũ khí, kỹ năng). Nâng cấp pháo đài, kể cả **vũ khí của thành**, trả bằng **giá trộn** các nguyên liệu này.
- Độ khó: **quãng đường** (nền) + **tiếng ồn** (tăng tốc, khai thác, bắn…; đầy → truy đuổi; điểm dừng làm dịu).
- Điểm dừng an toàn: **chọn 1/2 tuyến** (thưởng/rủi ro), nâng cấp, chuẩn bị, khởi hành.
- Chết: hồi sinh / được đồng đội đỡ dậy, rơi đồ đang mang. Thua khi pháo đài bị phá.
- **Pháo đài tự phòng thủ** (khác game tham khảo), chỉ xử lý quái lọt sát thân: nỏ liên châu yếu + chông gai có sẵn;
  **Nỏ thần** (đòn tất sát nạp bằng hoạt động của cả đội); module: nâng nỏ, dầu sôi, lò lửa đốt Than, khiên tự hồi;
  ụ nỏ có người điều khiển (co-op).

## 3. Đã có (prototype, xem PROGRESS)

Đường vô tận theo seed, pháo đài + máu → tốc độ, chiến binh di chuyển, đánh chủ động (sẽ chuyển thành kỹ năng), quái + spawner,
độ khó theo quãng đường (M1.2), Gỗ/Đá/Đồng + khai thác/nộp/sửa/rơi đồ, điểm dừng + bảng nâng cấp + thẻ vũ khí, bom ẩn, HUD, màn kết quả,
44+ test tự động, benchmark, F3. **Phần cần làm lại:** tài nguyên (bỏ Đá, thêm Than), tháp gắn pháo đài → công trình ngoài thực địa,
đánh chủ động → tự đánh + kỹ năng.

## 4. Cột mốc

Mỗi mốc chia thành bước nhỏ có test + chơi thử; người dùng duyệt từng bước.

### M1 — Vòng cốt lõi (solo, placeholder) — ✅ xong 2026-10-18 (cân bằng còn chờ chơi thử)

**Câu hỏi phải trả lời được: "nhảy cóc công trình trong khi pháo đài cứ đi và quái áp sát có vui không?"** Nếu chưa vui, sửa vòng này trước khi thêm nội dung.

| Bước | Nội dung |
|---|---|
| M1.2 | Độ khó theo quãng đường (đã code, chờ commit) |
| M1.3 | **Đòn thường tự đánh** (stick phải/chuột ưu tiên hướng) + **dash**; phần ngắm hiện có giữ cho kỹ năng sau |
| M1.4 | **Công trình ngoài thực địa**: chế độ xây (chọn công trình, bóng ma xanh/vàng/đỏ), **tháp gập mang theo** (mang 1 cái), **chướng ngại cố định**; **bộ đệm tiếp sức** trong bán kính pháo đài; thu hồi; **đòn cuối** khi bỏ. Tháp gắn pháo đài cũ → bỏ (sau thành module) |
| M1.5 | **Tự vệ cơ bản của pháo đài**: nỏ liên châu yếu (tầm ngắn, quái sát thân) + chông gai phản sát thương · **chơi thử câu hỏi cốt lõi** + cân bằng |
| M1.6 | **Tài nguyên mới**: Gỗ / **Than** (tiêu hao theo tốc độ, tăng tốc, hết than bò chậm) / Đồng; bỏ Đá · **Nâng cấp pháo đài** (ô module hiện trên thân, mua ở điểm dừng, **trả bằng nguyên liệu kiếm được — giá trộn Gỗ/Than/Đồng**): thân vật liệu, cấp nỏ liên châu, **dầu sôi**, **lò lửa đốt Than**, **khiên tự hồi**; sau này cả nâng cấp Nỏ thần |
| M1.7 | **Tiếng ồn + truy đuổi** chồng lên độ khó quãng đường · **Nỏ thần**: thanh năng lượng (hạ quái, nộp đồ, xây) → một người kích hoạt loạt tên quét quanh thành (cứu nguy khi truy đuổi / boss) |
| M1.8 | **Chọn 1/2 tuyến** ở điểm dừng (tham số đoạn đường: thưởng/rủi ro), theo seed |
| M1.9 | **Điểm số = quãng đường**, kỷ lục, lưu cài đặt (`user://`); **seed hằng ngày/tuần** chơi được offline (10) |
| M1.10 | **Hạ tầng i18n** (Việt + Anh), màn chọn ngôn ngữ lần đầu (cần tắt Godot khi sửa `project.godot`) |

### M2 — Co-op & vai trò

| Bước | Nội dung |
|---|---|
| M2.1 | **Mạng co-op nền** (host-authoritative, ENet; test 2–4 cửa sổ trên cùng máy / LAN): đồng bộ ý định từ `PlayerInput`, sinh/hủy entity, trạng thái trận; kho chung + túi riêng (7) |
| M2.2 | **Class = vai trò** (1): Công binh, Tiều phu/Thợ mỏ, Võ tướng, Thầy pháp, Thợ máy — mỗi class 1 kỹ năng chủ động + 1 điểm mạnh thụ động |
| M2.3 | **Đỡ đồng đội dậy** (2), **kết hợp giữa class** (4), **ping/đánh dấu** (5), **ụ nỏ có người điều khiển** trên pháo đài (không ai đứng thì tự bắn yếu) |
| M2.4 | **Độ khó theo số người**, vào/ra giữa trận (8) |
| M2.5 | **Tổng kết cuối trận theo vai trò** (MVP xây / khuân / hạ quái / cứu người) (12) |

### M3 — Vertical slice đẹp

B1 hướng mỹ thuật + **tài liệu tiêu chuẩn asset** (nền KayKit/Kenney CC0, phần Việt do họa sĩ) · B2 làm đẹp bằng code (ánh sáng, hậu kỳ,
stylized, hạt, juice, font tiếng Việt, làm mờ pháo đài khi che) · 1 biome hoàn chỉnh · âm thanh cơ bản · đo lại hiệu năng.

### M4 — Nội dung

**Biome theo vùng miền** (16) + tuyến mang tên địa danh · **sự kiện truyền thuyết**: nước dâng, đêm trăng máu (17) · **boss truyền thuyết** theo mốc (18)
· thêm quái, công trình, module, kỹ năng · *(ưu tiên thấp, có thể bỏ)* trang phục theo thời đại (19).

### M5 — Steam beta

Steamworks: **bảng xếp hạng theo cỡ đội** Solo/2/3/4 (9), **bạn bè** (11), **seed hằng ngày/tuần online + thử thách** (10),
**thẻ hành trình chia sẻ** (13), **mùa giải** (14), **chống gian lận** (seed + nhật ký rút gọn) (15), co-op qua Steam Networking,
thành tựu, cloud save, build Windows/macOS/Linux, Steam Playtest.

### M6 — Phát hành Steam · M7 — Port di động · M8 — Google Play + App Store

M7: renderer Mobile, điều khiển cảm ứng, UI safe area; M8: Google Play Games, Game Center, store listing đa ngôn ngữ.

## 5. Quyết định đang mở

1. Chi tiết công trình M1.4: số loại ban đầu, bộ đệm bao lâu, mang mấy cái, đòn cuối kích hoạt thế nào.
2. Cách điều khiển xây (menu vòng tròn kiểu tay cầm, hay phím số + chuột).
3. Tên/cơ chế quái, boss, class (đề xuất trong IDEAS.md).
4. Cấu hình PC tối thiểu + mục tiêu FPS (đề xuất 60 FPS ở 1080p, GPU tích hợp tầm trung).
5. Mô hình kinh doanh (ghi chú: nếu bán thì chỉ trang phục).
6. Nền tảng PC: Windows + macOS + Linux/Steam Deck?

## 6. Rủi ro

- Vòng nhảy cóc thành "hộ tống nhàm chán" nếu thao tác bảo trì nhỏ lẻ, lặp liên tục → mỗi thao tác phải có kết quả lớn, rõ.
- Xây trên tay cầm khó dùng → menu vòng tròn, làm chậm thời gian khi chọn, bắt lưới rộng.
- Co-op online: đồng bộ nhiều quái + công trình; cần làm nền mạng sớm (M2.1) để không phải viết lại.
- Hiệu năng bầy quái (vật lý quái là điểm nóng đã đo) → có thể cần thay CharacterBody bằng di chuyển đơn giản + spatial hash.
- Che khuất bởi pháo đài; khối lượng asset; phụ thuộc plugin Steamworks theo phiên bản Godot.
