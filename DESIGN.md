# DESIGN

Nguồn sự thật cho giao diện. Đọc file này trước khi thêm màu, cỡ chữ hay khoảng cách mới.

## Quyết định

- Chủ đề: công cụ khóa ứng dụng, người dùng mở hiếm khi nhưng cần tin tưởng ngay.
- Cảm giác khi mở: bình tĩnh, chắc chắn, không hù dọa.
- Khái niệm chọn: **Locker** (xanh mòng két dịu). Ba hướng đã cân nhắc:
  1. Locker: một màu thương hiệu, bề mặt trung tính ngả xanh, nhãn trạng thái bằng hình dạng.
  2. Vault: nền đen, nhấn vàng. Hợp phim hơn là hợp công cụ hằng ngày, dễ giống app tài chính.
  3. Paper: nền giấy, chữ có chân. Đẹp nhưng nặng font, mâu thuẫn mục tiêu nhẹ và ngoại tuyến.
  Locker thắng ở độ phù hợp và khả thi.
- Ba từ khóa: calm, exact, light. Ba phản ví dụ: neon "hacker", ổ khóa vàng bóng, khiên có dấu tích.
- Tín hiệu đặc trưng: trạng thái mỗi app là **hình dạng cộng màu** (vòng rỗng, tròn đặc, vuông, thoi, vòng có chấm), nên không phụ thuộc phân biệt màu.

## Chữ

Roboto hệ thống. Có đủ dấu tiếng Việt, không tốn dung lượng APK, đúng mục tiêu app nhẹ. Cỡ 22 / 16 / 14 / 12, độ đậm 400 và 600. Dòng cách tối thiểu 1.4 cho dấu chồng.

## Khoảng cách và bo góc

Khoảng cách: 4, 8, 12, 16, 24, 32, 48. Bo góc: 8, 12, 20.

## Màu

| Vai trò | Sáng | Tối |
|---|---|---|
| Nền | F6F7F5 | 0E1514 |
| Bề mặt | FFFFFF | 151E1D |
| Tông | ECEFEC | 1E2A28 |
| Chữ | 14201E | E6EEEC |
| Chữ phụ | 4A5A57 | A5B5B1 |
| Thương hiệu | 0F766E | 4FD1C5 |
| Nguy hiểm | B3261E | FFB4AB |
| Chú ý | B45309 | F4A259 |

Trạng thái (sáng / tối): không 6B7775 / 8FA09C, sinh trắc 1D4ED8 / 7AA2FF, mã chung 0F766E / 4FD1C5, mã riêng B45309 / F4A259, kết hợp 9D174D / F28BB1.

Mọi cặp chữ trên nền đạt tối thiểu 4.5:1 (đã tính bằng script khi thiết kế). Màn hình khóa bên Kotlin dùng cùng giá trị trong `res/values/colors.xml` và `res/values-night/colors.xml`.

## Thích ứng

Theo bề rộng cửa sổ, không theo loại máy: dưới 600 thanh dưới, 600 đến 839 rail, từ 840 rail mở rộng. Danh sách app thành lưới khi rộng. Cài đặt thành hai ngăn từ 720. Nội dung đọc được giới hạn bề rộng.

## Quy tắc

- Chỉ dùng token trong `lib/app/theme/tokens.dart`. Thêm giá trị mới thì cập nhật file này.
- Cài đặt, trang hướng dẫn và tìm kiếm cùng đọc `settings_registry.dart`. Thêm cài đặt ở đó là đủ.
- Không dấu gạch dài trong chữ hiển thị, comment và tài liệu.
- Mục tiêu chạm tối thiểu 48dp. Có nhãn cho trình đọc màn hình.
