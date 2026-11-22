import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';

/// Năm loại trạng thái hiển thị bằng chấm màu cộng hình dạng.
enum LockStatus { none, biometric, mainCode, ownCode, combined }

class AppEntry {
  const AppEntry({
    required this.app,
    required this.status,
    required this.enabled,
    required this.hasOwnCode,
  });

  final InstalledApp app;
  final LockStatus status;
  final bool enabled;
  final bool hasOwnCode;
}

/// Phân loại trạng thái của một ứng dụng từ cấu hình hiện tại.
LockStatus classifyLockStatus({
  required LockConfig config,
  required String package,
  required bool hasOwnCode,
}) {
  final policy = config.apps[package];
  if (policy == null || !policy.enabled) return LockStatus.none;
  final mode = policy.mode ?? config.defaults.mode;
  switch (mode) {
    case AuthMode.biometricOnly:
      return LockStatus.biometric;
    case AuthMode.both:
    case AuthMode.either:
      return LockStatus.combined;
    case AuthMode.codeOnly:
      return hasOwnCode ? LockStatus.ownCode : LockStatus.mainCode;
  }
}
