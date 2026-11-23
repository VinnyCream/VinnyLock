# Vinny Lock

App khóa ứng dụng cho Android: gọn, ngoại tuyến, không quảng cáo, không thu thập dữ liệu.

- Package: `com.vinnycream.vinnylock`
- Android 8.0 trở lên (minSdk 26)
- Flutter cho giao diện ít mở (danh sách app, cài đặt, hướng dẫn). Kotlin thuần cho mã bí mật, màn hình khóa và dịch vụ Trợ năng.
- Phụ thuộc ngoài SDK Flutter: duy nhất `androidx.biometric`.

## Kiến trúc

```
lib/
  core/            chuẩn hóa chữ dùng chung
  domain/          entities, repositories (interface), usecases (thuần Dart)
  data/            codec JSON, cầu nối MethodChannel, repositories
  presentation/    ViewModel (ChangeNotifier) và trang
  app/             theme, container (DI tay), MaterialApp
android/.../       model, security, attempts, service, ui, bridge
```

Clean architecture ba lớp, MVVM truyền thống. Lược đồ JSON cấu hình dùng chung giữa `config_codec.dart` và `LockModels.kt`. Tên lệnh channel khớp giữa `native_call.dart` và `ChannelHandler.kt`.

## Build

```bash
flutter create --platforms=android --org com.vinnycream .   # sinh gradlew và wrapper, không ghi đè file có sẵn
flutter pub get
flutter analyze
flutter test
(cd android && ./gradlew :app:testDebugUnitTest)
flutter build apk --release
```

Nếu `flutter create` ghi đè file nào trong `android/`, khôi phục lại bằng git.

## Ký bản phát hành

1. Tạo khóa một lần: `keytool -genkeypair -v -keystore vinnylock-release.jks -alias vinnylock -keyalg RSA -keysize 4096 -validity 10000`
2. Chép `android/key.properties.example` thành `android/key.properties` và điền thông tin. File này và `*.jks` đã nằm trong `.gitignore`. Sao lưu khóa ở nơi an toàn: mất khóa là không cập nhật được app.
3. Chạy `tools/release.sh`. Script kiểm tra APK không bị ký bằng khóa debug.

Không có `key.properties` thì bản release ra APK chưa ký (không bao giờ dùng khóa debug), nên F-Droid vẫn tự build và tự ký được.

## Quyền riêng tư

Bản release không có quyền INTERNET, CAMERA, vị trí, bộ nhớ hay danh bạ. Chỉ có VIBRATE và USE_BIOMETRIC. Không sao lưu đám mây. Mã lưu dạng PBKDF2-HMAC-SHA256 có muối riêng, cả tệp được mã hóa AES-GCM bằng khóa trong Android Keystore.

## Giới hạn đã biết

- Dịch vụ Trợ năng mở màn hình khóa từ nền: cần thử trên máy thật, một số hãng hạn chế.
- Android 13 trở lên, bản cài ngoài cửa hàng cần bật "Cho phép cài đặt bị hạn chế" trước khi cấp quyền Trợ năng.
- Đổi icon bằng activity-alias có thể trễ vài giây ở một số launcher. Tên trong Cài đặt hệ thống không đổi được.
- Google Play yêu cầu khai báo và thông báo nổi bật về việc dùng Trợ năng.
- Đây không thay thế khóa màn hình hệ thống. Người có quyền cài đặt hoặc gỡ app vẫn gỡ được app này.

## Giấy phép

Chưa chọn. F-Droid yêu cầu giấy phép mã nguồn mở (ví dụ GPL-3.0-or-later hoặc Apache-2.0). Thêm file `LICENSE` trước khi công khai.
