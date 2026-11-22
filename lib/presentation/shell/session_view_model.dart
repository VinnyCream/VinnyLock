import 'package:flutter/foundation.dart';
import 'package:vinnylock/domain/entities/device_state.dart';
import 'package:vinnylock/domain/entities/lock_config.dart';
import 'package:vinnylock/domain/repositories/repositories.dart';

enum LoadStatus { loading, ready, failed }

typedef ConfigEdit = LockConfig Function(LockConfig current);

/// Trạng thái dùng chung toàn app: cấu hình và trạng thái thiết bị.
/// Mọi màn hình đọc từ đây và sửa qua [update] để chỉ có một nguồn sự thật.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel({
    required ConfigRepository configRepository,
    required SecurityRepository securityRepository,
  })  : _configRepository = configRepository,
        _securityRepository = securityRepository;

  final ConfigRepository _configRepository;
  final SecurityRepository _securityRepository;

  LoadStatus _status = LoadStatus.loading;
  LockConfig _config = LockConfig.initial;
  DeviceState _device = DeviceState.empty;

  LoadStatus get status => _status;
  LockConfig get config => _config;
  DeviceState get device => _device;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final loaded = await _configRepository.load();
      final state = await _securityRepository.loadState();
      _config = loaded;
      _device = state;
      _status = LoadStatus.ready;
    } on Object {
      _status = LoadStatus.failed;
    }
    notifyListeners();
  }

  /// Đọc lại trạng thái hệ thống (quyền Trợ năng, sinh trắc, mã đã đặt).
  /// Gọi khi app quay lại từ màn hình cài đặt của Android.
  Future<void> refreshDevice() async {
    try {
      _device = await _securityRepository.loadState();
    } on Object {
      return;
    }
    notifyListeners();
  }

  /// Sửa cấu hình: cập nhật giao diện ngay, rồi lưu. Lưu lỗi thì nạp lại bản đã lưu.
  Future<void> update(ConfigEdit edit) async {
    final before = _config;
    final next = edit(before);
    if (identical(next, before)) return;
    _config = next;
    notifyListeners();
    try {
      await _configRepository.save(next);
      if (next.icon != before.icon && _iconChanged(before.icon, next.icon)) {
        await _securityRepository.applyIconMode(next.icon);
      }
    } on Object {
      _config = await _configRepository.load();
      notifyListeners();
    }
  }

  bool _iconChanged(IconSettings a, IconSettings b) {
    return a.mode != b.mode || a.disguise != b.disguise;
  }

  Future<bool> setMainCode(CodeKind kind) async {
    final ok = await _securityRepository.setMainCode(kind);
    await refreshDevice();
    return ok;
  }

  Future<bool> setAppCode(String package, CodeKind kind) async {
    final ok = await _securityRepository.setAppCode(package, kind);
    await refreshDevice();
    return ok;
  }

  Future<void> clearAppCode(String package) async {
    await _securityRepository.clearAppCode(package);
    await refreshDevice();
  }

  Future<bool> setRecovery({required String question, required String answer}) async {
    final ok = await _securityRepository.setRecovery(question: question, answer: answer);
    await refreshDevice();
    return ok;
  }

  Future<void> openAccessibilitySettings() => _securityRepository.openAccessibilitySettings();

  Future<void> openAppInfo() => _securityRepository.openAppInfo();

  Future<void> completeOnboarding() => update(
        (LockConfig c) => c.copyWith(onboardingDone: true),
      );

  /// Đặt lại cài đặt chung. Giữ nguyên danh sách app đã khóa và cờ onboarding.
  Future<void> resetGeneralSettings() => update(
        (LockConfig c) => LockConfig(onboardingDone: c.onboardingDone, apps: c.apps),
      );
}
