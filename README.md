# Vinny Lock

App khóa ứng dụng cho Android: gọn, ngoại tuyến, không quảng cáo, không thu thập dữ liệu.

- Package: `com.vinnycream.vinnylock`
- Android 8.0 trở lên (minSdk 26)
- Flutter cho giao diện ít mở (danh sách app, cài đặt, hướng dẫn). Kotlin thuần cho mã bí mật, màn hình khóa và dịch vụ Trợ năng.
- Phụ thuộc ngoài SDK Flutter: duy nhất `androidx.biometric`.

## Tính năng

- Mở khóa bằng sinh trắc học, mã PIN hoặc hình vẽ dùng chung, hoặc mã riêng cho từng app.
- Phạt khi nhập sai do bạn cấu hình (tối thiểu 5 lần, chờ cố định hoặc tăng dần).
- Câu hỏi khôi phục tự đặt, luôn dùng được kể cả khi đang bị phạt.
- Ẩn icon hoặc ngụy trang thành máy tính, ghi chú, thời tiết.
- Tiếng Việt và tiếng Anh, tìm kiếm không cần gõ dấu, thẻ trạng thái màu cho từng app.

## Cài đặt từ APK

1. Tải `app-release.apk` ở mục Releases rồi cài. Nếu Google Play Protect cảnh báo, bấm "Chi tiết khác" rồi "Vẫn cài đặt".
2. Mở app, đặt mã chung và câu hỏi khôi phục.
3. Vào Cài đặt > Trợ năng > Vinny Lock và bật lên.
4. Android 13 trở lên có thể chặn bước 3. Khi đó vào Cài đặt > Ứng dụng > Vinny Lock > menu ba chấm > "Cho phép cài đặt bị hạn chế", rồi bật lại Trợ năng.

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
flutter pub get
flutter analyze
flutter test
flutter build apk --debug      # chạy thử, tự ký bằng khóa debug
flutter build apk --release    # cần khóa ký, xem mục dưới
```

Lần đầu trên dự án mới, chạy thêm `flutter create --platforms=android --org com.vinnycream .` một lần để sinh `gradlew` và wrapper, rồi xóa `test/widget_test.dart` mà lệnh này tạo ra.

Test Kotlin: `cd android && ./gradlew :app:testDebugUnitTest`. Gradle 8.10.2 không chạy với Java 25, hãy đặt `JAVA_HOME` về JDK 17 đến 21 (ví dụ JDK đi kèm Android Studio).

## Ký bản phát hành

1. Tạo khóa một lần: `keytool -genkeypair -v -keystore vinnylock-release.jks -alias vinnylock -keyalg RSA -keysize 4096 -validity 10000`
2. Chép `android/key.properties.example` thành `android/key.properties` và điền thông tin thật (đường dẫn `storeFile` dùng dấu `/`). File này và `*.jks` đã nằm trong `.gitignore`. Sao lưu khóa và mật khẩu ở nơi an toàn: mất khóa là không cập nhật được app.
3. Chạy `tools/release.sh` (hoặc `flutter build apk --release`).

Không có `key.properties` thì bản release ra APK chưa ký, không cài được trên máy (không bao giờ dùng khóa debug). Cách này cho phép F-Droid tự build và tự ký.

## Quyền riêng tư

Bản release không có quyền INTERNET, CAMERA, vị trí, bộ nhớ hay danh bạ. Chỉ có VIBRATE và USE_BIOMETRIC. Không sao lưu đám mây. Mã lưu dạng PBKDF2-HMAC-SHA256 có muối riêng, cả tệp được mã hóa AES-GCM bằng khóa trong Android Keystore.

Dịch vụ Trợ năng chỉ nghe sự kiện đổi cửa sổ để biết app nào vừa mở. Không đọc nội dung màn hình, không ghi lại những gì bạn gõ.

## Giới hạn đã biết

- Dịch vụ Trợ năng mở màn hình khóa từ nền: một số hãng máy hạn chế, cần thử trên máy thật.
- Đổi icon bằng activity-alias có thể trễ vài giây ở một số launcher. Tên trong Cài đặt hệ thống không đổi được.
- Google Play yêu cầu khai báo và thông báo nổi bật về việc dùng Trợ năng.
- Đây không thay thế khóa màn hình hệ thống. Người có quyền cài đặt hoặc gỡ app vẫn gỡ được app này.

## Giấy phép

```
MIT License

Copyright (c) 2026 VinnyCream

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
