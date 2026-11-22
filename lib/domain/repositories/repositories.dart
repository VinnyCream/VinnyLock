import 'dart:typed_data';

import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';

/// Nguồn sự thật của cấu hình. `changes` phát ra mỗi khi cấu hình đổi.
abstract interface class ConfigRepository {
  Stream<LockConfig> get changes;
  Future<LockConfig> load();
  Future<void> save(LockConfig config);
}

abstract interface class AppCatalogRepository {
  Future<List<InstalledApp>> listApps();
  Future<Uint8List?> loadIcon(String package, int sizePx);
}

/// Mọi thứ liên quan bí mật nằm ở phía Android. Mã PIN và hình vẽ được nhập
/// ngay trên màn hình gốc nên không đi qua Dart. Riêng câu trả lời khôi phục
/// được gõ ở form Flutter, chuyển một lần sang Android để băm rồi bỏ, Dart không lưu lại.
abstract interface class SecurityRepository {
  Future<DeviceState> loadState();
  Future<bool> setMainCode(CodeKind kind);
  Future<bool> setAppCode(String package, CodeKind kind);
  Future<void> clearAppCode(String package);
  Future<bool> setRecovery({required String question, required String answer});
  Future<void> applyIconMode(IconSettings icon);
  Future<void> openAccessibilitySettings();
  Future<void> openAppInfo();
}
