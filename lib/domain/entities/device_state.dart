import 'package:vinnylock/domain/entities/lock_config.dart';

enum CodeKind implements WireEnum {
  pin('pin'),
  pattern('pattern');

  const CodeKind(this.wire);
  @override
  final String wire;
}

/// Trạng thái đọc từ phía Android, không phải cài đặt do người dùng chọn.
class DeviceState {
  const DeviceState({
    this.hasMainCode = false,
    this.mainCodeKind,
    this.hasRecovery = false,
    this.recoveryQuestion,
    this.accessibilityEnabled = false,
    this.biometricAvailable = false,
    this.ownCodePackages = const <String>{},
  });

  static const DeviceState empty = DeviceState();

  final bool hasMainCode;
  final CodeKind? mainCodeKind;
  final bool hasRecovery;
  final String? recoveryQuestion;
  final bool accessibilityEnabled;
  final bool biometricAvailable;
  final Set<String> ownCodePackages;

  bool hasOwnCode(String package) => ownCodePackages.contains(package);
}

class InstalledApp {
  const InstalledApp({required this.package, required this.label});

  final String package;
  final String label;
}
