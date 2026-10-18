# Game tham khảo: Marcha de Ferro

- Bản chơi web: https://victorrseloy.github.io/marcha-de-ferro/ (Three.js; repo chỉ chứa bản build, **không ghi giấy phép**, mã nguồn không công khai)
- Spec gốc: https://gist.githubusercontent.com/victorrseloy/5ef46d0f726766fba4705bd07782a310/raw/eee8f5c4d32fd69c11cf772f9494de0b1746ac2e/gistfile1.txt
- Người dùng (2026-10-18): THÀNH TRÌ tham khảo game này, **khác ở chỗ có co-op và thêm tính năng riêng** của người dùng.
- Đây là dự án của người khác: lấy **nguyên tắc thiết kế**, không chép nguyên văn tên, nội dung, asset hay câu chữ.

## Tóm tắt Marcha de Ferro

Roguelite isometric, điều khiển bằng tay cầm. Người chơi là kỹ sư hộ tống **nhện-pháo đài hơi nước** tự đi theo đường;
tiếng ồn của nó tạo **Trail** kéo bầy xác sống ngày càng đông. Pitch: *"tower defense mà căn cứ không bao giờ dừng, người chơi
phải tự tay dời tuyến phòng thủ"*. Bốn động từ: **Tiến → Lắp → Duy trì → Bỏ lại.**

- Vũ khí cá nhân **tự bắn**; người chơi gây 30–40% sát thương, công trình 60–70%.
- **Công trình đặt ngoài thực địa**: loại neo cố định (rẻ, bỏ đi) và loại **gập mang theo** (đắt, thu hồi, mang 1 cái mỗi lần).
  Mạng áp suất: công trình trong bán kính phục vụ của nhện thì được nạp; ra ngoài thì chạy hết bộ đệm (~30 s).
  Vòng **"nhảy cóc"**: đặt tháp phía trước → thu tháp phía sau → mang lên trước → bỏ tháp khi thu hồi quá tốn thời gian.
- **Last Shot**: công trình bị bỏ lại có thể quá tải, bắn mạnh vài giây rồi nổ.
- 2 tài nguyên: **phế liệu** (xây/sửa) và **nhiên liệu** (chạy nhện, tăng tốc). Hết nhiên liệu → đốt phế liệu, chậm lại.
- **Trail / đạo diễn bầy**: thanh 0–100 tăng theo thời gian và tiếng ồn; mốc QUIET → PROBING → SWARM → HEAVY → PURSUIT
  (bầy đuổi liên tục phía sau, không thua tức thì). Điểm dừng hạ Trail về ~15–20. Quái theo ngân sách sinh.
- Điểm dừng an toàn: chọn **1 trong 2 tuyến** (mỏ than, bãi phế liệu, xưởng, kho vũ khí…), lắp module, chuẩn bị máy, hết giờ tự đi.
- Lên cấp bằng XP trong trận → chọn 1/3; module cho nhện ở điểm dừng; meta-progression theo chiều ngang.
- 1 lượt 20–30 phút, 3–4 điểm dừng, kết bằng **cuộc trốn chạy tới cổng cuối** (thắng) hoặc lõi nhện về 0 (thua).
- Asset: KayKit + Kenney (cả hai **CC0**), quái xương, rừng nguyền rủa.
- Ưu tiên khi mơ hồ: vòng phòng thủ di động > dễ đọc trên tay cầm > quyết định không gian > hiệu năng bầy > tiến trình > đồ họa.

## So sánh với THÀNH TRÌ (trạng thái 2026-10-18)

| Khía cạnh | Marcha de Ferro | THÀNH TRÌ hiện tại |
|---|---|---|
| Thứ được hộ tống | Nhện hơi nước tự đi | Pháo đài gỗ tự đi ✔ giống |
| Pháo đài tự vệ | Không (chỉ module tháp trên lưng / giáp phản ứng / khiên) | **[Chốt, khác spec]** nỏ liên châu yếu + chông gai có sẵn, Nỏ thần, module dầu sôi / lò lửa Than / khiên, ụ nỏ có người điều khiển |
| Đánh | Tự bắn, công trình gánh chính | **[Chốt]** đánh chủ động ngắm chuột, nhiều vũ khí sau này |
| Phòng thủ | Đặt/gập/mang tháp ngoài thực địa, nhảy cóc, Last Shot | Tháp gắn vào ô trên pháo đài ở điểm dừng |
| Tài nguyên | Phế liệu + nhiên liệu (nhiên liệu = tốc độ) | **[Chốt]** Gỗ (sửa) / Đá (nâng thành) / Đồng (vũ khí) |
| Độ khó | Trail (thời gian + tiếng ồn), Pursuit | Theo quãng đường (M1.2) |
| Cấu trúc lượt | 20–30 phút, cổng cuối, rẽ nhánh mỗi điểm dừng | **[Chốt]** endless, 1 đường uốn lượn, so quãng đường |
| Tiến trình trong trận | XP → chọn 1/3, module nhện | Thẻ vũ khí 1/3 + thân/tháp ở điểm dừng |
| Người chơi | Solo | **[Chốt]** solo + co-op |
| Engine | Three.js | Godot 4.7 ✔ giữ |
| Asset | KayKit + Kenney (CC0) | Placeholder; **có thể dùng KayKit/Kenney CC0** làm nền |

## Quyết định cần người dùng chốt

Xem `PROGRESS.md` → "Câu hỏi đang chờ".
